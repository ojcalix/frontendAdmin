CREATE DATABASE vansue DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
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
-- (Encabezado: nombre, marca, categoría, descripción.
--  Precio, stock, código de barras e imágenes propias viven en variantes)
-- ========================
CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    brand VARCHAR(100),
    description TEXT,
    category_id INT NOT NULL,
    gender_id INT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive') DEFAULT 'active',

    FOREIGN KEY (category_id) REFERENCES categorias(id),
    FOREIGN KEY (gender_id) REFERENCES generos(id)
);

-- ========================
-- Imágenes de producto
-- ========================
CREATE TABLE productos_imagenes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    image VARCHAR(255) NOT NULL,
    type ENUM('principal', 'hover', 'extra') NOT NULL,

    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE
);

-- ========================
-- Variantes
-- (average_cost: costo promedio ponderado de la variante. Existe en tu
--  base real pero NINGÚN endpoint que he revisado lo actualiza todavía
--  — confirmar si hay lógica pendiente de conectar aquí)
-- ========================
CREATE TABLE variantes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    variant_name VARCHAR(100) NOT NULL,
    sale_price DECIMAL(10, 2) NOT NULL,
    average_cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    quantity INT NOT NULL DEFAULT 0,
    barcode VARCHAR(20) NULL,
    status ENUM('active', 'inactive') DEFAULT 'active',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE,
    INDEX idx_variantes_product_id (product_id),
    INDEX idx_barcode (barcode)
);

-- ========================
-- Imágenes de variante
-- ========================
CREATE TABLE variantes_imagenes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    variant_id INT NOT NULL,
    image VARCHAR(255) NOT NULL,
    type ENUM('principal', 'hover', 'extra') NOT NULL,

    FOREIGN KEY (variant_id) REFERENCES variantes(id) ON DELETE CASCADE
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
-- Proveedores
-- (phone es NULLABLE en tu base real — corregido aquí)
-- ========================
CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100) NULL,
    address VARCHAR(255) NULL,
    city VARCHAR(100) NULL,
    state VARCHAR(100) NULL,
    country VARCHAR(100) NULL DEFAULT 'Honduras',
    phone VARCHAR(20) NULL,
    phone_secondary VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    notes VARCHAR(255) NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

-- Nota: tu base real ya tiene AUTO_INCREMENT en 24 (17 cuentas insertadas,
-- con un hueco entre los ids 15-20 de cuentas que se crearon y luego se
-- borraron — no afecta nada, los ids no se referencian en el código,
-- solo el "code"). Esta lista fue confirmada contra tu tabla real.
INSERT INTO cuentas_contables (code, name, type, nature) VALUES
('1101', 'Caja General',                       'activo',     'deudora'),
('1102', 'Bancos',                             'activo',     'deudora'),
('1103', 'Cuentas por Cobrar',                 'activo',     'deudora'),
('1104', 'Inventario',                         'activo',     'deudora'),
('2101', 'Cuentas por Pagar a Proveedores',    'pasivo',     'acreedora'),
('2102', 'Tarjetas de Crédito',                'pasivo',     'acreedora'),
('2103', 'Financiamiento del Propietario',     'pasivo',     'acreedora'),
('2104', 'Otras Obligaciones',                 'pasivo',     'acreedora'),
('2105', 'Préstamos por Pagar',                'pasivo',     'acreedora'),
('3101', 'Capital Social',                     'patrimonio', 'acreedora'),
('4101', 'Ventas',                             'ingreso',    'acreedora'),
('4102', 'Otros Ingresos',                     'ingreso',    'acreedora'),
('5101', 'Costo de Ventas',                    'costo',      'deudora'),
('6101', 'Gastos Generales',                   'gasto',      'deudora'),
('6102', 'Gastos de Compras',                  'gasto',      'deudora'),
('6103', 'Gastos Financieros (Intereses)',     'gasto',      'deudora'),
('6104', 'Comisiones y Cargos Bancarios',       'gasto',      'deudora');

