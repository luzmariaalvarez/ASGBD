/* =========================================================
   PRÁCTICA - Sesión 12
   MySQL + phpMyAdmin
   - Crear una BD de ejemplo
   - Crear una tabla central (clientes)
   - Aplicar fragmentación HORIZONTAL (por país)
   - Aplicar fragmentación VERTICAL (datos vs pagos)
   - Simular replicación (backup)
   - Simular un fallo (borrado)
   - Comprobar resultados con consultas
   ========================================================= */


/* ---------------------------------------------------------
   1) BORRADO Y CREACIÓN DE LA BASE DE DATOS
   --------------------------------------------------------- */

-- Crea la base de datos desde cero
CREATE DATABASE empresa_global;

USE empresa_global;


/* ---------------------------------------------------------
   2) TABLA CENTRAL -  TABLA "ORIGINAL"
   --------------------------------------------------------- */

-- Crea la tabla clientes (tabla central no fragmentada)
CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  pais CHAR(2) NOT NULL,
  tarjeta_credito VARCHAR(32) NOT NULL
);

-- Inserta registros de ejemplo en la tabla central
INSERT INTO clientes (nombre, email, pais, tarjeta_credito) VALUES
('Ana Ruiz',        'ana.ruiz@correo.com',        'ES', '4111111111111111'),
('Luis Martín',     'luis.martin@correo.com',     'ES', '5555555555554444'),
('Carmen López',    'carmen.lopez@correo.com',    'ES', '378282246310005'),
('Jean Dupont',     'jean.dupont@correo.com',     'FR', '6011000990139424'),
('Marie Curie',     'marie.curie@correo.com',     'FR', '3530111333300000'),
('Luc Moreau',      'luc.moreau@correo.com',      'FR', '4000002500003155'),
('Hans Müller',     'hans.mueller@correo.com',    'DE', '4000002760003184'),
('Greta Schmidt',   'greta.schmidt@correo.com',   'DE', '4000001240000000'),
('Max Weber',       'max.weber@correo.com',       'DE', '5200828282828210');


/* ---------------------------------------------------------
   3) FRAGMENTACIÓN HORIZONTAL
   Divide FILAS: cada fragmento se queda con filas según una condición
   En este caso: cada país a su propia tabla.
   --------------------------------------------------------- */

-- Crea 3 tablas con la MISMA estructura que clientes (LIKE copia estructura, no datos)
CREATE TABLE clientes_es LIKE clientes;
CREATE TABLE clientes_fr LIKE clientes;
CREATE TABLE clientes_de LIKE clientes;

-- Copia a cada fragmento las filas que cumplen la condición del país
INSERT INTO clientes_es SELECT * FROM clientes WHERE pais='ES';
INSERT INTO clientes_fr SELECT * FROM clientes WHERE pais='FR';
INSERT INTO clientes_de SELECT * FROM clientes WHERE pais='DE';

-- Vista para “reconstruir” la tabla global uniendo los fragmentos horizontales
-- UNION ALL: une resultados SIN eliminar duplicados
CREATE OR REPLACE VIEW v_clientes_global AS
SELECT * FROM clientes_es
UNION ALL
SELECT * FROM clientes_fr
UNION ALL
SELECT * FROM clientes_de;


/* ---------------------------------------------------------
   4) FRAGMENTACIÓN VERTICAL
   Divide COLUMNAS: separa datos sensibles o de uso distinto
   En este caso:
   - clientes_datos: info general
   - clientes_pagos: tarjeta de crédito
   La unión se hace por id_cliente.
   --------------------------------------------------------- */

-- Tabla con los datos generales del cliente (sin tarjeta)
CREATE TABLE clientes_datos (
  -- Mantiene el mismo identificador (será la clave para reconstruir)
  id_cliente INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  pais CHAR(2) NOT NULL
);

-- Tabla con los datos de pago (solo tarjeta)
CREATE TABLE clientes_pagos (
  id_cliente INT PRIMARY KEY,
  tarjeta_credito VARCHAR(32) NOT NULL,
  -- Clave foránea: exige que exista el cliente en clientes_datos para poder tener pago
  CONSTRAINT fk_pagos_cliente
    FOREIGN KEY (id_cliente) REFERENCES clientes_datos(id_cliente)
    -- Si se borra el cliente en clientes_datos, se borra automáticamente su pago
    ON DELETE CASCADE
    -- Si cambia el id_cliente (poco común), se actualiza en cascada
    ON UPDATE CASCADE
);

-- Rellena clientes_datos con columnas de la tabla original
INSERT INTO clientes_datos (id_cliente, nombre, email, pais)
SELECT id_cliente, nombre, email, pais FROM clientes;

-- Rellena clientes_pagos con la columna de tarjeta
INSERT INTO clientes_pagos (id_cliente, tarjeta_credito)
SELECT id_cliente, tarjeta_credito FROM clientes;

-- Vista para reconstruir el cliente “completo” uniendo datos + pagos
-- JOIN: solo aparecen clientes que estén en ambas tablas
CREATE OR REPLACE VIEW v_clientes_completo AS
SELECT d.id_cliente, d.nombre, d.email, d.pais, p.tarjeta_credito
FROM clientes_datos d
JOIN clientes_pagos p ON p.id_cliente = d.id_cliente;


/* ---------------------------------------------------------
   5) REPLICACIÓN SIMULADA (BACKUP)
   Copia de una tabla para tener redundancia
   --------------------------------------------------------- */

-- Crea una tabla backup con la misma estructura que clientes_datos
CREATE TABLE clientes_backup LIKE clientes_datos;

-- Copia todos los registros (simula “réplica” o backup)
INSERT INTO clientes_backup SELECT * FROM clientes_datos;


/* ---------------------------------------------------------
   6) SIMULACIÓN DE FALLO
   Borrar un registro para ver qué pasa con las vistas y cascadas
   --------------------------------------------------------- */

-- Borra a Ana del fragmento vertical "clientes_datos"
-- Al tener ON DELETE CASCADE, también debería borrarse su fila en clientes_pagos
DELETE FROM clientes_datos WHERE email='ana.ruiz@correo.com';


/* ---------------------------------------------------------
   7) PRUEBAS / COMPROBACIONES
   --------------------------------------------------------- */

-- 1) Unificación horizontal: muestra todos los clientes desde la vista global
-- (OJO: esta vista usa las tablas fragmentadas por país, no la central)
SELECT * FROM v_clientes_global ORDER BY pais, id_cliente;

-- 2) Reconstrucción vertical: une datos + pagos
-- Ana ya no aparece porque se borró de clientes_datos
SELECT * FROM v_clientes_completo ORDER BY pais, id_cliente;

-- 3) Comprobación backup: Ana sigue en el backup porque el backup no se tocó
SELECT * FROM clientes_backup WHERE email='ana.ruiz@correo.com';

-- 4) Comprobación de cascada:
-- Busca pagos “huérfanos” (que estén en pagos pero no en datos).
-- Si la cascada funcionó, NO debería salir nada.
SELECT * FROM clientes_pagos
WHERE id_cliente NOT IN (SELECT id_cliente FROM clientes_datos);
