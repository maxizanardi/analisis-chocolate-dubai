/*
Se crea un calendario mensual completo,
se pivotean los precios históricos,
se limpian las tendencias mensuales,
se unen las tablas por fecha
y se excluyen los productos de versión clásica sin fecha.
*/
CREATE OR REPLACE TABLE `analisis-chocolate-dubai.chocolate_dubai.chocolate_dubai_tabla_final` AS
 -- Paso 1: Creamos un calendario mensual completo
WITH calendario AS (
 SELECT date
 FROM UNNEST(GENERATE_DATE_ARRAY('2023-01-01', '2026-03-01', INTERVAL 1 MONTH)) AS date
),
precios_pivot AS (
 -- Paso 2: Pivotamos la tabla de precios históricos para que se lea correctamente
 SELECT
   fecha,
   MAX(CASE WHEN ingrediente = 'Cacao' THEN precio_eur_kg END) AS costo_cacao_kg,
   MAX(CASE WHEN ingrediente = 'Pistacho' THEN precio_eur_kg END) AS costo_pistacho_kg,
   MAX(CASE WHEN ingrediente = 'Kataifi' THEN precio_eur_kg END) AS costo_kataifi_kg
 FROM `analisis-chocolate-dubai.chocolate_dubai.dataset_precios_historicos`
 GROUP BY fecha
),
trends_limpio AS (
 -- Paso 3: Agregamos los datos de la tabla de tendencias a nuestra tabla temporal
 SELECT
   date AS fecha_trends,
   trend_chocolate_dubai AS interes_dubai,
   trend_pistacho AS interes_pistacho,
   trend_kataifi AS interes_kataifi
 FROM `analisis-chocolate-dubai.chocolate_dubai.trends_chocolate_dubai_mensual`
)


-- Paso 4: Se realiza la unión mediante JOIN y se excluyen los productos de versión clásica sin fecha
SELECT
   c.date AS fecha,
   m.marca,
   m.producto,
   m.version,
   m.precio_100g AS precio_venta_100g,
   p.costo_cacao_kg,
   p.costo_pistacho_kg,
   p.costo_kataifi_kg,
   t.interes_dubai,
   t.interes_pistacho,
   t.interes_kataifi
FROM calendario AS c
LEFT JOIN precios_pivot AS p
 ON c.date = p.fecha
LEFT JOIN `analisis-chocolate-dubai.chocolate_dubai.mercado_chocolate_dubai` AS m
 ON c.date = m.fecha_deteccion_mercado
 AND NOT (m.fecha_deteccion_mercado IS NULL AND m.version = 'Clasico')
LEFT JOIN trends_limpio AS t
 ON c.date = t.fecha_trends
ORDER BY c.date ASC;
