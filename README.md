# Distribuidora de Gaseosas del Valle S.A. - Base de Datos

Base de datos relacional en MySQL para la gestión de sedes, clientes, productos, pedidos e inventario de la Distribuidora de Gaseosas del Valle S.A. El sistema automatiza, mediante funciones y disparadores, el cálculo de subtotales, el control de stock, la actualización de totales con IVA y la auditoría de cambios de precio.

## Estructura del proyecto

```
distribuidora-del-valle-db/
├── assets/
│   ├── functions/         Capturas de pantalla de la ejecución de functions.sql
│   ├── schema/             Capturas de pantalla de la ejecución de schema.sql
│   ├── triggers/           Capturas de pantalla de la ejecución de triggers.sql
│   ├── views_and_queries/  Capturas de pantalla de la ejecución de views_and_queries.sql
│   └── modelo_er.png       Modelo entidad-relación de la base de datos
├── database/
│   ├── schema.sql              Definición de tablas, relaciones y datos de prueba
│   ├── functions.sql           Funciones almacenadas
│   ├── triggers.sql            Disparadores
│   └── views_and_queries.sql   Vistas y consultas requeridas
├── docs/
│   └── informe_tecnico.md  Informe técnico detallado del diseño e implementación
├── tests/
│   └── smoke_tests.md      Pruebas básicas de verificación de funcionamiento
└── README.md
```

## Requisitos

- MySQL 8.0 o superior (o MariaDB compatible).
- Un cliente de administración de bases de datos (MySQL Workbench, DBeaver, línea de comandos, o la extensión de MySQL/SQLTools de VS Code).

## Orden de ejecución de los scripts

Los scripts deben ejecutarse en el siguiente orden, ya que cada uno depende del anterior:

1. `database/schema.sql`: crea la base de datos `GaseosasDelValle`, las tablas y carga los datos de prueba.
2. `database/functions.sql`: crea las funciones `fn_calcular_total_sin_iva`, `fn_calcular_total_con_iva` y `fn_validar_stock`.
3. `database/triggers.sql`: crea los disparadores que dependen de las funciones creadas en el paso anterior.
4. `database/views_and_queries.sql`: actualiza los totales de los pedidos existentes, crea las vistas y contiene las consultas de explotación de datos.

## Modelo de datos

La base de datos está compuesta por seis tablas:

| Tabla | Descripción |
|---|---|
| SEDES | Sedes físicas de la distribuidora |
| CLIENTES | Clientes que realizan pedidos |
| PRODUCTOS | Catálogo de productos, precio y stock |
| AUDITORIA_PRECIOS | Historial de cambios de precio por producto |
| PEDIDOS | Pedidos realizados por los clientes |
| DETALLE_PEDIDO | Productos y cantidades incluidos en cada pedido |

El diagrama entidad-relación completo se encuentra en `assets/modelo_er.png`.

## Funcionalidades principales

- **Cálculo automático de subtotales**: cada detalle de pedido calcula su subtotal según el precio vigente del producto al momento de la inserción.
- **Control de inventario**: el stock se descuenta automáticamente al registrar un detalle de pedido, y la operación se rechaza si no hay stock suficiente o el producto no existe.
- **Totales de pedido con y sin IVA**: los totales se recalculan automáticamente (IVA del 19%) cada vez que se agrega un producto a un pedido.
- **Auditoría de precios**: todo cambio en el precio de un producto queda registrado con fecha, precio anterior y precio nuevo.
- **Vistas de consulta**: resumen de pedidos y ventas por sede, productos con stock bajo el mínimo, y clientes activos.
- **Consultas de explotación**: búsquedas por fecha, por categoría, por nombre, productos más vendidos, cliente con más pedidos, y totales por sede.

## Documentación

- El detalle técnico completo del diseño, las tablas, funciones, triggers, vistas y decisiones de implementación se encuentra en [`docs/informe_tecnico.md`](docs/informe_tecnico.md).
- Las pruebas de verificación del sistema se encuentran en [`tests/smoke_tests.md`](tests/smoke_tests.md).

## Autor

Angela Sofia de la Cruz Arrivillaga - Proyecto académico de base de datos.
@ArrivillagaDAS - github