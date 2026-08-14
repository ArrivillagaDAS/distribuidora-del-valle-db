# Informe Técnico

## Proyecto: Sistema de Base de Datos - Distribuidora de Gaseosas del Valle S.A.

---

## 1. Introducción

El presente informe describe el diseño, la implementación y el funcionamiento de la base de datos desarrollada para la empresa Distribuidora de Gaseosas del Valle S.A. El sistema fue construido en MySQL y tiene como propósito gestionar la información relacionada con sedes, clientes, productos, pedidos y el control de inventario y precios de la distribuidora.

El proyecto se organiza en cuatro scripts principales, correspondientes a las distintas capas de la base de datos:

- `schema.sql`: definición de tablas, relaciones y datos de prueba.
- `functions.sql`: funciones almacenadas para cálculos reutilizables.
- `triggers.sql`: disparadores para automatizar reglas de negocio.
- `views_and_queries.sql`: vistas y consultas requeridas para la explotación de la información.

---

## 2. Objetivo

Diseñar e implementar una base de datos relacional que permita registrar sedes, clientes y productos, gestionar pedidos y su detalle, controlar el stock disponible, mantener actualizados los totales de cada pedido (con y sin IVA) y llevar un historial de auditoría sobre los cambios de precio de los productos, todo mediante funciones y disparadores que garanticen la consistencia de los datos sin depender de la lógica de la aplicación cliente.

---

## 3. Modelo de Datos

### 3.1 Descripción general

El modelo está compuesto por seis tablas relacionadas entre sí mediante llaves foráneas. La tabla `PEDIDOS` centraliza la relación entre `CLIENTES` y `SEDES`, mientras que `DETALLE_PEDIDO` vincula cada pedido con los productos solicitados. La tabla `AUDITORIA_PRECIOS` almacena el historial de modificaciones de precio de cada producto.

### 3.2 Tablas

**SEDES**

| Campo | Tipo | Descripción |
|---|---|---|
| id_sede | BIGINT, PK, AUTO_INCREMENT | Identificador de la sede |
| nombre_sede | VARCHAR(100), NOT NULL | Nombre de la sede |
| ubicacion | TEXT | Dirección física de la sede |
| capacidad_almacenamiento | BIGINT | Capacidad de almacenamiento en unidades |
| encargado | VARCHAR(100) | Nombre del responsable de la sede |

**CLIENTES**

| Campo | Tipo | Descripción |
|---|---|---|
| id_cliente | BIGINT, PK, AUTO_INCREMENT | Identificador del cliente |
| nombre_completo | VARCHAR(100), NOT NULL | Nombre o razón social del cliente |
| identificacion | VARCHAR(13), UNIQUE, NOT NULL | NIT o cédula del cliente |
| direccion | TEXT | Dirección del cliente |
| telefono | VARCHAR(8) | Teléfono de contacto |
| correo_electronico | VARCHAR(100) | Correo de contacto |

**PRODUCTOS**

| Campo | Tipo | Descripción |
|---|---|---|
| id_producto | BIGINT, PK, AUTO_INCREMENT | Identificador del producto |
| nombre | VARCHAR(100), NOT NULL | Nombre del producto |
| categoria | VARCHAR(100) | Categoría del producto |
| precio | DECIMAL(10,2), NOT NULL | Precio unitario vigente |
| volumen_ml | INT | Volumen del producto en mililitros |
| stock_actual | INT, NOT NULL | Cantidad disponible en inventario |
| stock_minimo | INT, NOT NULL | Umbral mínimo de stock permitido |

**AUDITORIA_PRECIOS**

| Campo | Tipo | Descripción |
|---|---|---|
| id_auditoria | BIGINT, PK, AUTO_INCREMENT | Identificador del registro de auditoría |
| id_producto | BIGINT, FK -> PRODUCTOS | Producto afectado por el cambio |
| precio_anterior | DECIMAL(10,2) | Precio antes del cambio |
| precio_nuevo | DECIMAL(10,2) | Precio después del cambio |
| fecha_cambio | TIMESTAMP, DEFAULT CURRENT_TIMESTAMP | Fecha y hora del cambio |

**PEDIDOS**

