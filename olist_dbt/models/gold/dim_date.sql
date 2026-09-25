with dates as (
  select explode(sequence(to_date('2016-01-01'), to_date('2018-12-31'), interval 1 day)) as date_day
)
select
  cast(date_format(date_day, 'yyyyMMdd') as int)  as date_key,
  date_day,
  year(date_day)                                  as year,
  quarter(date_day)                               as quarter,
  month(date_day)                                 as month,
  date_format(date_day, 'MMMM')                   as month_name,
  date_format(date_day, 'yyyy-MM')                as year_month,
  dayofweek(date_day)                             as day_of_week,
  date_format(date_day, 'EEEE')                   as day_name,
  dayofweek(date_day) in (1, 7)                   as is_weekend
from dates