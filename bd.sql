CREATE DATABASE vansue;
USE vansue;

-- ========================
-- Usuarios
-- ========================
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    role ENUM('Administrador', 'Vendedor') NOT NULL
);

-- ========================
-- Proveedores
-- ========================
CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================
-- Categorías (JERÁRQUICAS)
-- ========================
CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categorias(id) ON DELETE CASCADE
);

-- ========================
-- Géneros (ATRIBUTO)
-- ========================
CREATE TABLE generos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name ENUM('Hombre','Mujer','Unisex') NOT NULL
);

INSERT INTO generos (name) VALUES 
('Hombre'),
('Mujer'),
('Unisex');

-- ========================
-- Productos
-- ========================
CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    description TEXT,
    category_id INT NOT NULL,
    gender_id INT NULL,
    sale_price DECIMAL(10, 2),
    quantity INT DEFAULT 0, -- Para productos sin tonos
    inventory_type ENUM(
        'simple',
        'tones',
        'barcode'
    ) NOT NULL DEFAULT 'simple',
    image VARCHAR(255),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive') DEFAULT 'active',

    FOREIGN KEY (category_id) REFERENCES categorias(id),
    FOREIGN KEY (gender_id) REFERENCES generos(id)
);

-- ========================
-- Clientes
-- ========================
CREATE TABLE clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NULL,
    phone VARCHAR(20) NULL,
    password VARCHAR(255) NULL,
    accumulated_points INT DEFAULT 0,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================
-- Compras
-- (Actualizada: soporte para crédito con proveedores)
-- ========================
CREATE TABLE compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT,
    user_id INT,

    payment_type ENUM('cash', 'credit', 'mixed') NOT NULL DEFAULT 'cash',
    payment_status ENUM('paid', 'partial', 'pending') NOT NULL DEFAULT 'paid',

    purchase_price DECIMAL(10, 2),
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    pending_amount DECIMAL(10,2) NOT NULL DEFAULT 0,

    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (supplier_id) REFERENCES proveedores(id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

-- ========================
-- Tonos (variantes)
-- ========================
CREATE TABLE tonos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    tone_name VARCHAR(50) NOT NULL,
    quantity INT DEFAULT 0,
    image VARCHAR(255),
    status ENUM('active', 'inactive') DEFAULT 'active',
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE
);

-- ========================
-- Detalle de compras
-- ========================
CREATE TABLE detalle_compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id INT,
    product_id INT,
    tone_id INT NULL,
    quantity INT,
    purchase_price DECIMAL(10, 2),
    FOREIGN KEY (purchase_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (tone_id) REFERENCES tonos(id) ON DELETE CASCADE
);

-- ========================
-- Ventas
-- (Actualizada: soporte para contado / crédito / mixto)
-- ========================
CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    customer_id INT NULL,

    payment_type ENUM('cash', 'credit', 'mixed') NOT NULL DEFAULT 'cash',
    payment_status ENUM('paid', 'partial', 'pending') NOT NULL DEFAULT 'paid',

    total DECIMAL(10, 2) NOT NULL,
    paid_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    pending_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,

    earned_points INT DEFAULT 0,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (customer_id) REFERENCES clientes(id) ON DELETE SET NULL
);

ALTER TABLE ventas
    ADD COLUMN payment_method ENUM('cash', 'transfer', 'card') NOT NULL DEFAULT 'cash' AFTER payment_type,
    ADD COLUMN bank_id INT NULL AFTER payment_method,
    ADD FOREIGN KEY (bank_id) REFERENCES bancos(id);

-- ========================
-- Detalle de ventas
-- ========================
CREATE TABLE ventas_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    tone_id INT NULL,
    quantity INT NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    earned_points INT DEFAULT 0,
    FOREIGN KEY (sale_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (tone_id) REFERENCES tonos(id) ON DELETE CASCADE
);

-- ========================
-- Pagos de crédito (abonos de clientes)
-- ========================
CREATE TABLE pagos_credito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    customer_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card', 'other') NOT NULL DEFAULT 'cash',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,

    FOREIGN KEY (sale_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

-- ========================
-- Historial de puntos
-- ========================
CREATE TABLE historial_puntos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    sale_id INT NULL,
    points INT NOT NULL,
    type ENUM('earned', 'used') NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (sale_id) REFERENCES ventas(id) ON DELETE SET NULL
);

-- ========================
-- Imágenes de productos
-- ========================
CREATE TABLE productos_imagenes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    image VARCHAR(255) NOT NULL,
    type ENUM('hover', 'extra') NOT NULL,
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE
);

-- ========================
-- Precio por proveedor
-- ========================
CREATE TABLE producto_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    supplier_id INT NOT NULL,
    purchase_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES productos(id),
    FOREIGN KEY (supplier_id) REFERENCES proveedores(id),
    UNIQUE (product_id, supplier_id)
);

-- ========================
-- Códigos de barras
-- ========================
CREATE TABLE codigos_barras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(20) NOT NULL,
    product_id INT NOT NULL,
    tone_id INT NULL,
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (tone_id) REFERENCES tonos(id) ON DELETE CASCADE,
    UNIQUE KEY uq_barcode_producto_tono (barcode, product_id, tone_id)
);

