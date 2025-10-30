
-- 01_dataset.sql
-- Esquema y datos de ejemplo (PostgreSQL / MariaDB / SQL Server con pequeñas adaptaciones).
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS empleados;
DROP TABLE IF EXISTS secciones;

CREATE TABLE secciones (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

CREATE TABLE empleados (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  puesto  VARCHAR(50) NOT NULL,
  estado  VARCHAR(20) NOT NULL DEFAULT 'Activo',
  id_seccion INT REFERENCES secciones(id)
);

CREATE TABLE clientes (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  pais   VARCHAR(60) NOT NULL
);

CREATE TABLE productos (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  precio NUMERIC(10,2) NOT NULL,
  stock  INT NOT NULL DEFAULT 0
);

CREATE TABLE ventas (
  id SERIAL PRIMARY KEY,
  id_cliente  INT REFERENCES clientes(id),
  id_empleado INT REFERENCES empleados(id),
  id_producto INT REFERENCES productos(id),
  cantidad INT NOT NULL,
  importe  NUMERIC(10,2) NOT NULL,
  fecha DATE NOT NULL
);

INSERT INTO secciones (nombre) VALUES ('Electrónica'),('Moda'),('Hogar'),('Deportes');

INSERT INTO empleados (nombre, puesto, estado, id_seccion) VALUES
('Ana Ruiz','Vendedor','Activo',1),
('Luis Pérez','Vendedor','Activo',2),
('Marta Gil','Gerente','Activo',1),
('Sergio Mora','Vendedor','Inactivo',3);

INSERT INTO clientes (nombre, pais) VALUES
('ACME S.L.','España'),
('Globex','España'),
('Innotech','Portugal'),
('BlueCorp','Francia');

INSERT INTO productos (nombre, precio, stock) VALUES
('Portátil 14"',799.00,25),
('Auriculares BT',59.90,200),
('Zapatillas Run',89.00,15),
('Sofá 3 plazas',499.00,5);

INSERT INTO ventas (id_cliente,id_empleado,id_producto,cantidad,importe,fecha) VALUES
(1,1,1,1,799.00,'2025-01-05'),
(2,1,2,3,179.70,'2025-01-06'),
(3,2,3,2,178.00,'2025-02-02'),
(4,2,2,1,59.90,'2025-02-15'),
(1,3,4,1,499.00,'2025-03-10'),
(2,1,1,1,799.00,'2025-03-12');
