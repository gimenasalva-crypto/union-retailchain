# union-retailchain

**Autora:** Salva, María Gimena

**Motor:** SQL Server Express 17, ejecutado en SQL Server Management Studio 22

Práctica de `UNION` y `UNION ALL` para consolidar el inventario de las dos sucursales de RetailChain (Norte y Sur) en dos reportes: un catálogo unificado para el área comercial y una auditoría de stock para operaciones.

## Contenido

| Archivo | Qué contiene |
|---|---|
| `schema.sql` | Crea la base `RetailChain` y las tablas `inventario_sucursal_norte` (7 filas) e `inventario_sucursal_sur` (7 filas) con sus datos. |
| `soluciones.sql` | Consulta 1 (`UNION`), Consulta 2 (`UNION ALL`) y Consulta 3 (comparación con `COUNT(*)`). |
| `README.md` | Esta documentación. |

## Cómo ejecutarlo

1. Abrir `schema.sql` en SSMS y ejecutarlo (F5).
2. Abrir `soluciones.sql` y ejecutarlo (F5).

## Preguntas

### 1. ¿Cuántas filas devuelve cada consulta y por qué son distintas?

| Consulta | Operador | Filas |
|---|---|---|
| 1 · Catálogo unificado | `UNION` | **11** |
| 2 · Auditoría de stock | `UNION ALL` | **14** |

Cada sucursal tiene 7 registros, así que juntas suman 14. `UNION ALL` devuelve los 14 tal cual. `UNION`, en cambio, elimina las filas que son **completamente idénticas** y por eso devuelve 3 menos.

En la Consulta 1 seleccioné `id_producto`, `nombre_producto` y `categoria`. Con esas columnas, tres productos tienen exactamente la misma fila en las dos sucursales, y `UNION` deja una sola:

| id_producto | nombre_producto | categoria | Norte | Sur |
|---|---|---|---|---|
| 103 | Monitor 4K 27" | Computación | ✔ | ✔ |
| 104 | Teclado Mecánico | Accesorios | ✔ | ✔ |
| 106 | SSD Externo 1TB | Almacenamiento | ✔ | ✔ |

14 − 3 = **11 productos únicos**.

Dos casos que `UNION` **no** eliminó:

- **La Webcam HD 1080p** aparece dos veces (107 en Norte y 111 en Sur). Tiene el mismo nombre, pero distinto `id_producto`, así que las filas no son idénticas. Para el análisis esto es una alerta de calidad de datos: probablemente es el mismo producto cargado con dos códigos distintos, y habría que unificar el código entre sucursales.
- **Por qué no incluí `stock` en el catálogo:** el Monitor tiene 5 unidades en Norte y 3 en Sur. Si el `SELECT` incluyera `stock`, las filas `(103, Monitor, Computación, 5)` y `(103, Monitor, Computación, 3)` serían distintas y `UNION` no eliminaría nada: devolvería 14 filas, igual que `UNION ALL`. El catálogo describe **qué** productos se venden, no cuántos hay, así que el stock no corresponde en ese reporte.

En la Consulta 2 sí se necesitan todas las filas: operaciones tiene que ver el Monitor dos veces (5 unidades en Norte y 3 en Sur), porque son dos existencias físicas en dos lugares distintos. Por eso agregué la columna fija `sucursal`, para saber de dónde viene cada registro. Entre las dos sucursales hay 200 unidades en stock (100 en cada una); con `UNION` se perderían registros y el stock total quedaría subestimado.

### 2. ¿Por qué UNION ALL es más eficiente que UNION?

`UNION ALL` solo **pega** el resultado de la segunda consulta debajo del de la primera, sin revisar nada.

`UNION` hace un paso adicional: para eliminar duplicados, tiene que **comparar todas las filas entre sí**. Internamente el motor ordena el resultado completo (o arma una tabla de búsqueda en memoria) y después descarta las filas repetidas, de forma parecida a un `DISTINCT`. Ese ordenamiento consume CPU y memoria, y crece mucho con el tamaño de los datos: con 14 filas no se nota, pero con millones de registros de varias sucursales la diferencia de tiempo es grande.

Por eso, si sé que no hay duplicados o si necesito conservarlos, uso `UNION ALL`.

### 3. ¿En qué casos de negocio usaría cada uno?

**`UNION`, cuando necesito una lista de valores únicos:**

- **Lista de clientes para una campaña de email:** combinar los clientes de la tienda online y los de la tienda física para enviar una promoción. Un cliente que compra en los dos canales tiene que recibir **un solo** mail, no dos.
- **Proveedores activos de la empresa:** unir los proveedores de compras nacionales con los de importación para armar un listado único, sin repetir los que trabajan en ambas áreas.

**`UNION ALL`, cuando necesito todos los registros para contar o sumar:**

- **Ventas mensuales de varias sucursales:** juntar las ventas de enero de cada local para calcular la facturación total. Si dos locales vendieron el mismo producto, por el mismo monto, el mismo día, son dos ventas reales: `UNION` eliminaría una y la facturación daría menos.
- **Historial de movimientos de stock:** combinar la tabla de ingresos de mercadería de 2024 con la de 2025 para analizar la evolución. Cada movimiento es un hecho distinto, aunque se repitan producto y cantidad.

### 4. ¿Qué pasa si las columnas no coinciden en número o tipo?

**Si no coinciden en número**, SQL no puede armar el resultado y la consulta falla. Por ejemplo, si la primera parte selecciona 4 columnas y la segunda 3:

```sql
SELECT id_producto, nombre_producto, categoria, stock FROM inventario_sucursal_norte
UNION
SELECT id_producto, nombre_producto, categoria FROM inventario_sucursal_sur;
```

SQL Server devuelve el error:

> Msg 205: All queries combined using a UNION, INTERSECT or EXCEPT operator must have an equal number of expressions in their target lists.

En español: *"Todas las consultas combinadas con UNION deben tener la misma cantidad de expresiones en su lista de columnas"*.

**Si no coinciden en tipo**, SQL intenta convertir los datos al tipo de la columna con mayor prioridad. Por ejemplo, si en la misma posición pongo `id_producto` (INT) en una parte y `nombre_producto` (VARCHAR) en la otra, SQL intenta convertir el texto `'Monitor 4K 27"'` en número y falla con:

> Msg 245: Conversion failed when converting the varchar value 'Monitor 4K 27"' to data type int.

Además, aunque los tipos sean compatibles, el **orden** importa. `UNION` combina las columnas por posición, no por nombre: si en una parte pongo `nombre_producto, categoria` y en la otra `categoria, nombre_producto`, la consulta puede ejecutarse sin error, pero mezcla categorías con nombres de productos. Por eso, en las dos consultas de `soluciones.sql`, ambas partes seleccionan las mismas columnas en el mismo orden.
