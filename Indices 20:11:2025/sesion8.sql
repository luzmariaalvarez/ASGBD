/* ===========================================================
   SESIÓN 8 – ÍNDICES, ESTADÍSTICAS, PARTICIONAMIENTO Y EXPLAIN
   DEMO COMPLETA PARA TRABAJAR EN CLASE CON MYSQL
   =========================================================== */

-- -----------------------------------------------------------
-- 0. CREAR BASE DE DATOS DE PRUEBA
-- -----------------------------------------------------------
CREATE DATABASE sesion8_demo;
USE sesion8_demo;

-- -----------------------------------------------------------
-- 1. TABLA SIN ÍNDICES ESPECÍFICOS
--    (solo tendrá el índice de la PRIMARY KEY)
-- -----------------------------------------------------------
/*
 Creamos una tabla de alumnos. 
 IMPORTANTE: al principio NO creamos índice en dni.
*/
CREATE TABLE alumnos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    dni VARCHAR(9) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    curso VARCHAR(20) NOT NULL
);

-- Insertamos datos de ejemplo (pocos para la demo,
-- pero puedes duplicar INSERTs para simular una tabla grande)
INSERT INTO alumnos (dni, nombre, apellidos, curso) VALUES
('12345678A', 'Ana', 'López García', '1ESO'),
('23456789B', 'Luis', 'Gómez Gil', '2ESO'),
('34567890C', 'Marta', 'Ruiz Pérez', '3ESO'),
('45678901D', 'Carlos', 'Santos Díaz', '4ESO'),
('56789012E', 'Lucía', 'Martín López', '1ESO'),
('67890123F', 'Jorge', 'Fernández Ruiz', '2ESO'),
('78901234G', 'Elena', 'Torres Martínez', '3ESO'),
('89012345H', 'Raúl', 'Navarro Soto', '4ESO');

-- -----------------------------------------------------------
-- 2. CONSULTA SIN ÍNDICE EN DNI
-- -----------------------------------------------------------
/*
 "Vamos a buscar por dni pero SIN índice. 
  MySQL tendrá que mirar muchas filas."
*/

-- Se puede observar  que en EXPLAIN:
--  - type = ALL (escaneo completo de tabla)
--  - key = NULL (no usa índice)
--  - rows = nº de filas que revisa
-- No te da los datos, te explica cómo piensa ejecutar la consulta el motor de la base de datos.

EXPLAIN SELECT * FROM alumnos WHERE dni = '12345678A';

--table : qué tabla usa (alumnos)
-- type : tipo de acceso (por ejemplo, const, ref, ALL…)
-- possible_keys : índices que podría usar
-- key : índice que realmente va a usar (por ejemplo, un índice sobre dni)
-- rows : cuántas filas estima que tiene que mirar
-- Extra  detalles adicionales (por ejemplo, si usa Using index, etc.)
-- Sirve para:
-- Ver si está utilizando un índice o está haciendo un table scan (revisar toda la tabla).
-- Detectar problemas de rendimiento y optimizar la consulta (crear índices, cambiar condiciones, etc.).
-- No devuelve alumnos, sino información sobre el plan de ejecución.

-- Ejecutar también la consulta normal:
-- jecuta la consulta de verdad y te devuelve las filas que cumplen la condición.
SELECT * FROM alumnos WHERE dni = '12345678A';




-- -----------------------------------------------------------
-- 3. CREAR ÍNDICE EN dni Y REPETIR EXPLAIN
-- -----------------------------------------------------------
/*
 Ahora creamos un índice en la columna dni.
*/
CREATE INDEX idx_alumnos_dni ON alumnos(dni);

-- Volvemos a ver el plan de ejecución:
EXPLAIN SELECT * FROM alumnos WHERE dni = '12345678A';

-- Volvemos a ejecutar la consulta:
SELECT * FROM alumnos WHERE dni = '12345678A';

-- Cambios:
--  - type suele mejorar (ref/const)
--  - key = idx_alumnos_dni (ahora sí usa el índice)
--  - rows mucho menor (MySQL lee menos filas)


-- -----------------------------------------------------------
-- 4. ÍNDICE COMPUESTO (apellidos, nombre)
-- -----------------------------------------------------------
/*
 Creamos un índice para ordenar/buscar por apellidos y nombre.
*/
CREATE INDEX idx_alumnos_apellidos_nombre
    ON alumnos(apellidos, nombre);

