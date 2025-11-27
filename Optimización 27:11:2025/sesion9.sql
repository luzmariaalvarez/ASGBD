-- #########################################################
--  MONITORIZACIÓN AVANZADA EN MYSQL
--  - Crea BD de ejemplo
--  - Crea tablas y datos
--  - Activa slow_query_log
--  - Genera consultas lentas
--  - Analiza slow_log y performance_schema
--  - Usa EXPLAIN antes y después de crear índices
-- #########################################################


-- =========================================================
-- CREAR Y USAR LA BASE DE DATOS DE TRABAJO
-- =========================================================

-- Crea la base de datos solo si no existe.
CREATE DATABASE monitorizacion;



-- =========================================================
-- BLOQUE 1: CREAR TABLA CLIENTES Y CARGAR DATOS
-- =========================================================

-- Creamos una tabla de clientes.
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY, 
    nombre     VARCHAR(50) NOT NULL,           
    apellidos  VARCHAR(80) NOT NULL,           
    email      VARCHAR(100) NOT NULL,          
    ciudad     VARCHAR(50) NOT NULL            
);


-- Insertamos algunos clientes
INSERT INTO clientes (nombre, apellidos, email, ciudad) VALUES
('Ana',     'Gómez López',      'ana.gomez@example.com',       'Madrid'),
('Luis',    'Pérez Martín',     'luis.perez@example.com',      'Sevilla'),
('María',   'López García',     'maria.lopez@example.com',     'Valencia'),
('Javier',  'Sánchez Ruiz',     'javier.sanchez@example.com',  'Madrid'),
('Lucía',   'Torres Díaz',      'lucia.torres@example.com',    'Barcelona'),
('Pedro',   'Ramírez Ortiz',    'pedro.ramirez@example.com',   'Madrid'),
('Elena',   'Castro Romero',    'elena.castro@example.com',    'Bilbao'),
('Carlos',  'Núñez Herrera',    'carlos.nunez@example.com',    'Sevilla'),
('Sara',    'Jiménez Flores',   'sara.jimenez@example.com',    'Valencia'),
('Diego',   'Moreno Santos',    'diego.moreno@example.com',    'Madrid'),
('Paula',   'Ibáñez Gil',       'paula.ibanez@example.com',    'Granada'),
('Hugo',    'Vidal Vega',       'hugo.vidal@example.com',      'Madrid'),
('Nuria',   'Navarro León',     'nuria.navarro@example.com',   'Zaragoza'),
('Raúl',    'Domínguez Cano',   'raul.dominguez@example.com',  'Sevilla'),
('Carmen',  'Serrano Molina',   'carmen.serrano@example.com',  'Madrid');


-- =========================================================
-- BLOQUE 2: CREAR TABLA PEDIDOS Y CARGAR DATOS
-- =========================================================

CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido   INT AUTO_INCREMENT PRIMARY KEY,  
    id_cliente  INT NOT NULL,                    
    fecha       DATE NOT NULL,                  
    importe     DECIMAL(10,2) NOT NULL,          
    estado      VARCHAR(20) NOT NULL,            
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);



-- Insertamos pedidos.
INSERT INTO pedidos (id_cliente, fecha, importe, estado) VALUES
(1,  '2025-11-01', 120.50, 'PAGADO'),
(1,  '2025-11-10',  80.20, 'PENDIENTE'),
(2,  '2025-11-05',  60.00, 'PAGADO'),
(3,  '2025-10-29', 210.00, 'PAGADO'),
(3,  '2025-11-15',  15.99, 'PENDIENTE'),
(4,  '2025-11-02',  45.75, 'PAGADO'),
(5,  '2025-11-03',  99.90, 'PAGADO'),
(6,  '2025-11-04', 300.00, 'PENDIENTE'),
(7,  '2025-11-06',  12.00, 'PAGADO'),
(8,  '2025-11-07',  70.70, 'PAGADO'),
(9,  '2025-11-08', 130.30, 'PENDIENTE'),
(10, '2025-11-09',  55.55, 'PAGADO'),
(11, '2025-11-11',  20.00, 'PENDIENTE'),
(12, '2025-11-12', 180.90, 'PAGADO'),
(13, '2025-11-13',  33.33, 'PAGADO'),
(14, '2025-11-14',  77.77, 'PAGADO'),
(15, '2025-11-16',  99.99, 'PENDIENTE');