-- ========================
-- Libro diario (asientos contables)
-- ========================
CREATE TABLE asientos_contables (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entry_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255) NOT NULL,
    reference_type ENUM('venta', 'compra', 'pago_credito', 'pago_proveedor', 'pago_financiamiento', 'gasto', 'ingreso_extra', 'apertura_caja', 'cierre_caja', 'ajuste') NOT NULL,
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
    reference_type ENUM('venta', 'compra', 'pago_credito', 'gasto', 'pago_proveedor', 'otro') NOT NULL,
    reference_id INT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bank_id) REFERENCES bancos(id)
);

-- ========================
-- Fuentes de financiamiento
-- ========================
CREATE TABLE fuentes_financiamiento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type ENUM('tarjeta_credito', 'propietario', 'otro') NOT NULL,
    account_id INT NOT NULL,
    credit_limit DECIMAL(10,2) NULL,
    current_balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('active', 'inactive') DEFAULT 'active',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (account_id) REFERENCES cuentas_contables(id)
);

CREATE TABLE movimientos_financiamiento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    financing_source_id INT NOT NULL,
    type ENUM('charge', 'payment') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    concept VARCHAR(150) NOT NULL,
    reference_type ENUM('compra', 'pago_financiamiento', 'ajuste') NOT NULL,
    reference_id INT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (financing_source_id) REFERENCES fuentes_financiamiento(id)
);

CREATE TABLE pagos_financiamiento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    financing_source_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card', 'other') NOT NULL DEFAULT 'cash',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,

    FOREIGN KEY (financing_source_id) REFERENCES fuentes_financiamiento(id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
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
    reference_type ENUM('venta', 'compra', 'pago_credito', 'gasto', 'pago_proveedor', 'otro') NOT NULL,
    reference_id INT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (caja_id) REFERENCES cajas(id) ON DELETE CASCADE
);

-- ========================
-- Compras
-- (user_id y purchase_price son NULLABLE en tu base real — corregido
--  aquí. payment_type TODAVÍA NO incluye 'opening' en tu base real: ver
--  la migración pendiente al final de este archivo)
-- ========================
CREATE TABLE compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NULL,
    user_id INT NULL,

    payment_type ENUM('cash', 'credit', 'mixed') NOT NULL DEFAULT 'cash',
    payment_method ENUM('cash', 'transfer', 'card', 'financing') NOT NULL DEFAULT 'cash',
    bank_id INT NULL,
    financing_source_id INT NULL,
    payment_status ENUM('paid', 'partial', 'pending') NOT NULL DEFAULT 'paid',

    purchase_price DECIMAL(10, 2) NULL,
    shipping_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    pending_amount DECIMAL(10,2) NOT NULL DEFAULT 0,

    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (supplier_id) REFERENCES proveedores(id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (bank_id) REFERENCES bancos(id),
    FOREIGN KEY (financing_source_id) REFERENCES fuentes_financiamiento(id)
);

-- ========================
-- Detalle de compras
-- ========================
CREATE TABLE detalle_compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity INT NOT NULL,
    purchase_price DECIMAL(10, 2) NOT NULL,

    FOREIGN KEY (purchase_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES variantes(id) ON DELETE CASCADE
);

-- ========================
-- Ventas
-- (user_id es NULLABLE en tu base real — corregido aquí)
-- ========================
CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    customer_id INT NULL,

    payment_type ENUM('cash', 'credit', 'mixed') NOT NULL DEFAULT 'cash',
    payment_method ENUM('cash', 'transfer', 'card') NOT NULL DEFAULT 'cash',
    bank_id INT NULL,
    payment_status ENUM('paid', 'partial', 'pending') NOT NULL DEFAULT 'paid',

    total DECIMAL(10, 2) NOT NULL,
    paid_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    pending_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,

    earned_points INT DEFAULT 0,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (customer_id) REFERENCES clientes(id) ON DELETE SET NULL,
    FOREIGN KEY (bank_id) REFERENCES bancos(id)
);

-- ========================
-- Detalle de ventas
-- ========================
CREATE TABLE ventas_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity INT NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    earned_points INT DEFAULT 0,

    FOREIGN KEY (sale_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES productos(id) ON DELETE CASCADE,
    FOREIGN KEY (variant_id) REFERENCES variantes(id) ON DELETE CASCADE
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
-- Precio por proveedor
-- ========================
CREATE TABLE producto_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    supplier_id INT NOT NULL,
    variant_id INT NULL,
    purchase_price DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (product_id) REFERENCES productos(id),
    FOREIGN KEY (supplier_id) REFERENCES proveedores(id),
    FOREIGN KEY (variant_id) REFERENCES variantes(id) ON DELETE CASCADE,
    UNIQUE (product_id, supplier_id, variant_id)
);