-- Sirve para acelerar búsquedas y ordenaciones donde se use apellidos (y opcionalmente nombre).

-- Ejemplo de consulta que aprovecha ese índice:
EXPLAIN
SELECT * FROM alumnos
WHERE apellidos = 'Gómez Gil' AND nombre = 'Luis';

SELECT * FROM alumnos
WHERE apellidos = 'Gómez Gil' AND nombre = 'Luis';

-- Comentario para los alumnos:
-- El índice compuesto es útil cuando la búsqueda empieza por la primera columna del índice (apellidos).
-- Aprovecha el índice:
-- WHERE apellidos = 'Gómez Gil' AND nombre = 'Luis'
-- WHERE apellidos = 'Gómez Gil'
-- No aprovecha bien el índice:
-- WHERE nombre = 'Luis' (porque no empieza por apellidos)

-- -----------------------------------------------------------
-- 5. VER INFORMACIÓN DE ÍNDICES Y ESTADÍSTICAS BÁSICAS
-- -----------------------------------------------------------
/*
 SHOW INDEX nos da información sobre:
 - qué índices existen
 - cardinalidad (aprox. nº de valores distintos)
*/
SHOW INDEX FROM alumnos;

-- puedes:
-- Ver qué índices existen en la tabla.
-- Confirmar si has creado bien idx_alumnos_dni.
-- Ver si el índice compuesto idx_alumnos_apellidos_nombre aparece con dos filas (apellidos y nombre).
-- Revisar cardinalidad y tipo para detectar problemas de rendimiento.
-- Comprobar si MySQL aprovechará un índice en una consulta.

-- También podemos forzar actualización de estadísticas:
-- Vuelve a analizar esta tabla y actualiza las estadísticas de sus índices para que el optimizador 
-- pueda elegir mejor los planes de ejecución.
ANALYZE TABLE alumnos;

-- ANALYZE TABLE recalcula estadísticas que usa el optimizador
-- para decidir qué índice usar y cómo ejecutar la consulta.


-- -----------------------------------------------------------
-- 6. TABLA GRANDE DE VENTAS PARA PARTICIONAMIENTO
-- -----------------------------------------------------------
/*
 Ahora vamos a crear una tabla de ventas que simula 
 muchos años de datos. Vamos a prepararla ya particionada
 por rango de años usando la columna fecha.
*/


CREATE TABLE ventas (
    id INT AUTO_INCREMENT,
    fecha DATE NOT NULL,
    cliente_id INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id, fecha)   -- IMPORTANTE: la columna de partición
) 
PARTITION BY RANGE (YEAR(fecha)) (
    PARTITION p2019 VALUES LESS THAN (2020),
    PARTITION p2020 VALUES LESS THAN (2021),
    PARTITION p2021 VALUES LESS THAN (2022),
    PARTITION pmax  VALUES LESS THAN MAXVALUE
);


-- La tabla sigue siendo "ventas" pero internamente MySQL
-- guarda los datos en particiones p2019, p2020, p2021, etc.
-- En tablas particionadas por rango, MySQL obliga a que la columna de partición (fecha o expresión sobre ella) 
-- forme parte de la PRIMARY KEY / UNIQUE KEY.
-- Por eso la PK es (id, fecha) y no solo id.
-- Distribuye las filas en distintas particiones según el año de la columna fecha.
-- Las particiones quedan así:

-- PARTITION p2019 VALUES LESS THAN (2020). guarda filas donde YEAR(fecha) < 2020 (es decir, año 2019, 2018, 2017… si las hubiera).
-- PARTITION p2020 VALUES LESS THAN (2021) , YEAR(fecha) = 2020
-- PARTITION p2021 VALUES LESS THAN (2022), YEAR(fecha) = 2021
-- PARTITION pmax VALUES LESS THAN MAXVALUE, cualquier año ≥ 2022 (2022, 2023, 2024, …)


-- -----------------------------------------------------------
-- 7. INSERTAR DATOS DE EJEMPLO EN ventas
-- -----------------------------------------------------------
INSERT INTO ventas (fecha, cliente_id, total) VALUES
('2019-01-10', 1, 120.50),
('2019-05-22', 2, 80.00),
('2020-02-15', 3, 200.00),
('2020-07-30', 2, 50.00),
('2021-03-05', 1, 300.00),
('2021-11-19', 4, 150.50),
('2022-01-10', 3, 90.00),
('2023-06-21', 5, 450.00);

