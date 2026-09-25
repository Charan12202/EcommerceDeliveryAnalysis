select count(*) as row_count
from {{ ref('fact_orders') }}
having count(*) < 90000