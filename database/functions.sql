USE GaseosasDelValle;

DELIMITER //

-- 1. fn_calcular_total_con_iva
-- Calcula el total con IVA del pedido (19%) a partir de la suma de subtotales. (Tomamos en cuenta el hecho de que el IVA puede variar, por lo que se hace dinámico)
CREATE FUNCTION fn_calcular_total_con_iva_dinamico(p_id_pedido BIGINT, p_porcentaje_iva DECIMAL(2,2) UNSIGNED)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_total_sin_iva DECIMAL(10,2);

    IF p_porcentaje_iva < 0 OR p_porcentaje_iva > 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: el porcentaje de IVA debe estar entre 0 y 1 (ej. 0.19 para 19%).';
    END IF;

    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_total_sin_iva
    FROM DETALLE_PEDIDO
    WHERE id_pedido = p_id_pedido;
    
    RETURN v_total_sin_iva * (1 + p_porcentaje_iva);
END //

-- 2. fn_calcular_total_sin_iva
-- funcion complementaria para obtener la suma de subtotales sin IVA.
CREATE FUNCTION fn_calcular_total_sin_iva(p_id_pedido BIGINT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_total_sin_iva DECIMAL(10,2);
    
    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_total_sin_iva
    FROM DETALLE_PEDIDO
    WHERE id_pedido = p_id_pedido;
    
    RETURN v_total_sin_iva;
END //

-- 3. fn_validar_stock
-- Retorna un mensaje indicando si hay suficiente stock antes de confirmar el pedido.
CREATE FUNCTION fn_validar_stock(p_id_producto BIGINT, p_cantidad INT)
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
    DECLARE v_stock_actual INT;
    DECLARE v_mensaje VARCHAR(255);
    
    SELECT stock_actual INTO v_stock_actual
    FROM PRODUCTOS
    WHERE id_producto = p_id_producto;
    
    IF v_stock_actual IS NULL THEN
        SET v_mensaje = 'Error: El producto no existe.';
    ELSEIF v_stock_actual >= p_cantidad THEN
        SET v_mensaje = CONCAT('Stock suficiente. Disponible: ', v_stock_actual);
    ELSE
        SET v_mensaje = CONCAT('Stock insuficiente. Disponible: ', v_stock_actual, ', Requerido: ', p_cantidad);
    END IF;
    
    RETURN v_mensaje;
END //

DELIMITER ;