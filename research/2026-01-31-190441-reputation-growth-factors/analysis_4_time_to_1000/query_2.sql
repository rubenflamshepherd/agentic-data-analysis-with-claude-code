/*
 * Query 2: Time to 1000 Rep Controlling for Early Activity Level
 *
 * Purpose: Compare time-to-1000-rep between cohorts while controlling for
 * activity level in the first 90 days. This addresses selection bias:
 * are 2008 users faster because conditions were better, or because
 * the survivors were simply more active?
 *
 * Approach: Bucket users by their answer count in first 90 days,
 * then compare time-to-1000 within each activity bucket across cohorts.
 */

WITH user_cohorts AS (
  SELECT
    id AS user_id,
    EXTRACT(YEAR FROM creation_date) AS cohort_year,
    creation_date,
    reputation
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1000
    AND EXTRACT(YEAR FROM creation_date) BETWEEN 2008 AND 2020
),

early_activity AS (
  -- Count answers in first 90 days after signup
  SELECT
    uc.user_id,
    uc.cohort_year,
    uc.creation_date,
    COUNT(*) AS answers_first_90_days,
    SUM(a.score) AS score_first_90_days
  FROM user_cohorts uc
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON uc.user_id = a.owner_user_id
    AND a.creation_date BETWEEN uc.creation_date
        AND TIMESTAMP_ADD(uc.creation_date, INTERVAL 90 DAY)
  GROUP BY uc.user_id, uc.cohort_year, uc.creation_date
),

activity_bucketed AS (
  SELECT
    *,
    CASE
      WHEN answers_first_90_days IS NULL OR answers_first_90_days = 0 THEN '0_none'
      WHEN answers_first_90_days BETWEEN 1 AND 5 THEN '1_low_1_5'
      WHEN answers_first_90_days BETWEEN 6 AND 20 THEN '2_medium_6_20'
      WHEN answers_first_90_days BETWEEN 21 AND 50 THEN '3_high_21_50'
      ELSE '4_very_high_50plus'
    END AS activity_bucket
  FROM early_activity
),

user_answers_with_cumsum AS (
  SELECT
    ab.user_id,
    ab.cohort_year,
    ab.creation_date AS user_created,
    ab.activity_bucket,
    a.creation_date AS answer_date,
    a.score,
    SUM(a.score) OVER (
      PARTITION BY ab.user_id
      ORDER BY a.creation_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_score
  FROM activity_bucketed ab
  INNER JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON ab.user_id = a.owner_user_id
  WHERE a.creation_date >= ab.creation_date
),

first_crossing AS (
  SELECT
    user_id,
    cohort_year,
    user_created,
    activity_bucket,
    MIN(answer_date) AS crossed_1000_date
  FROM user_answers_with_cumsum
  WHERE cumulative_score >= 100
  GROUP BY user_id, cohort_year, user_created, activity_bucket
),

time_to_milestone AS (
  SELECT
    user_id,
    cohort_year,
    activity_bucket,
    DATE_DIFF(DATE(crossed_1000_date), DATE(user_created), DAY) AS days_to_1000
  FROM first_crossing
)

SELECT
  activity_bucket,
  cohort_year,
  COUNT(*) AS users,
  AVG(days_to_1000) AS avg_days_to_1000,
  APPROX_QUANTILES(days_to_1000, 100)[OFFSET(50)] AS median_days_to_1000,
  SAFE_DIVIDE(COUNTIF(days_to_1000 <= 90), COUNT(*)) * 100 AS pct_fast_achievers
FROM time_to_milestone
GROUP BY activity_bucket, cohort_year
HAVING COUNT(*) >= 50  -- Require minimum sample size
ORDER BY activity_bucket, cohort_year
