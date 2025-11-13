/* 
  SESIÓN 6 – Auditoría de cambios de salario en MySQL
  Versión simple: EMPLEADOS + AUDITORIA_SALARIOS + TRIGGER
*/

/* 
  1) Crear la base de datos (si no existe) 
     y seleccionar su uso
*/
CREATE DATABASE IF NOT EXISTS bd_rrhh_auditoria;

USE bd_rrhh_auditoria;


/* 
  2) Crear la tabla EMPLEADOS 
     
*/


CREATE TABLE empleados (
  id INT PRIMARY KEY,          -- identificador único del empleado
  nombre VARCHAR(100) NOT NULL,-- nombre del empleado
  salario DECIMAL(10,2) NOT NULL -- salario actual del empleado
);


/* 
  3) Crear la tabla AUDITORIA_SALARIOS 
*/


CREATE TABLE auditoria_salarios (
  id INT AUTO_INCREMENT PRIMARY KEY,         -- identificador de la fila de auditoría
  empleado_id INT NOT NULL,                  -- id del empleado al que se le cambia el salario
  salario_antiguo DECIMAL(10,2) NOT NULL,    -- salario antes del cambio
  salario_nuevo DECIMAL(10,2) NOT NULL,      -- salario después del cambio
  fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP -- fecha y hora del cambio
);


/* 
  4) Crear el trigger de auditoría
*/
DELIMITER $$

/*
  Trigger: trg_auditoria_salario
  - Se ejecuta DESPUÉS de un UPDATE sobre la tabla EMPLEADOS.
  - Para CADA FILA modificada (FOR EACH ROW).
  - Si el salario cambia, inserta un registro en AUDITORIA_SALARIOS.
*/
CREATE TRIGGER trg_auditoria_salario
AFTER UPDATE ON empleados
FOR EACH ROW
BEGIN
    /* Solo registramos si el salario ha cambiado realmente */
    IF OLD.salario <> NEW.salario THEN
        INSERT INTO auditoria_salarios (
            empleado_id,
            salario_antiguo,
            salario_nuevo
        ) VALUES (
            OLD.id,        /* id del empleado antes del cambio */
            OLD.salario,   /* salario antiguo */
            NEW.salario    /* salario nuevo */
        );
    END IF;
END$$

/* Restauramos el delimitador estándar ';' */
DELIMITER ;


/* 
  5) Insertar datos de prueba en EMPLEADOS 
*/
INSERT INTO empleados (id, nombre, salario) VALUES
(1, 'Ana',   1500.00),
(2, 'Luis',  1800.00);


/* 
  6) Probar el trigger:
     Cambiamos el salario de Luis (id = 2)
*/
UPDATE empleados
SET salario = 1900.00
WHERE id = 2;


/* 
  7) Ver el contenido de la tabla de auditoría
     Debería aparecer un registro con el cambio de salario de Luis.
*/
SELECT * FROM auditoria_salarios;



/*
  Insertamos varios empleados de ejemplo:

    3 - Marta
    4 - Sergio
    5 - Beatriz
*/
INSERT INTO empleados (id, nombre, salario) VALUES
(3, 'Marta',   2000.00),
(4, 'Sergio',  2200.00),
(5, 'Beatriz', 2500.00);

/* Vemos el estado inicial de la tabla EMPLEADOS. */
SELECT * FROM empleados;

/*
  Realizamos varios cambios de salario para generar registros de auditoría:

    - Luis: pasa de 1800 -> 1900 -> 1950
    - Marta: pasa de 2000 -> 1950
    - Beatriz: pasa de 2500 -> 2600 -> 2700
*/
UPDATE empleados
SET salario = 1900.00
WHERE id = 2;

UPDATE empleados
SET salario = 1950.00
WHERE id = 2;

UPDATE empleados
SET salario = 1950.00
WHERE id = 3;

UPDATE empleados
SET salario = 2600.00
WHERE id = 5;

UPDATE empleados
SET salario = 2700.00
WHERE id = 5;

/* Volvemos a consultar EMPLEADOS para ver los salarios finales. */
SELECT * FROM empleados;

