/*
 * Query 1: Cohort Definition and Basic Answer Characteristics Comparison
 *
 * Purpose: Define top 1% reputation users vs median users (reputation 1-100)
 * and compare their answer characteristics including:
 * - Average answer length
 * - Average answer score
 * - Total answers posted
 * - Acceptance rate
 *
 * Cohort Definitions:
 * - Power users: Top 1% by reputation (using PERCENTILE_CONT)
 * - Average users: Reputation between 1-100 (median band)
 */

WITH user_reputation_percentiles AS (
  SELECT
    PERCENTILE_CONT(reputation, 0.99) OVER() as p99_reputation,
    id as user_id,
    reputation,
    creation_date as user_creation_date
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1
),

cohort_users AS (
  SELECT
    user_id,
    reputation,
    user_creation_date,
    CASE
      WHEN reputation >= p99_reputation THEN 'power_user_top1pct'
      WHEN reputation BETWEEN 1 AND 100 THEN 'average_user_1_100rep'
      ELSE 'other'
    END as cohort
  FROM user_reputation_percentiles
),

user_answer_stats AS (
  SELECT
    a.owner_user_id as user_id,
    COUNT(*) as total_answers,
    AVG(LENGTH(a.body)) as avg_answer_length_chars,
    AVG(a.score) as avg_answer_score,
    SUM(a.score) as total_answer_score,
    COUNTIF(a.score > 0) as positive_answers,
    SAFE_DIVIDE(COUNTIF(a.score > 0), COUNT(*)) as positive_answer_rate,
    -- Check if answer was accepted by joining with questions
    COUNTIF(q.accepted_answer_id = a.id) as accepted_answers,
    SAFE_DIVIDE(COUNTIF(q.accepted_answer_id = a.id), COUNT(*)) as acceptance_rate,
    MIN(a.creation_date) as first_answer_date,
    MAX(a.creation_date) as last_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.owner_user_id IS NOT NULL
  GROUP BY a.owner_user_id
)

SELECT
  c.cohort,
  COUNT(DISTINCT c.user_id) as user_count,
  -- Reputation stats
  AVG(c.reputation) as avg_reputation,
  MIN(c.reputation) as min_reputation,
  MAX(c.reputation) as max_reputation,
  -- Answer volume
  ROUND(AVG(COALESCE(a.total_answers, 0)), 2) as avg_answers_per_user,
  SUM(COALESCE(a.total_answers, 0)) as total_answers,
  -- Answer quality
  ROUND(AVG(a.avg_answer_length_chars), 0) as avg_answer_length_chars,
  ROUND(AVG(a.avg_answer_score), 3) as avg_score_per_answer,
  -- Success rates
  ROUND(AVG(a.positive_answer_rate) * 100, 2) as avg_positive_rate_pct,
  ROUND(AVG(a.acceptance_rate) * 100, 2) as avg_acceptance_rate_pct,
  -- Total impact
  SUM(COALESCE(a.total_answer_score, 0)) as total_score_generated
FROM cohort_users c
LEFT JOIN user_answer_stats a ON c.user_id = a.user_id
WHERE c.cohort IN ('power_user_top1pct', 'average_user_1_100rep')
GROUP BY c.cohort
ORDER BY avg_reputation DESC;
