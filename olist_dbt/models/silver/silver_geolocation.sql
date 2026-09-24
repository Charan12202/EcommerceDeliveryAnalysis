select
  lpad(geolocation_zip_code_prefix, 5, '0')    as zip_prefix,
  avg(cast(geolocation_lat as double))         as lat,
  avg(cast(geolocation_lng as double))         as lng,
  first(upper(trim(geolocation_state)))        as state
from {{ source('bronze', 'geolocation') }}
where cast(geolocation_lat as double) between -35 and 5.5
  and cast(geolocation_lng as double) between -75 and -34
group by 1