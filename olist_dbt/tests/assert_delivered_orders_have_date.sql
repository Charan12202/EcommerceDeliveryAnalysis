{{ config(severity='warn') }}

select order_id, order_status, delivered_at
from {{ ref('fact_orders') }}
where order_status = 'delivered'
  and delivered_at is null