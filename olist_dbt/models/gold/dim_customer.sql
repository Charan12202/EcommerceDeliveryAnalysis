select
  c.customer_id,
  c.customer_unique_id,
  c.zip_prefix,
  c.city,
  c.state,
  g.lat,
  g.lng
from {{ ref('silver_customers') }} c
left join {{ ref('silver_geolocation') }} g
  on c.zip_prefix = g.zip_prefix