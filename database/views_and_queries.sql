USE GaseosasDelValle;

UPDATE PEDIDOS
SET total_sin_iva = fn_calcular_total_sin_iva(id_pedido),
    total_con_iva = fn_calcular_total_con_iva_dinamico(id_pedido, 0.19);

-- CREACIÓN DE VISTAS (CREATE VIEW)

-- 1. vista_resumen_pedidos_por_sede: muestra la cantidad total de pedidos y ventas por sede.
CREATE VIEW vista_resumen_pedidos_por_sede AS
SELECT 
    s.id_sede,
    s.nombre_sede,
    COUNT(p.id_pedido) AS total_pedidos,
    COALESCE(SUM(p.total_con_iva), 0) AS ventas_totales_con_iva
FROM SEDES s
LEFT JOIN PEDIDOS p ON s.id_sede = p.id_sede
GROUP BY s.id_sede, s.nombre_sede;

-- 2. vista_productos_bajo_stock: lista productos con stock_actual <= stock_minimo.
CREATE VIEW vista_productos_bajo_stock AS
SELECT 
    id_producto,
    nombre,
    categoria,
    stock_actual,
    stock_minimo
FROM PRODUCTOS
WHERE stock_actual <= stock_minimo;

-- 3. vista_clientes_activos: muestra clientes con al menos un pedido registrado.
CREATE VIEW vista_clientes_activos AS
SELECT DISTINCT
    c.id_cliente,
    c.nombre_completo,
    c.identificacion,
    c.telefono,
    c.correo_electronico
FROM CLIENTES c
JOIN PEDIDOS p ON c.id_cliente = p.id_cliente;


-- CONSULTAS SQL REQUERIDAS

-- 1. Consultar los productos con stock por debajo del mínimo.
SELECT 
    nombre, 
    categoria, 
    stock_actual, 
    stock_minimo,
    'Stock bajo mínimo' AS estado_stock
FROM PRODUCTOS
WHERE stock_actual <= stock_minimo;

-- 2. Consultar los pedidos realizados entre dos fechas (BETWEEN).
SELECT * 
FROM PEDIDOS 
WHERE fecha_pedido BETWEEN '2026-02-01 00:00:00' AND '2026-02-28 23:59:59';

-- 3. Listar los productos más vendidos (con JOIN y GROUP BY).
SELECT 
    pr.id_producto,
    pr.nombre,
    SUM(dp.cantidad) AS total_unidades_vendidas,
    SUM(dp.subtotal) AS ingresos_totales
FROM PRODUCTOS pr
JOIN DETALLE_PEDIDO dp ON pr.id_producto = dp.id_producto
GROUP BY pr.id_producto, pr.nombre
ORDER BY total_unidades_vendidas DESC;

-- 4. Mostrar clientes y la cantidad de pedidos realizados.
SELECT 
    c.id_cliente,
    c.nombre_completo,
    COUNT(p.id_pedido) AS cantidad_pedidos
FROM CLIENTES c
LEFT JOIN PEDIDOS p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre_completo;

-- 5. Buscar clientes por nombre parcial usando LIKE.
SELECT * 
FROM CLIENTES 
WHERE nombre_completo LIKE '%Supermercado%';

-- 6. Consultar productos de ciertas categorías usando IN.
SELECT * 
FROM PRODUCTOS 
WHERE categoria IN ('Gaseosas Tradicionales', 'Frutales');

-- 7. Mostrar el cliente con mayor número de pedidos (subconsulta).
SELECT c.id_cliente, c.nombre_completo, COUNT(p.id_pedido) AS total_pedidos
FROM CLIENTES c
JOIN PEDIDOS p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre_completo
HAVING COUNT(p.id_pedido) = (
    SELECT COUNT(id_pedido) AS conteo
    FROM PEDIDOS
    GROUP BY id_cliente
    ORDER BY conteo DESC
    LIMIT 1
);

-- 8. Consultar pedidos y sus totales agrupados por sede.
SELECT 
    s.nombre_sede,
    COUNT(p.id_pedido) AS numero_pedidos,
    SUM(p.total_sin_iva) AS suma_sin_iva,
    SUM(p.total_con_iva) AS suma_con_iva
FROM PEDIDOS p
JOIN SEDES s ON p.id_sede = s.id_sede
GROUP BY s.id_sede, s.nombre_sede;