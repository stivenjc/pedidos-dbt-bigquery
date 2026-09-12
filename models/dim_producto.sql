{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER () AS id_producto,
    producto AS nombre_producto
FROM (
    SELECT DISTINCT producto
    FROM `pedidos-dataeng.pedidos.pedidos_raw`
)