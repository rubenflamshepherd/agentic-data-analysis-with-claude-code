/*
  Query 2: Acceptance Rate by Answer Length

  Purpose: Analyze whether longer, more detailed answers have higher acceptance rates.

  Length buckets based on character count of HTML body:
  - Very short (< 200 chars): Brief one-liner answers
  - Short (200-500 chars): Quick explanations
  - Medium (500-1500 chars): Standard answers
  - Long (1500-3000 chars): Detailed explanations
  - Very long (3000+ chars): Comprehensive answers

  Focuses on 2018-2022 data for consistency with previous query.
*/

WITH answer_data AS (
  SELECT
    a.id AS answer_id,
    a.parent_id AS question_id,
    a.owner_user_id,
    a.score AS answer_score,
    CASE WHEN q.accepted_answer_id = a.id THEN 1 ELSE 0 END AS is_accepted,
    LENGTH(a.body) AS answer_length,
    TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) AS response_minutes
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.owner_user_id IS NOT NULL
    AND a.creation_date >= q.creation_date
    AND EXTRACT(YEAR FROM a.creation_date) BETWEEN 2018 AND 2022
),
bucketed AS (
  SELECT
    *,
    CASE
      WHEN answer_length < 200 THEN '01. Very short (<200)'
      WHEN answer_length < 500 THEN '02. Short (200-500)'
      WHEN answer_length < 1500 THEN '03. Medium (500-1500)'
      WHEN answer_length < 3000 THEN '04. Long (1500-3000)'
      ELSE '05. Very long (3000+)'
    END AS length_bucket
  FROM answer_data
)

SELECT
  length_bucket,
  COUNT(*) AS total_answers,
  SUM(is_accepted) AS accepted_count,
  SAFE_DIVIDE(SUM(is_accepted), COUNT(*)) * 100 AS acceptance_rate_pct,
  AVG(answer_score) AS avg_score,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100 AS pct_of_all_answers,
  AVG(response_minutes) AS avg_response_minutes
FROM bucketed
GROUP BY length_bucket
ORDER BY length_bucket
