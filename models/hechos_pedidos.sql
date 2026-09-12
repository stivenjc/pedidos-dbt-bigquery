{{ config(materialized='table') }}

SELECT
    pr.id_pedido,
    dp.id_producto,
    dt.id_tienda,
    df.id_fecha,
    pr.cantidad,
    pr.precio_unitario
FROM `pedidos-dataeng.pedidos.pedidos_raw` AS pr
JOIN {{ ref('dim_producto') }} AS dp
    ON pr.producto = dp.nombre_producto
JOIN {{ ref('dim_tienda') }} AS dt
    ON pr.tienda = dt.nombre_tienda
JOIN {{ ref('dim_fecha') }} AS df
    ON pr.fecha = df.fecha