| Campo | Tipo | Descripción |
|---|---|---|
| id_pedido | BIGINT, PK, AUTO_INCREMENT | Identificador del pedido |
| fecha_pedido | DATETIME, DEFAULT CURRENT_TIMESTAMP | Fecha de registro del pedido |
| id_cliente | BIGINT, FK -> CLIENTES, NOT NULL | Cliente que realiza el pedido |
| id_sede | BIGINT, FK -> SEDES, NOT NULL | Sede que atiende el pedido |
| total_sin_iva | DECIMAL(10,2), DEFAULT 0 | Total del pedido sin IVA |
| total_con_iva | DECIMAL(10,2), DEFAULT 0 | Total del pedido con IVA |

**DETALLE_PEDIDO**

| Campo | Tipo | Descripción |
|---|---|---|
| id_detalle_pedido | BIGINT, PK, AUTO_INCREMENT | Identificador del detalle |
| id_pedido | BIGINT, FK -> PEDIDOS, NOT NULL | Pedido al que pertenece el detalle |
| id_producto | BIGINT, FK -> PRODUCTOS, NOT NULL | Producto solicitado |
| cantidad | INT, NOT NULL | Cantidad solicitada |
| subtotal | DECIMAL(10,2) | Subtotal calculado (cantidad x precio) |

### 3.3 Relaciones

- Un cliente puede realizar varios pedidos (1:N entre CLIENTES y PEDIDOS).
- Una sede puede atender varios pedidos (1:N entre SEDES y PEDIDOS).
- Un pedido puede contener varios productos, y un producto puede aparecer en varios pedidos, relación resuelta mediante la tabla intermedia DETALLE_PEDIDO (N:M entre PEDIDOS y PRODUCTOS).
- Un producto puede tener varios registros de auditoría de precio (1:N entre PRODUCTOS y AUDITORIA_PRECIOS).

---

## 4. Funciones Almacenadas

Las funciones se implementaron como `FUNCTION` de MySQL con la cláusula `READS SQL DATA`, ya que únicamente consultan información sin modificarla.

### 4.1 fn_calcular_total_sin_iva

Recibe el identificador de un pedido y retorna la suma de los subtotales registrados en `DETALLE_PEDIDO` para ese pedido. Si el pedido no tiene detalles, retorna 0 mediante `COALESCE`.

### 4.2 fn_calcular_total_con_iva

Reutiliza internamente la misma lógica de suma de subtotales y aplica un incremento del 19% correspondiente al IVA, retornando el total final del pedido.

### 4.3 fn_validar_stock

Recibe el identificador de un producto y una cantidad solicitada. Retorna un mensaje de texto indicando si el producto existe, si el stock es suficiente o si es insuficiente, incluyendo en el mensaje la cantidad disponible y la cantidad requerida. Esta función está pensada como validación previa a la confirmación de un pedido desde la aplicación cliente.

---

## 5. Disparadores (Triggers)

Los cuatro disparadores se ejecutan sobre las tablas `DETALLE_PEDIDO` y `PRODUCTOS`, y en conjunto garantizan que el sistema mantenga su consistencia sin intervención manual.

### 5.1 tr_calcular_subtotal (BEFORE INSERT en DETALLE_PEDIDO)

Antes de insertar un nuevo detalle de pedido, consulta el precio vigente del producto en la tabla `PRODUCTOS` y calcula el subtotal como `cantidad x precio`, asignándolo automáticamente al registro que se está insertando. De esta manera el subtotal nunca depende de un valor enviado por la aplicación.

### 5.2 tr_actualizar_stock (AFTER INSERT en DETALLE_PEDIDO)

Después de insertar un detalle de pedido, valida que el producto exista y que haya stock suficiente para la cantidad solicitada. Si el producto no existe o el stock es insuficiente, la operación se cancela mediante `SIGNAL SQLSTATE '45000'` con un mensaje descriptivo. Si la validación es exitosa, descuenta la cantidad vendida del `stock_actual` del producto.

### 5.3 tr_actualizar_totales_pedido (AFTER INSERT en DETALLE_PEDIDO)

Después de insertar un detalle de pedido, recalcula y actualiza los campos `total_sin_iva` y `total_con_iva` del pedido correspondiente, invocando las funciones `fn_calcular_total_sin_iva` y `fn_calcular_total_con_iva`. Esto asegura que el pedido siempre refleje el total actualizado a medida que se agregan productos.

### 5.4 tr_auditar_cambio_precio (BEFORE UPDATE en PRODUCTOS)

