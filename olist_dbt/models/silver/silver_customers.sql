select
  customer_id,
  customer_unique_id,
  lpad(customer_zip_code_prefix, 5, '0')       as zip_prefix,
  initcap(trim(customer_city))                 as city,
  upper(trim(customer_state))                  as state
from {{ source('bronze', 'customers') }}
qualify row_number() over (partition by customer_id order by _ingested_at desc) = 1