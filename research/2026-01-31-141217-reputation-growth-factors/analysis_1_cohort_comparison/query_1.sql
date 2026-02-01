/*
 * Query 1: Early Adopters vs Late Joiners - Cohort Comparison by Activity Level
 *
 * This query segments Stack Overflow users into two cohorts:
 *   - Early Adopters: joined 2008-2012
 *   - Late Joiners: joined 2018-2022
 *
 * For each cohort, users are bucketed by activity level (number of answers posted),
 * and we compare average reputation, avg score per answer, and milestone achievement rates.
 *
 * This allows us to control for activity level and isolate the "first-mover advantage"
 * effect from pure effort/contribution differences.
 */

WITH user_answer_stats AS (
  -- Get answer counts and scores per user
  SELECT
    owner_user_id,
    COUNT(*) AS answer_count,
    SUM(score) AS total_answer_score,
    AVG(score) AS avg_score_per_answer
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_cohorts AS (
  -- Segment users into Early (2008-2012) and Late (2018-2022) cohorts
  SELECT
    u.id AS user_id,
    u.reputation,
    u.creation_date,
    EXTRACT(YEAR FROM u.creation_date) AS join_year,
    CASE
      WHEN EXTRACT(YEAR FROM u.creation_date) BETWEEN 2008 AND 2012 THEN 'Early (2008-2012)'
      WHEN EXTRACT(YEAR FROM u.creation_date) BETWEEN 2018 AND 2022 THEN 'Late (2018-2022)'
      ELSE 'Other'
    END AS cohort,
    COALESCE(a.answer_count, 0) AS answer_count,
    COALESCE(a.total_answer_score, 0) AS total_answer_score,
    COALESCE(a.avg_score_per_answer, 0) AS avg_score_per_answer
  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN user_answer_stats a ON u.id = a.owner_user_id
  WHERE EXTRACT(YEAR FROM u.creation_date) BETWEEN 2008 AND 2012
     OR EXTRACT(YEAR FROM u.creation_date) BETWEEN 2018 AND 2022
),

activity_buckets AS (
  -- Bucket users by activity level
  SELECT
    *,
    CASE
      WHEN answer_count = 0 THEN '0_none'
      WHEN answer_count BETWEEN 1 AND 5 THEN '1_1-5'
      WHEN answer_count BETWEEN 6 AND 20 THEN '2_6-20'
      WHEN answer_count BETWEEN 21 AND 100 THEN '3_21-100'
      WHEN answer_count BETWEEN 101 AND 500 THEN '4_101-500'
      ELSE '5_500+'
    END AS activity_bucket
  FROM user_cohorts
)

SELECT
  cohort,
  activity_bucket,
  COUNT(*) AS user_count,
  -- Reputation metrics
  ROUND(AVG(reputation), 2) AS avg_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(50)], 2) AS median_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(90)], 2) AS p90_reputation,
  -- Score efficiency
  ROUND(AVG(avg_score_per_answer), 3) AS avg_score_per_answer,
  ROUND(SUM(total_answer_score) * 1.0 / NULLIF(SUM(answer_count), 0), 3) AS cohort_avg_score_per_answer,
  -- Milestone achievement rates
  ROUND(100.0 * COUNTIF(reputation >= 1000) / COUNT(*), 2) AS pct_reached_1k,
  ROUND(100.0 * COUNTIF(reputation >= 10000) / COUNT(*), 2) AS pct_reached_10k,
  ROUND(100.0 * COUNTIF(reputation >= 50000) / COUNT(*), 2) AS pct_reached_50k,
  -- Activity summary
  ROUND(AVG(answer_count), 1) AS avg_answers_in_bucket
FROM activity_buckets
GROUP BY cohort, activity_bucket
ORDER BY cohort, activity_bucket