Antes de actualizar un producto, compara el precio anterior con el nuevo. Si el precio cambió, inserta un registro en `AUDITORIA_PRECIOS` con el producto afectado, el precio anterior, el precio nuevo y la fecha del cambio, dejando trazabilidad histórica de todas las modificaciones de precio.

### 5.5 Orden de ejecución

Para un mismo evento (`INSERT` en `DETALLE_PEDIDO`), el orden lógico de ejecución es el siguiente:

1. `tr_calcular_subtotal` (BEFORE INSERT) calcula el subtotal antes de insertar la fila.
2. `tr_actualizar_stock` (AFTER INSERT) valida y descuenta el stock una vez insertada la fila.
3. `tr_actualizar_totales_pedido` (AFTER INSERT) recalcula los totales del pedido con el subtotal ya insertado.

---

## 6. Vistas

### 6.1 vista_resumen_pedidos_por_sede

Presenta, por cada sede, el número total de pedidos y la suma de ventas con IVA. Utiliza `LEFT JOIN` para incluir también las sedes que aún no tienen pedidos registrados, mostrando 0 en dichos casos mediante `COALESCE`.

### 6.2 vista_productos_bajo_stock

Filtra los productos cuyo `stock_actual` es menor o igual al `stock_minimo` configurado, permitiendo identificar de forma rápida los productos que requieren reabastecimiento.

### 6.3 vista_clientes_activos

Lista, sin duplicados, los clientes que tienen al menos un pedido registrado, mediante un `INNER JOIN` entre `CLIENTES` y `PEDIDOS`.

---

## 7. Consultas SQL Requeridas

El archivo `views_and_queries.sql` incluye ocho consultas que cubren distintos requisitos de explotación de la información:

1. Productos con stock por debajo del mínimo.
2. Pedidos realizados en un rango de fechas específico, usando `BETWEEN`.
3. Productos más vendidos, combinando `PRODUCTOS` y `DETALLE_PEDIDO` con `JOIN` y `GROUP BY`.
4. Cantidad de pedidos por cliente, incluyendo clientes sin pedidos mediante `LEFT JOIN`.
5. Búsqueda de clientes por coincidencia parcial de nombre usando `LIKE`.
6. Productos filtrados por categoría usando `IN`.
7. Cliente con mayor número de pedidos, resuelto con una subconsulta anidada que calcula el máximo de pedidos por cliente.
8. Totales de pedidos agrupados por sede, mostrando la suma de totales con y sin IVA.

---

## 8. Decisiones Técnicas Relevantes

- **Tipo de dato para montos**: se utilizó `DECIMAL(10,2)` en todos los campos monetarios para evitar los errores de precisión propios de tipos de punto flotante.
- **Cálculo de IVA**: se fijó una tarifa del 19%, aplicada de forma centralizada dentro de `fn_calcular_total_con_iva`, evitando que el porcentaje se repita en distintos puntos del sistema.
- **Validación de stock mediante SIGNAL**: se optó por cancelar la operación con un error controlado (`SIGNAL SQLSTATE '45000'`) en lugar de permitir inserciones inconsistentes, trasladando la regla de negocio a la base de datos.
- **Auditoría condicional de precios**: el trigger `tr_auditar_cambio_precio` solo genera un registro cuando el precio efectivamente cambia, evitando registros innecesarios ante actualizaciones que no modifican el precio.
- **Reutilización de funciones en triggers**: los triggers de actualización de totales reutilizan las funciones de cálculo en lugar de duplicar la lógica, centralizando el cálculo del IVA y de los subtotales en un único lugar.
- **Datos de prueba**: el script `schema.sql` incluye la inserción de 5 sedes, 50 clientes, 50 productos, 50 registros de auditoría, 50 pedidos y 63 detalles de pedido, permitiendo probar el comportamiento de funciones, triggers y vistas con un volumen de datos representativo.

---

## 9. Conclusiones

El diseño implementado traslada a la base de datos las reglas de negocio críticas de la distribuidora: cálculo de subtotales, control de inventario, actualización de totales con IVA y auditoría de cambios de precio. Esto reduce la dependencia de la aplicación cliente para mantener la integridad de los datos y garantiza que dichas reglas se cumplan sin importar el origen de la operación (aplicación, script o consola). Las vistas y consultas desarrolladas cubren las necesidades operativas de consulta de inventario, seguimiento de clientes y análisis de ventas por sede.