-- ========================
-- Plan de cuentas contables
-- ========================
CREATE TABLE cuentas_contables (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    type ENUM('activo', 'pasivo', 'patrimonio', 'ingreso', 'costo', 'gasto') NOT NULL,
    nature ENUM('deudora', 'acreedora') NOT NULL,
    parent_id INT NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    FOREIGN KEY (parent_id) REFERENCES cuentas_contables(id) ON DELETE SET NULL
);

INSERT INTO cuentas_contables (code, name, type, nature) VALUES
('1101', 'Caja General',            'activo',     'deudora'),
('1102', 'Bancos',                  'activo',     'deudora'),
('1103', 'Cuentas por Cobrar',      'activo',     'deudora'),
('1104', 'Inventario',              'activo',     'deudora'),
('2101', 'Cuentas por Pagar',       'pasivo',     'acreedora'),
('3101', 'Capital Social',          'patrimonio', 'acreedora'),
('4101', 'Ventas',                  'ingreso',    'acreedora'),
('5101', 'Costo de Ventas',         'costo',      'deudora'),
('6101', 'Gastos Generales',        'gasto',      'deudora'),
('6102', 'Gastos de Compras',       'gasto',      'deudora');

INSERT INTO cuentas_contables (code, name, type, nature) VALUES
('4102', 'Otros Ingresos', 'ingreso', 'acreedora');

-- ========================
-- Libro diario (asientos contables)
-- ========================
CREATE TABLE asientos_contables (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entry_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255) NOT NULL,
    reference_type ENUM('venta', 'compra', 'pago_credito', 'pago_proveedor', 'gasto', 'ingreso_extra', 'apertura_caja', 'cierre_caja', 'ajuste') NOT NULL,
    reference_id INT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

CREATE TABLE asientos_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entry_id INT NOT NULL,
    account_id INT NOT NULL,
    debit DECIMAL(10,2) NOT NULL DEFAULT 0,
    credit DECIMAL(10,2) NOT NULL DEFAULT 0,
    description VARCHAR(255) NULL,
    FOREIGN KEY (entry_id) REFERENCES asientos_contables(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES cuentas_contables(id)
);

-- ========================
-- Caja diaria
-- ========================
CREATE TABLE cajas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    opening_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    closing_amount DECIMAL(10,2) NULL,
    expected_amount DECIMAL(10,2) NULL,
    difference DECIMAL(10,2) NULL,
    status ENUM('open', 'closed') NOT NULL DEFAULT 'open',
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

CREATE TABLE movimientos_caja (
    id INT AUTO_INCREMENT PRIMARY KEY,
    caja_id INT NOT NULL,
    type ENUM('income', 'expense') NOT NULL,
    concept VARCHAR(150) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reference_type ENUM('venta', 'pago_credito', 'gasto', 'pago_proveedor', 'otro') NOT NULL,
    reference_id INT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (caja_id) REFERENCES cajas(id) ON DELETE CASCADE
);

ALTER TABLE movimientos_caja 
MODIFY COLUMN reference_type ENUM('venta', 'compra', 'pago_credito', 'gasto', 'pago_proveedor', 'otro') NOT NULL;

-- ========================
-- Bancos
-- ========================
CREATE TABLE bancos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    account_alias VARCHAR(100) NULL,
    current_balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('active', 'inactive') DEFAULT 'active'
);

CREATE TABLE movimientos_bancarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bank_id INT NOT NULL,
    type ENUM('deposit', 'withdrawal', 'transfer_in', 'transfer_out') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    concept VARCHAR(150) NOT NULL,
    reference_type ENUM('venta', 'pago_credito', 'gasto', 'pago_proveedor', 'otro') NOT NULL,
    reference_id INT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bank_id) REFERENCES bancos(id)
);

-- ========================
-- Pagos a proveedores (cuentas por pagar)
-- ========================
CREATE TABLE pagos_proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id INT NOT NULL,
    supplier_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card', 'other') NOT NULL DEFAULT 'cash',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,
    FOREIGN KEY (purchase_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES proveedores(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

-- ========================
-- Gastos
-- ========================
CREATE TABLE categorias_gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO categorias_gastos (name) VALUES
('Servicios (agua, luz, internet)'),
('Alquiler'),
('Salarios'),
('Transporte'),
('Mantenimiento'),
('Publicidad'),
('Otros');

INSERT INTO categorias_gastos (name) VALUES ('Faltante de Caja');

ALTER TABLE categorias_gastos
    ADD COLUMN is_system BOOLEAN NOT NULL DEFAULT FALSE;
    
UPDATE categorias_gastos SET is_system = TRUE WHERE id = 8;

CREATE TABLE gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    concept VARCHAR(150) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'bank') NOT NULL,
    caja_id INT NULL,
    bank_id INT NULL,
    user_id INT NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categorias_gastos(id),
    FOREIGN KEY (caja_id) REFERENCES cajas(id) ON DELETE SET NULL,
    FOREIGN KEY (bank_id) REFERENCES bancos(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

-- ========================
-- Ingresos extra (no relacionados a ventas)
-- ========================
CREATE TABLE ingresos_extra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    concept VARCHAR(150) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'bank') NOT NULL,
    caja_id INT NULL,
    bank_id INT NULL,
    user_id INT NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (caja_id) REFERENCES cajas(id) ON DELETE SET NULL,
    FOREIGN KEY (bank_id) REFERENCES bancos(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

ALTER TABLE ingresos_extra
    ADD COLUMN is_system BOOLEAN NOT NULL DEFAULT FALSE;
