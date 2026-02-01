/*
  Query 4: Combined Factor Analysis - Optimal Acceptance Profile

  Purpose: Analyze all three factors simultaneously to find the optimal combination
  for maximizing acceptance probability. Uses stratified analysis.

  Simplified buckets for cross-tabulation:
  - Response time: Fast (<4hr), Medium (4-72hr), Slow (72hr+)
  - Answer length: Short (<500), Medium (500-2000), Long (2000+)
  - Reputation: Low (<1k), Medium (1k-25k), High (25k+)

  This allows us to see interaction effects and find the "sweet spot".
*/

WITH answer_data AS (
  SELECT
    a.id AS answer_id,
    a.parent_id AS question_id,
    a.owner_user_id,
    a.score AS answer_score,
    u.reputation AS user_reputation,
    CASE WHEN q.accepted_answer_id = a.id THEN 1 ELSE 0 END AS is_accepted,
    LENGTH(a.body) AS answer_length,
    TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) AS response_minutes
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  INNER JOIN `bigquery-public-data.stackoverflow.users` u
    ON a.owner_user_id = u.id
  WHERE a.owner_user_id IS NOT NULL
    AND a.creation_date >= q.creation_date
    AND EXTRACT(YEAR FROM a.creation_date) BETWEEN 2018 AND 2022
),
bucketed AS (
  SELECT
    *,
    CASE
      WHEN response_minutes <= 240 THEN 'Fast (<4hr)'
      WHEN response_minutes <= 4320 THEN 'Medium (4-72hr)'
      ELSE 'Slow (72hr+)'
    END AS speed_bucket,
    CASE
      WHEN answer_length < 500 THEN 'Short'
      WHEN answer_length < 2000 THEN 'Medium'
      ELSE 'Long'
    END AS length_bucket,
    CASE
      WHEN user_reputation < 1000 THEN 'Low (<1k)'
      WHEN user_reputation < 25000 THEN 'Mid (1k-25k)'
      ELSE 'High (25k+)'
    END AS rep_bucket
  FROM answer_data
)

SELECT
  speed_bucket,
  length_bucket,
  rep_bucket,
  COUNT(*) AS total_answers,
  SUM(is_accepted) AS accepted_count,
  SAFE_DIVIDE(SUM(is_accepted), COUNT(*)) * 100 AS acceptance_rate_pct,
  AVG(answer_score) AS avg_score
FROM bucketed
GROUP BY speed_bucket, length_bucket, rep_bucket
ORDER BY acceptance_rate_pct DESC
