/* =========================================================
   PRÁCTICA - MODO ALUMNADO (CON HUECOS)
   Tema: Fragmentación horizontal/vertical + replicación simulada
   Entorno: MySQL + phpMyAdmin
   ========================================================= */

-- 0) CREAR BD (y usarla)
DROP DATABASE IF EXISTS empresa_global;
CREATE DATABASE empresa_global
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE empresa_global;

-- =========================================================
-- PARTE 1: TABLA CENTRAL
-- =========================================================

CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  pais CHAR(2) NOT NULL,               -- ES, FR, DE
  tarjeta_credito VARCHAR(32) NOT NULL
);

-- 1) INSERTA al menos 9 clientes (3 por país)
--    ES, FR, DE (mínimo 3 por cada uno)
-- TODO: añade aquí tus INSERT
-- INSERT INTO clientes (...) VALUES (...), (...), ... ;

/* =========================================================
   PARTE 2: FRAGMENTACIÓN HORIZONTAL (POR PAÍS)
   Tablas: clientes_es, clientes_fr, clientes_de
   ========================================================= */

-- 2) CREA las 3 tablas fragmentadas copiando estructura de clientes
-- TODO:
-- CREATE TABLE clientes_es LIKE clientes;
-- CREATE TABLE clientes_fr LIKE clientes;
-- CREATE TABLE clientes_de LIKE clientes;

-- 3) RELLENA cada fragmento con los registros de su país
-- TODO:
-- INSERT INTO clientes_es SELECT * FROM clientes WHERE pais = 'ES';
-- INSERT INTO clientes_fr SELECT * FROM clientes WHERE pais = 'FR';
-- INSERT INTO clientes_de SELECT * FROM clientes WHERE pais = 'DE';

-- 4) CREA una VISTA que unifique todos los fragmentos
--    Nombre: v_clientes_global
--    Pista: UNION ALL
-- TODO:
-- CREATE OR REPLACE VIEW v_clientes_global AS
-- SELECT * FROM clientes_es
-- UNION ALL
-- SELECT * FROM clientes_fr
-- UNION ALL
-- SELECT * FROM clientes_de;

-- 5) COMPRUEBA que la vista devuelve todos los clientes
-- TODO:
-- SELECT * FROM v_clientes_global ORDER BY pais, id_cliente;

/* =========================================================
   PARTE 3: FRAGMENTACIÓN VERTICAL (DATOS VS PAGOS)
   Tablas: clientes_datos, clientes_pagos
   ========================================================= */

-- 6) CREA clientes_datos con: id_cliente (PK), nombre, email (UNIQUE), pais
-- TODO:
-- CREATE TABLE clientes_datos ( ... ) ENGINE=InnoDB;

-- 7) CREA clientes_pagos con: id_cliente (PK, FK), tarjeta_credito
--    FK a clientes_datos(id_cliente) con ON DELETE CASCADE
-- TODO:
-- CREATE TABLE clientes_pagos ( ... ) ENGINE=InnoDB;

-- 8) PUEBLA ambas tablas verticales desde clientes
-- TODO:
-- INSERT INTO clientes_datos (...) SELECT ... FROM clientes;
-- INSERT INTO clientes_pagos (...) SELECT ... FROM clientes;

-- 9) CREA una VISTA que reconstruya el cliente completo mediante JOIN
--    Nombre: v_clientes_completo
-- TODO:
-- CREATE OR REPLACE VIEW v_clientes_completo AS
-- SELECT ...
-- FROM clientes_datos d
-- JOIN clientes_pagos p ON ...;

-- 10) CONSULTA: mostrar nombre, email y tarjeta_credito desde la vista
-- TODO:
-- SELECT nombre, email, tarjeta_credito FROM v_clientes_completo;

/* =========================================================
   PARTE 4: REPLICACIÓN SIMULADA (BACKUP)
   Tabla: clientes_backup (copia de clientes_datos)
   ========================================================= */

-- 11) CREA clientes_backup con la misma estructura que clientes_datos
-- TODO:
-- 

-- 12) COPIA los datos iniciales (simula réplica puntual)
-- TODO:
-- 

-- 13) SIMULA un fallo: borra un cliente de clientes_datos por email
--     (elige uno de los que insertaste)
-- TODO:
-- 

-- 14) COMPRUEBA:
--     a) que ya no está en clientes_datos
--     b) que sigue en clientes_backup
-- TODO:
-- 
-- 
