1. Crear una función MySQL llamada total_pedidos_cliente_periodo que:
Reciba como parámetros el ID del cliente, la fecha de inicio y la fecha final.
Retorne el valor total de los pedidos realizados por ese cliente dentro del rango de fechas.
Si el cliente no tiene pedidos en ese período, debe retornar 0.

```SQL

DELIMITER //

CREATE FUNCTION total_pedidos_cliente_periodo(p_id_cliente INT, p_fecha_inicio DATE, p_fecha_fin DATE) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT COALESCE(SUM(total), 0)
    INTO v_total
    FROM pedidos
    WHERE id_cliente = p_id_cliente
      AND fecha BETWEEN p_fecha_inicio AND p_fecha_fin;

    RETURN v_total;
END //

DELIMITER ;

```


2. Crear una vista llamada vista_clientes_activos que:
Muestre los clientes que han realizado al menos un pedido en los últimos 90 días.
Incluya el nombre del cliente, número total de pedidos y valor total comprado.
Debe usar JOIN entre clientes y pedidos, y aplicar funciones de agregación.

```SQL

CREATE VIEW vista_clientes_activos AS
SELECT DISTINCT
    c.id_cliente,
    c.nombre_completo,
    c.identificacion,
    c.telefono,
    c.correo_electronico
FROM CLIENTES c
JOIN PEDIDOS p ON c.id_cliente = p.id_cliente;

```

3. Realizar una consulta analítica que:
Liste los cinco clientes con mayor valor total en pedidos durante el año actual.
Debe mostrar: nombre del cliente, cantidad de pedidos y total comprado.
Usa ORDER BY y LIMIT 5 para presentar los resultados en orden descendente.

```SQL

SELECT 
    c.nombre_completo AS nombre_cliente,
    COUNT(p.id_pedido) AS cantidad_pedidos,
    SUM(p.total_con_iva) AS total_comprado
FROM CLIENTES c
JOIN PEDIDOS p ON c.id_cliente = p.id_cliente
WHERE YEAR(p.fecha_pedido) = 2026
GROUP BY c.id_cliente, c.nombre_completo
ORDER BY total_comprado DESC
LIMIT 5;


```

4. Crear un trigger llamado registrar_nuevo_pedido_trigger que:
Se ejecute después de insertar un nuevo pedido.
Registre en una tabla auditoria_pedidos los campos:
id_pedido, id_cliente, fecha_registro, total_pedido y usuario_responsable (puede ser un valor fijo o por defecto).
Debe garantizar que cada pedido nuevo quede auditado correctamente.

```SQL

-- Estructura de la tabla de auditoria:

CREATE TABLE IF NOT EXISTS auditoria_pedidos (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT,
    id_cliente INT,
    fecha_registro DATETIME,
    total_pedido DECIMAL(10,2),
    usuario_responsable VARCHAR(100)
);


-- Creacion del Trigger:

DELIMITER //

CREATE TRIGGER registrar_nuevo_pedido_trigger
AFTER INSERT ON PEDIDOS
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_pedidos (id_pedido, id_cliente, fecha_registro, total_pedido, usuario_responsable) 
    VALUES (NEW.id_pedido, NEW.id_cliente, NOW(), NEW.total_con_iva, NEW.id_cliente);
END //

DELIMITER ;