-- ========================
-- Categorías de gastos
-- ========================
CREATE TABLE categorias_gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    is_system BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO categorias_gastos (name, is_system) VALUES
('Servicios (agua, luz, internet)',    FALSE),
('Alquiler',                           FALSE),
('Salarios',                           FALSE),
('Transporte',                         FALSE),
('Mantenimiento',                      FALSE),
('Publicidad',                         FALSE),
('Otros',                              FALSE),
('Envío / Flete de Mercadería',        FALSE),
('Faltante de Caja',                   TRUE);

-- ========================
-- Gastos
-- ========================
CREATE TABLE gastos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    purchase_id INT NULL,
    concept VARCHAR(150) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'bank') NOT NULL,
    caja_id INT NULL,
    bank_id INT NULL,
    user_id INT NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categorias_gastos(id),
    FOREIGN KEY (purchase_id) REFERENCES compras(id) ON DELETE SET NULL,
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
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (caja_id) REFERENCES cajas(id) ON DELETE SET NULL,
    FOREIGN KEY (bank_id) REFERENCES bancos(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

-- ========================
-- Préstamos
-- ========================
CREATE TABLE prestamos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    lender_name VARCHAR(150) NOT NULL,
    principal_amount DECIMAL(10,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    term_months INT NOT NULL,
    monthly_payment DECIMAL(10,2) NOT NULL,
    commission_type ENUM('descontada', 'aparte', 'ninguna') NOT NULL DEFAULT 'ninguna',
    commission_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    disbursement_method ENUM('cash', 'bank') NOT NULL DEFAULT 'bank',
    bank_id INT NULL,
    disbursement_date DATE NOT NULL,
    status ENUM('active', 'paid', 'cancelled') NOT NULL DEFAULT 'active',
    user_id INT NOT NULL,
    notes VARCHAR(255) NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (bank_id) REFERENCES bancos(id),
    FOREIGN KEY (user_id) REFERENCES usuarios(id)
);

CREATE TABLE cargos_prestamo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prestamo_id INT NOT NULL,
    concept VARCHAR(150) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    charge_type ENUM('descontado', 'aparte') NOT NULL DEFAULT 'descontado',

    FOREIGN KEY (prestamo_id) REFERENCES prestamos(id) ON DELETE CASCADE
);

CREATE TABLE cuotas_prestamo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prestamo_id INT NOT NULL,
    number INT NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    interest_portion DECIMAL(10,2) NOT NULL,
    principal_portion DECIMAL(10,2) NOT NULL,
    interest_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
    principal_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('pending', 'partial', 'paid') NOT NULL DEFAULT 'pending',

    FOREIGN KEY (prestamo_id) REFERENCES prestamos(id) ON DELETE CASCADE
);

CREATE TABLE pagos_prestamo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prestamo_id INT NOT NULL,
    cuota_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    interest_paid DECIMAL(10,2) NOT NULL,
    principal_paid DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card') NOT NULL DEFAULT 'cash',
    bank_id INT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,

    FOREIGN KEY (prestamo_id) REFERENCES prestamos(id) ON DELETE CASCADE,
    FOREIGN KEY (cuota_id) REFERENCES cuotas_prestamo(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (bank_id) REFERENCES bancos(id)
);

CREATE TABLE abonos_capital_prestamo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prestamo_id INT NOT NULL,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'transfer', 'card') NOT NULL DEFAULT 'cash',
    bank_id INT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,

    FOREIGN KEY (prestamo_id) REFERENCES prestamos(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (bank_id) REFERENCES bancos(id)
);

ALTER TABLE ventas
    ADD COLUMN status ENUM('completada', 'cancelada') NOT NULL DEFAULT 'completada' AFTER payment_status,
    ADD COLUMN cancelled_at TIMESTAMP NULL,
    ADD COLUMN cancelled_by INT NULL,
    ADD COLUMN cancel_reason VARCHAR(255) NULL,
    ADD FOREIGN KEY (cancelled_by) REFERENCES usuarios(id);