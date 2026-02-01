/*
 * Query 2: Early Behavior Analysis - First 90 Days Comparison
 *
 * Purpose: Compare activity patterns in the first 90 days between users
 * who eventually became power users vs those who remained average users.
 * This addresses the critical question: "Did power users start as power users
 * or grow into the role?"
 *
 * Analysis:
 * - How many answers did each cohort post in first 90 days?
 * - What was their average answer score in first 90 days?
 * - What was their answer length in first 90 days?
 * - What was their acceptance rate in first 90 days?
 */

WITH user_cohorts AS (
  SELECT
    id as user_id,
    creation_date as user_creation_date,
    reputation,
    CASE
      WHEN reputation >= (SELECT PERCENTILE_CONT(reputation, 0.99) OVER() FROM `bigquery-public-data.stackoverflow.users` LIMIT 1)
        THEN 'power_user_top1pct'
      WHEN reputation BETWEEN 1 AND 100 THEN 'average_user_1_100rep'
      ELSE 'other'
    END as cohort
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1
),

first_90_days_answers AS (
  SELECT
    a.owner_user_id as user_id,
    COUNT(*) as answers_first_90d,
    AVG(LENGTH(a.body)) as avg_answer_length_first_90d,
    AVG(a.score) as avg_score_first_90d,
    COUNTIF(a.score > 0) as positive_answers_first_90d,
    SAFE_DIVIDE(COUNTIF(a.score > 0), COUNT(*)) as positive_rate_first_90d,
    COUNTIF(q.accepted_answer_id = a.id) as accepted_answers_first_90d,
    SAFE_DIVIDE(COUNTIF(q.accepted_answer_id = a.id), COUNT(*)) as acceptance_rate_first_90d
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN user_cohorts c ON a.owner_user_id = c.user_id
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_questions` q ON a.parent_id = q.id
  WHERE a.creation_date <= TIMESTAMP_ADD(c.user_creation_date, INTERVAL 90 DAY)
    AND a.owner_user_id IS NOT NULL
  GROUP BY a.owner_user_id
)

SELECT
  c.cohort,
  COUNT(DISTINCT c.user_id) as total_users_in_cohort,
  COUNT(DISTINCT f.user_id) as users_who_answered_first_90d,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT f.user_id), COUNT(DISTINCT c.user_id)) * 100, 2) as pct_users_who_answered_first_90d,
  -- First 90 days activity metrics
  ROUND(AVG(f.answers_first_90d), 2) as avg_answers_first_90d,
  ROUND(AVG(f.avg_answer_length_first_90d), 0) as avg_answer_length_first_90d,
  ROUND(AVG(f.avg_score_first_90d), 3) as avg_score_first_90d,
  ROUND(AVG(f.positive_rate_first_90d) * 100, 2) as avg_positive_rate_first_90d_pct,
  ROUND(AVG(f.acceptance_rate_first_90d) * 100, 2) as avg_acceptance_rate_first_90d_pct,
  -- Distribution of answers in first 90 days
  COUNTIF(f.answers_first_90d >= 10) as users_with_10plus_answers_first_90d,
  ROUND(SAFE_DIVIDE(COUNTIF(f.answers_first_90d >= 10), COUNT(DISTINCT f.user_id)) * 100, 2) as pct_with_10plus_first_90d
FROM user_cohorts c
LEFT JOIN first_90_days_answers f ON c.user_id = f.user_id
WHERE c.cohort IN ('power_user_top1pct', 'average_user_1_100rep')
GROUP BY c.cohort
ORDER BY avg_score_first_90d DESC;
