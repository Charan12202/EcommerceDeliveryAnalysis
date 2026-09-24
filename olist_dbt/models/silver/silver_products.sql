select
  p.product_id,
  coalesce(t.product_category_name_english, 'unknown')  as category,
  cast(p.product_name_lenght as int)                    as name_length,
  cast(p.product_description_lenght as int)             as description_length,
  cast(p.product_photos_qty as int)                     as photos_qty,
  cast(p.product_weight_g as int)                       as weight_g,
  cast(p.product_length_cm as int)                      as length_cm,
  cast(p.product_height_cm as int)                      as height_cm,
  cast(p.product_width_cm as int)                       as width_cm
from {{ source('bronze', 'products') }} p
left join {{ source('bronze', 'product_category_name_translation') }} t
  on p.product_category_name = t.product_category_name
qualify row_number() over (partition by p.product_id order by p._ingested_at desc) = 1