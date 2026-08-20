USE GaseosasDelValle;

DELIMITER //

-- 1. tr_calcular_subtotal
CREATE TRIGGER tr_calcular_subtotal
BEFORE INSERT ON DETALLE_PEDIDO
FOR EACH ROW
BEGIN
    DECLARE v_precio DECIMAL(10,2);

    SELECT precio INTO v_precio
    FROM PRODUCTOS
    WHERE id_producto = NEW.id_producto;

    SET NEW.subtotal = NEW.cantidad * v_precio;
END //

-- 2. tr_actualizar_stock
CREATE TRIGGER tr_actualizar_stock
AFTER INSERT ON DETALLE_PEDIDO
FOR EACH ROW
BEGIN
    DECLARE v_stock_disponible INT;

    SELECT stock_actual INTO v_stock_disponible
    FROM PRODUCTOS
    WHERE id_producto = NEW.id_producto;

    IF v_stock_disponible IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: el producto especificado no existe.';
    ELSEIF v_stock_disponible < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: stock insuficiente para completar el pedido.';
    ELSE
        UPDATE PRODUCTOS
        SET stock_actual = stock_actual - NEW.cantidad
        WHERE id_producto = NEW.id_producto;
    END IF;
END //

-- 3. tr_actualizar_totales_pedido
CREATE TRIGGER tr_actualizar_totales_pedido
AFTER INSERT ON DETALLE_PEDIDO
FOR EACH ROW
BEGIN
    UPDATE PEDIDOS
    SET total_sin_iva = fn_calcular_total_sin_iva(NEW.id_pedido),
        total_con_iva = fn_calcular_total_con_iva_dinamico(NEW.id_pedido, 0.19)
    WHERE id_pedido = NEW.id_pedido;
END //

-- 4. tr_auditar_cambio_precio
CREATE TRIGGER tr_auditar_cambio_precio
BEFORE UPDATE ON PRODUCTOS
FOR EACH ROW
BEGIN
    IF OLD.precio <> NEW.precio THEN
        INSERT INTO AUDITORIA_PRECIOS (id_producto, precio_anterior, precio_nuevo, fecha_cambio)
        VALUES (OLD.id_producto, OLD.precio, NEW.precio, NOW());
    END IF;
END //

DELIMITER ;