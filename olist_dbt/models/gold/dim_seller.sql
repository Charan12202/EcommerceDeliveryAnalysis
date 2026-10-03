SELECT
    s.seller_id,
    s.zip_prefix,
    s.city,
    s.state,
    g.lat,
    g.lng
FROM {{ ref('silver_sellers') }} AS s
LEFT JOIN {{ ref('silver_geolocation') }} AS g
    ON s.zip_prefix = g.zip_prefix
