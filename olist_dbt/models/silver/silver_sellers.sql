select
  seller_id,
  lpad(seller_zip_code_prefix, 5, '0')         as zip_prefix,
  initcap(trim(seller_city))                   as city,
  upper(trim(seller_state))                    as state
from {{ source('bronze', 'sellers') }}
qualify row_number() over (partition by seller_id order by _ingested_at desc) = 1