-- Podemos ver la tabla:
SELECT * FROM ventas;


-- -----------------------------------------------------------
-- 8. CREAR ÍNDICE COMPUESTO SOBRE (fecha, cliente_id)
-- -----------------------------------------------------------
CREATE INDEX idx_ventas_fecha_cliente
    ON ventas(fecha, cliente_id);


-- Este índice es útil para consultas por intervalo de fechas y cliente concreto.


-- -----------------------------------------------------------
-- 9. CONSULTA CON RANGO DE FECHAS (USANDO PARTICIONES + ÍNDICE)
-- -----------------------------------------------------------
/*
 Buscamos ventas de un año concreto, por ejemplo 2020,
 y para un cliente concreto.
*/

EXPLAIN
SELECT * FROM ventas
WHERE fecha BETWEEN '2020-01-01' AND '2020-12-31'
  AND cliente_id = 2;

SELECT * FROM ventas
WHERE fecha BETWEEN '2020-01-01' AND '2020-12-31'
  AND cliente_id = 2;

-- El particionamiento por año hace que MySQL se centre
-- en la partición 2020, no en toda la tabla.
-- Dentro de esa partición usa el índice (fecha, cliente_id).
-- EXPLAIN mostrará qué índice se está usando en 'key'
-- y cuántas filas estima en 'rows'.


-- -----------------------------------------------------------
-- 10. VER ESTADÍSTICAS Y ANALYZE EN ventas
-- -----------------------------------------------------------
SHOW INDEX FROM ventas;

ANALYZE TABLE ventas;

-- Explicación:
-- ANALYZE TABLE vuelve a recalcular estadísticas de la tabla 
-- y de sus índices, ayudando al optimizador a elegir siempre
-- el mejor plan de ejecución.


-- -----------------------------------------------------------
-- 11. DEMOSTRAR EFECTO DE UN ÍNDICE INADECUADO
-- -----------------------------------------------------------
/*
 Creamos una tabla con índices inadecuados para ver un mal plan.
*/

CREATE TABLE logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATETIME NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    accion VARCHAR(100) NOT NULL,
    detalle TEXT
);

-- Insertamos algunos datos de ejemplo
INSERT INTO logs (fecha, usuario, accion, detalle) VALUES
(NOW(), 'luis', 'LOGIN', 'Inicio de sesión correcto'),
(NOW(), 'ana', 'LOGOUT', 'Cierre de sesión'),
(NOW(), 'luis', 'UPDATE', 'Actualización de perfil'),
(NOW(), 'marta', 'LOGIN', 'Inicio de sesión correcto'),
(NOW(), 'ana', 'UPDATE', 'Cambio de contraseña');

-- Consulta sin índice adecuado:
EXPLAIN
SELECT * FROM logs
WHERE usuario = 'luis';

SELECT * FROM logs
WHERE usuario = 'luis';

-- type probablemente será ALL (escaneo completo).

-- Ahora creamos un índice en usuario
CREATE INDEX idx_logs_usuario ON logs(usuario);

-- Repetimos EXPLAIN y consulta:
EXPLAIN
SELECT * FROM logs
WHERE usuario = 'luis';

SELECT * FROM logs
WHERE usuario = 'luis';

-- Comprobamos cómo el optimizador cambia a usar el índice
-- y reduce las filas estimadas en 'rows'.


/*
 

 - Los ÍNDICES aceleran búsquedas (WHERE, JOIN, ORDER BY),
   pero ralentizan un poco las escrituras (INSERT/UPDATE/DELETE).

 - Las ESTADÍSTICAS (ANALYZE TABLE) informan al optimizador
   de cómo están distribuidos los datos.

 - El PARTICIONAMIENTO divide tablas muy grandes en trozos
   lógicos (por año, por país, etc.) y mejora consultas por rangos.

 - El OPTIMIZADOR de consultas es quien decide:
      * qué índice usar
      * qué orden seguir en los JOIN
      * si hacer escaneo completo o no

 - EXPLAIN es la herramienta para “ver dentro” del optimizador
   y entender qué está haciendo MySQL con nuestra consulta.
*/
