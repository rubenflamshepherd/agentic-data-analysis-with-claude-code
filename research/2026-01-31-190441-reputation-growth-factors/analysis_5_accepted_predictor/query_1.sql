/*
  Query 1: Acceptance Rate by Response Time

  Purpose: Analyze how quickly an answer is submitted after a question is posted
  and whether faster responses have higher acceptance rates.

  Response time buckets:
  - 0-1 hour: Immediate responders
  - 1-4 hours: Quick responders
  - 4-24 hours: Same-day responders
  - 24-72 hours: Within 3 days
  - 72+ hours: Late responders

  Joins posts_answers to posts_questions to calculate response time.
*/

WITH answer_response_times AS (
  SELECT
    a.id AS answer_id,
    a.parent_id AS question_id,
    a.owner_user_id,
    a.score AS answer_score,
    CASE WHEN q.accepted_answer_id = a.id THEN 1 ELSE 0 END AS is_accepted,
    TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) AS response_minutes,
    LENGTH(a.body) AS answer_length,
    EXTRACT(YEAR FROM a.creation_date) AS answer_year
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.owner_user_id IS NOT NULL
    AND a.creation_date >= q.creation_date  -- Answer must be after question
    AND EXTRACT(YEAR FROM a.creation_date) BETWEEN 2018 AND 2022  -- Last 5 years of data
),
bucketed AS (
  SELECT
    *,
    CASE
      WHEN response_minutes <= 60 THEN '01. 0-1 hour'
      WHEN response_minutes <= 240 THEN '02. 1-4 hours'
      WHEN response_minutes <= 1440 THEN '03. 4-24 hours'
      WHEN response_minutes <= 4320 THEN '04. 1-3 days'
      ELSE '05. 3+ days'
    END AS response_time_bucket
  FROM answer_response_times
)

SELECT
  response_time_bucket,
  COUNT(*) AS total_answers,
  SUM(is_accepted) AS accepted_count,
  SAFE_DIVIDE(SUM(is_accepted), COUNT(*)) * 100 AS acceptance_rate_pct,
  AVG(answer_score) AS avg_score,
  AVG(answer_length) AS avg_answer_length,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100 AS pct_of_all_answers
FROM bucketed
GROUP BY response_time_bucket
ORDER BY response_time_bucket
