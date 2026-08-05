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
-- ========================
CREATE TABLE compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT,
    user_id INT,
    purchase_price DECIMAL(10, 2),
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
-- ========================
CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    customer_id INT NULL,
    total DECIMAL(10, 2),
    earned_points INT DEFAULT 0,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (customer_id) REFERENCES clientes(id) ON DELETE SET NULL
);

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