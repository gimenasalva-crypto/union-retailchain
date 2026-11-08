-- ══════════════════════════════════════════
-- RetailChain — UNION y UNION ALL
-- Autora: Salva, María Gimena
-- Fecha: 08/11/2026
-- Motor: SQL Server (SSMS)
-- Requisito: ejecutar antes schema.sql
-- ══════════════════════════════════════════

USE RetailChain;
GO

-- ── CONSULTA 1: UNION ────────────────────
-- Reporte de Catálogo Unificado
-- Pregunta de negocio: ¿Qué productos únicos comercializa
-- la empresa en toda su red de sucursales?
-- Operador: UNION (elimina filas completamente duplicadas)
-- No se incluye la columna stock: el catálogo describe QUÉ productos hay,
-- no cuántos. Si se incluyera, el Monitor (5 en Norte y 3 en Sur) daría
-- dos filas distintas y UNION no podría unificarlo.
-- Resultado esperado: 11 filas (se eliminan los duplicados 103, 104 y 106)
SELECT id_producto,
       nombre_producto,
       categoria
FROM inventario_sucursal_norte
UNION
SELECT id_producto,
       nombre_producto,
       categoria
FROM inventario_sucursal_sur
ORDER BY id_producto;   -- el ORDER BY va al final de todo el UNION

-- ── CONSULTA 2: UNION ALL ────────────────
-- Auditoría de Stock Total
-- Pregunta de negocio: ¿Cuántos registros físicos de stock
-- existen en total entre ambas sucursales?
-- Operador: UNION ALL (mantiene todos los registros incluyendo duplicados)
-- Se agrega una columna fija 'sucursal' para saber de dónde viene cada registro.
-- Resultado esperado: 14 filas (7 de Norte + 7 de Sur)
SELECT 'Norte' AS sucursal,
       id_producto,
       nombre_producto,
       categoria,
       stock
FROM inventario_sucursal_norte
UNION ALL
SELECT 'Sur' AS sucursal,
       id_producto,
       nombre_producto,
       categoria,
       stock
FROM inventario_sucursal_sur
ORDER BY id_producto, sucursal;

-- ── CONSULTA 3: COMPARACIÓN DE RESULTADOS ─
-- Ejecutá estas dos consultas para comparar cuántas filas
-- devuelve cada operador y explicá la diferencia en tu README
-- (dentro de los paréntesis no va ORDER BY)
SELECT COUNT(*) AS filas_union
FROM (
    SELECT id_producto, nombre_producto, categoria FROM inventario_sucursal_norte
    UNION
    SELECT id_producto, nombre_producto, categoria FROM inventario_sucursal_sur
) AS resultado_union;           -- esperado: 11

SELECT COUNT(*) AS filas_union_all
FROM (
    SELECT 'Norte' AS sucursal, id_producto, nombre_producto, categoria, stock FROM inventario_sucursal_norte
    UNION ALL
    SELECT 'Sur'   AS sucursal, id_producto, nombre_producto, categoria, stock FROM inventario_sucursal_sur
) AS resultado_union_all;       -- esperado: 14
