with items as (
  select
    order_id,
    count(*)                  as item_count,
    count(distinct seller_id) as seller_count,
    sum(price)                as items_total,
    sum(freight_value)        as freight_total
  from {{ ref('silver_order_items') }}
  group by order_id
),

payments as (
  select
    order_id,
    sum(payment_value)                       as payment_total,
    max(payment_installments)                as max_installments,
    max_by(payment_type, payment_value)      as main_payment_type
  from {{ ref('silver_order_payments') }}
  group by order_id
)

select
  o.order_id,
  o.customer_id,
  cast(date_format(o.purchased_at, 'yyyyMMdd') as int)  as purchase_date_key,
  o.order_status,
  o.purchased_at,
  o.shipped_at,
  o.delivered_at,
  o.estimated_delivery_at,
  datediff(o.estimated_delivery_at, o.purchased_at)     as promised_days,
  o.delivery_days,
  o.delay_days,
  o.is_late,
  i.item_count,
  i.seller_count,
  i.items_total,
  i.freight_total,
  p.payment_total,
  p.max_installments,
  p.main_payment_type,
  r.review_score,
  r.review_message is not null                          as has_review_comment
from {{ ref('silver_orders') }} o
left join items i                          on o.order_id = i.order_id
left join payments p                       on o.order_id = p.order_id
left join {{ ref('silver_order_reviews') }} r on o.order_id = r.order_id