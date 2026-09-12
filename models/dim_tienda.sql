{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER () AS id_tienda,
    tienda AS nombre_tienda
FROM (
    SELECT DISTINCT tienda
    FROM `pedidos-dataeng.pedidos.pedidos_raw`
)