-- =========================================================
-- BLOQUE 3: CONSULTAS DE EJEMPLO (ANTES DE OPTIMIZAR)
-- Estas consultas luego las analizaremos con EXPLAIN y en el slow_log.
-- =========================================================

-- 3.1 Buscar un cliente por email (sin índice todavía).
SELECT * 
FROM clientes 
WHERE email = 'ana.gomez@example.com';

-- 3.2 Buscar todos los clientes de Madrid.
SELECT *
FROM clientes
WHERE ciudad = 'Madrid';

-- 3.3 Join típico entre pedidos y clientes filtrando por ciudad.
SELECT p.id_pedido, c.nombre, c.apellidos, p.fecha, p.importe, p.estado
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE c.ciudad = 'Madrid'
ORDER BY p.fecha DESC;


-- =========================================================
-- BLOQUE 4: ACTIVAR LOG DE CONSULTAS LENTAS (GLOBAL)
-- Ejecutar con usuario con permisos (SUPER / administrador).
-- Si da error de permisos, este bloque no se podrá usar en tu servidor.
-- =========================================================

-- Activa el log de consultas lentas.
SET GLOBAL slow_query_log = 1;

-- Considera "lenta" toda consulta que tarde más de 0.5 segundos.
SET GLOBAL long_query_time = 0.5;

-- Indica que el log de consultas se guarda en la tabla mysql.slow_log (no es un fichero).
SET GLOBAL log_output = 'TABLE';



-- Comprobamos que las variables se han establecido correctamente, para comprobar los valores
-- Se neecesitan permisos de administrador

SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'log_output';


-- =========================================================
-- BLOQUE 5: GENERAR CONSULTAS "LENTAS" PARA TENER DATOS
-- Ejecuta varias veces estas consultas para que queden registradas.
-- =========================================================

-- 5.1 Pausa de 1 segundo: se considera consulta lenta según long_query_time.
SELECT SLEEP(1) AS pausa_1_segundo;

-- 5.2 Carga de CPU con BENCHMARK (ejecuta muchas veces la función SHA2).
-- BENCHMARK(n, expresión) = ejecuta la expresión n veces seguidas.
-- Sirve para forzar trabajo al servidor y poder medir cuánto tarda.
-- n = 3000000 = 3 millones de veces.
-- calcula el hash SHA-256 de la cadena 'monitorizacion'
-- Calcula el hash SHA2 de la palabra ‘monitorizacion’ tres millones de veces seguidas.
-- Eso consume mucha CPU tarda más de 0.5 segundos y MySQL la considera consulta lenta 
-- y la mete en mysql.slow_log.

SELECT BENCHMARK(3000000, SHA2('monitorizacion', 256)) AS prueba_cpu_1;
SELECT BENCHMARK(3000000, SHA2('monitorizacion', 256)) AS prueba_cpu_2;

-- 5.3 Consulta que lee muchas filas de metadatos (puede tardar un poco).
SELECT * FROM information_schema.tables;

-- 5.4 Hacemos también alguna consulta sobre nuestras tablas de ejemplo.
SELECT * FROM clientes WHERE ciudad = 'Madrid';
SELECT p.id_pedido, c.nombre, c.apellidos, p.fecha, p.importe, p.estado
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE c.ciudad = 'Madrid'
ORDER BY p.fecha DESC;


-- =========================================================
-- BLOQUE 6: VER QUÉ SE HA REGISTRADO EN mysql.slow_log
-- Aquí analizamos las consultas lentas que se han guardado.
-- =========================================================

