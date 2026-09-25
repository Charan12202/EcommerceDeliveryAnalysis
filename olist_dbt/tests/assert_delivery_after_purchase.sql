{{ config(severity='warn') }}

select order_id, purchased_at, delivered_at
from {{ ref('fact_orders') }}
where delivered_at < purchased_at