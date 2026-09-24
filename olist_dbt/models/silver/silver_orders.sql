with base as (
  select
    order_id,
    customer_id,
    lower(trim(order_status))                              as order_status,
    try_cast(order_purchase_timestamp as timestamp)        as purchased_at,
    try_cast(order_approved_at as timestamp)               as approved_at,
    try_cast(order_delivered_carrier_date as timestamp)    as shipped_at,
    try_cast(order_delivered_customer_date as timestamp)   as delivered_at,
    try_cast(order_estimated_delivery_date as timestamp)   as estimated_delivery_at
  from {{ source('bronze', 'orders') }}
  qualify row_number() over (partition by order_id order by _ingested_at desc) = 1
)
select
  *,
  datediff(delivered_at, purchased_at)                           as delivery_days,
  datediff(to_date(delivered_at), to_date(estimated_delivery_at)) as delay_days,
  case when delivered_at is null then null
       else to_date(delivered_at) > to_date(estimated_delivery_at) end as is_late
from base