SELECT 
    start_time,    -- Momento en que empezó la consulta
    user_host,     -- Usuario y host desde el que se ejecutó
    query_time,    -- Tiempo total que tardó la consulta
    lock_time,     -- Tiempo en bloqueos
    rows_sent,     -- Filas enviadas al cliente
    rows_examined, -- Filas examinadas para generar el resultado
    sql_text       -- Texto completo de la consulta
FROM mysql.slow_log
ORDER BY start_time DESC;

-- Ves:
-- Cuándo se lanzó cada consulta lenta.
-- Cuánto tardó (query_time).
-- Cuántas filas examinó (rows_examined).
-- El texto de la consulta (sql_text).


-- =========================================================
-- BLOQUE 7: USAR performance_schema
-- Ranking de las consultas que más tiempo total consumen.
-- Si esta consulta da error, es que tu servidor no tiene
-- performance_schema o no tiene esa tabla: en ese caso,
-- simplemente usa solo mysql.slow_log.
-- =========================================================

-- Dame las 10 formas de consulta que más tiempo total están consumiendo en mi servidor.
SELECT 
    digest_text,                 -- Forma general de la consulta (sin parámetros concretos)
    COUNT_STAR        AS ejecuciones,       -- Cuántas veces se ejecutó
    SUM_TIMER_WAIT    AS tiempo_total,      -- Tiempo total acumulado (unidad interna, pico-segundos)
    AVG_TIMER_WAIT    AS tiempo_medio,      -- Tiempo medio por ejecución
    SUM_ROWS_SENT     AS filas_enviadas,    -- Total de filas enviadas
    SUM_ROWS_EXAMINED AS filas_examinadas   -- Total de filas examinadas
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 10;


-- =========================================================
-- BLOQUE 8: EXPLAIN SOBRE LAS CONSULTAS (ANTES DE ÍNDICES)
-- Vemos cómo MySQL ejecuta las consultas actuales, sin optimizar.
-- =========================================================

-- Plan de ejecución de búsqueda por email.
-- Leer toda la tabla clientes (15 filas) y, sobre ellas, mirar cuál tiene ese email.
-- Con 15 filas da igual, pero con 15.000 o 15 millones sería un drama
-- por es creamos indices

EXPLAIN
SELECT * 
FROM clientes 
WHERE email = 'ana.gomez@example.com';

-- Plan de ejecución de búsqueda por ciudad.
EXPLAIN
SELECT *
FROM clientes
WHERE ciudad = 'Madrid';

-- Plan de ejecución del join pedidos + clientes filtrando por ciudad.
-- Para cada pedido, busco el cliente por su PK, y luego miro si ese cliente es de Madrid.
-- necesitamos un índice
EXPLAIN
SELECT p.id_pedido, c.nombre, c.apellidos, p.fecha, p.importe, p.estado
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE c.ciudad = 'Madrid'
ORDER BY p.fecha DESC;


-- =========================================================
-- BLOQUE 9: CREAR ÍNDICES Y REPETIR EXPLAIN
-- Creamos índices para optimizar y comparamos los planes.
-- =========================================================

-- Índice por email para búsquedas rápidas de clientes por email.
CREATE INDEX idx_clientes_email ON clientes(email);

-- Índice por ciudad para filtros por ciudad.
CREATE INDEX idx_clientes_ciudad ON clientes(ciudad);

-- Repetimos EXPLAIN para ver si ahora usa los índices:

EXPLAIN
SELECT * 
FROM clientes 
WHERE email = 'ana.gomez@example.com';

EXPLAIN
SELECT *
FROM clientes
WHERE ciudad = 'Madrid';

EXPLAIN
SELECT p.id_pedido, c.nombre, c.apellidos, p.fecha, p.importe, p.estado
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
WHERE c.ciudad = 'Madrid'
ORDER BY p.fecha DESC;

