{{ config(materialized='table') }}

SELECT
    ROW_NUMBER() OVER () AS id_fecha,
    fecha,
    EXTRACT(YEAR FROM fecha) AS anio,
    EXTRACT(MONTH FROM fecha) AS mes,
    EXTRACT(QUARTER FROM fecha) AS trimestre,
    FORMAT_DATE('%A', fecha) AS dia_semana,
    EXTRACT(DAYOFWEEK FROM fecha) IN (1, 7) AS es_fin_de_semana
FROM (
    SELECT DISTINCT fecha
    FROM `pedidos-dataeng.pedidos.pedidos_raw`
)