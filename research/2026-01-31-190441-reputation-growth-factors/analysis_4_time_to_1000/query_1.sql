/*
 * Query 1: Time to 1000 Rep Analysis by Cohort Year
 *
 * Purpose: Analyze how quickly users reach 1,000 reputation milestone by signup year.
 * Since we don't have historical reputation snapshots, we use cumulative answer score
 * as a proxy and estimate when users crossed the threshold based on their answer patterns.
 *
 * Approach: Join users with their answers, calculate cumulative score over time,
 * and identify the first answer date where cumulative score would have crossed ~100 upvotes
 * (100 upvotes * 10 rep = 1000 rep, as a rough proxy).
 */

WITH user_cohorts AS (
  -- Users who have achieved 1000+ reputation
  SELECT
    id AS user_id,
    EXTRACT(YEAR FROM creation_date) AS cohort_year,
    creation_date,
    reputation
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1000
    AND EXTRACT(YEAR FROM creation_date) BETWEEN 2008 AND 2022
),

user_answers_with_cumsum AS (
  -- For each user's answers, calculate running total of score
  SELECT
    uc.user_id,
    uc.cohort_year,
    uc.creation_date AS user_created,
    a.creation_date AS answer_date,
    a.score,
    SUM(a.score) OVER (
      PARTITION BY uc.user_id
      ORDER BY a.creation_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_score
  FROM user_cohorts uc
  INNER JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON uc.user_id = a.owner_user_id
  WHERE a.creation_date >= uc.creation_date
),

first_crossing AS (
  -- Find the first answer where cumulative score crossed 100 (proxy for 1000 rep)
  -- 100 upvotes * 10 rep/upvote = 1000 rep
  SELECT
    user_id,
    cohort_year,
    user_created,
    MIN(answer_date) AS crossed_1000_date
  FROM user_answers_with_cumsum
  WHERE cumulative_score >= 100
  GROUP BY user_id, cohort_year, user_created
),

time_to_milestone AS (
  SELECT
    user_id,
    cohort_year,
    user_created,
    crossed_1000_date,
    DATE_DIFF(DATE(crossed_1000_date), DATE(user_created), DAY) AS days_to_1000
  FROM first_crossing
)

SELECT
  cohort_year,
  COUNT(*) AS users_reached_1000,
  -- Central tendency
  AVG(days_to_1000) AS avg_days_to_1000,
  -- Percentiles for distribution understanding
  APPROX_QUANTILES(days_to_1000, 100)[OFFSET(50)] AS median_days_to_1000,
  APPROX_QUANTILES(days_to_1000, 100)[OFFSET(25)] AS p25_days_to_1000,
  APPROX_QUANTILES(days_to_1000, 100)[OFFSET(75)] AS p75_days_to_1000,
  APPROX_QUANTILES(days_to_1000, 100)[OFFSET(90)] AS p90_days_to_1000,
  -- Fast achievers (under 90 days)
  COUNTIF(days_to_1000 <= 90) AS fast_achievers,
  SAFE_DIVIDE(COUNTIF(days_to_1000 <= 90), COUNT(*)) * 100 AS pct_fast_achievers,
  -- Slow achievers (over 365 days)
  COUNTIF(days_to_1000 > 365) AS slow_achievers,
  SAFE_DIVIDE(COUNTIF(days_to_1000 > 365), COUNT(*)) * 100 AS pct_slow_achievers
FROM time_to_milestone
GROUP BY cohort_year
ORDER BY cohort_year
