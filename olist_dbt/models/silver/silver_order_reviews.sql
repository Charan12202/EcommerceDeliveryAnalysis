select
  review_id,
  order_id,
  cast(review_score as int)                            as review_score,
  nullif(trim(review_comment_title), '')               as review_title,
  nullif(trim(review_comment_message), '')             as review_message,
  try_cast(review_creation_date as timestamp)          as review_created_at,
  try_cast(review_answer_timestamp as timestamp)       as review_answered_at
from {{ source('bronze', 'order_reviews') }}
where review_score is not null
qualify row_number() over (partition by order_id order by review_answer_timestamp desc) = 1