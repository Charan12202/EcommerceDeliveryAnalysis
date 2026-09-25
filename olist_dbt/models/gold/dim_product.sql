select 
product_id,
category,
photos_qty,
weight_g,
length_cm,
height_cm,
width_cm,
length_cm * height_cm * width_cm as volume_cm3
from {{ ref('silver_products') }}
