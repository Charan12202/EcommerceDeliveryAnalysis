SELECT
s.seller_id,
s.zip_prefix,
s.city,
s.state,
g.lat,
g.lng
from {{ ref('silver_sellers') }} s 
left join {{ ref('silver_geolocation') }} g
    on s.zip_prefix = g.zip_prefix