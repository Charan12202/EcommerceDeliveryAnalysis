select
  order_id,
  cast(payment_sequential as int)              as payment_sequential,
  lower(trim(payment_type))                    as payment_type,
  cast(payment_installments as int)            as payment_installments,
  cast(payment_value as decimal(10,2))         as payment_value
from {{ source('bronze', 'order_payments') }}
where payment_type != 'not_defined'
qualify row_number() over (partition by order_id, payment_sequential order by _ingested_at desc) = 1