
-- 02_ejercicios.sql
-- Ejercicios para el alumnado (PostgreSQL).

-- NIVEL 1: Vistas simples
-- E1.1 Crea una vista v_clientes_espana con clientes de España.
-- E1.2 Crea una vista v_productos_stock_bajo con stock < 10.
-- E1.3 Crea v_empleados_activos solo con empleados 'Activo' usando WITH CHECK OPTION.

-- NIVEL 2: Vistas complejas
-- E2.1 v_total_ventas_cliente: nombre de cliente + suma de importe.
-- E2.2 v_ventas_empleados: nombre de empleado + total vendido y número de tickets.
-- E2.3 v_ventas_seccion_mes: seccion, mes(YYYY-MM) y total vendido.

-- NIVEL 3: Vistas materializadas (PostgreSQL)
-- E3.1 mv_ventas_mensuales: mes (YYYY-MM) + total.
-- E3.2 Refresca la vista materializada.
-- E3.3 Consulta comparativa: ¿qué clientes compraron más en el último mes?

-- NIVEL 4: Seguridad
-- E4.1 Crea v_empleados_publicos (nombre, puesto, id_seccion). Concede permisos SELECT a un usuario de solo lectura.
-- E4.2 Revoca el acceso a tabla empleados para dicho usuario, manteniendo el acceso a la vista.