/*
  Consultamos AUDITORIA_SALARIOS para ver todos los cambios,
  incluyendo el usuario que los ha realizado.
*/
SELECT * FROM auditoria_salarios;


/* 5) TABLA DEPARTAMENTOS Y AUDITORÍA DE NOMBRE --------------------------- */


/*
  Creamos la tabla DEPARTAMENTOS:

    - id: identificador único del departamento (clave primaria).
    - nombre: nombre actual del departamento.
    - ubicacion: ubicación física del departamento.
*/
CREATE TABLE departamentos (
  id INT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  ubicacion VARCHAR(100) NOT NULL
);

/*
  Creamos la tabla AUDITORIA_DEPARTAMENTOS:

    - id: clave primaria de la auditoría.
    - departamento_id: referencia al departamento afectado.
    - nombre_antiguo: nombre anterior del departamento.
    - nombre_nuevo: nuevo nombre del departamento.
    - fecha_cambio: fecha y hora del cambio.
    - usuario: usuario que realiza el cambio.

  Añadimos una clave foránea hacia departamentos(id).
*/
CREATE TABLE auditoria_departamentos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  departamento_id INT NOT NULL,
  nombre_antiguo VARCHAR(100) NOT NULL,
  nombre_nuevo  VARCHAR(100) NOT NULL,
  fecha_cambio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario VARCHAR(100) NOT NULL,
  CONSTRAINT fk_auditoria_departamento
    FOREIGN KEY (departamento_id)
    REFERENCES departamentos(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


/* 6) TRIGGER DE AUDITORÍA PARA CAMBIOS DE NOMBRE DE DEPARTAMENTOS --------------------- */

/* Eliminamos el trigger anterior si existía. */


/* Cambiamos de nuevo el delimitador para definir el trigger. */


/*
  Trigger: trg_auditoria_nombre_departamento

  - AFTER UPDATE ON departamentos:
      se ejecuta después de actualizar la tabla DEPARTAMENTOS.
  - FOR EACH ROW:
      una vez por cada fila modificada.

  Lógica:
    - Solo actúa si OLD.nombre <> NEW.nombre (si cambia el nombre).
    - Inserta en AUDITORIA_DEPARTAMENTOS:
        · id del departamento,
        · nombre antiguo,
        · nombre nuevo,
        · usuario que hace el cambio.
*/


DROP TRIGGER IF EXISTS trg_auditoria_nombre_departamento;

DELIMITER $$

CREATE TRIGGER trg_auditoria_nombre_departamento
AFTER UPDATE ON departamentos
FOR EACH ROW
BEGIN
    IF OLD.nombre <> NEW.nombre THEN
        INSERT INTO auditoria_departamentos (
            departamento_id,
            nombre_antiguo,
            nombre_nuevo,
            usuario
        ) VALUES (
            OLD.id,
            OLD.nombre,
            NEW.nombre,
            CURRENT_USER()
        );
    END IF;
END$$

DELIMITER ;



/* 7) DATOS DE PRUEBA PARA DEPARTAMENTOS---------------------------------- */

/*
  Insertamos algunos departamentos de ejemplo.
*/
INSERT INTO departamentos (id, nombre, ubicacion) VALUES
(10, 'Recursos Humanos', 'Madrid'),
(20, 'Desarrollo',       'Sevilla'),
(30, 'Soporte',          'Valencia');

/* Comprobamos la tabla DEPARTAMENTOS. */
SELECT * FROM departamentos;

/*
  Cambiamos el nombre de algunos departamentos:

    - Desarrollo -> Desarrollo de Software
    - Soporte -> Atención al Cliente
*/
UPDATE departamentos
SET nombre = 'Desarrollo de Software'
WHERE id = 20;

UPDATE departamentos
SET nombre = 'Atención al Cliente'
WHERE id = 30;

/* Vemos los nombres actuales. */
SELECT * FROM departamentos;

/* Vemos el historial de cambios de nombres de departamentos. */
SELECT * FROM auditoria_departamentos;
