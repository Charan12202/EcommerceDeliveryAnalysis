select
  concat_ws('-', oi.order_id, cast(oi.order_item_id as string))  as order_item_key,
  oi.order_id,
  oi.order_item_id,
  oi.product_id,
  oi.seller_id,
  o.customer_id,
  cast(date_format(o.purchased_at, 'yyyyMMdd') as int)           as purchase_date_key,
  oi.price,
  oi.freight_value,
  round(
    2 * 6371 * asin(sqrt(
      pow(sin(radians(s.lat - c.lat) / 2), 2) +
      cos(radians(c.lat)) * cos(radians(s.lat)) *
      pow(sin(radians(s.lng - c.lng) / 2), 2)
    )), 1)                                                        as distance_km,
  o.is_late
from {{ ref('silver_order_items') }} oi
join {{ ref('silver_orders') }} o       on oi.order_id = o.order_id
left join {{ ref('dim_customer') }} c   on o.customer_id = c.customer_id
left join {{ ref('dim_seller') }} s     on oi.seller_id = s.seller_id