/*
 * Query 4: Gap-Closing Analysis - What Activity Level Lets Late Joiners Match Early Adopters?
 *
 * This query identifies whether late joiners can ever achieve similar reputation outcomes
 * to early adopters, and at what activity level.
 *
 * We compare late joiners at higher activity levels to early adopters at lower levels
 * to find the "activity multiplier" needed to close the first-mover advantage gap.
 *
 * Also examines the very top performers from each cohort to see if exceptional
 * late joiners can match typical early adopter success.
 */

WITH user_answer_stats AS (
  SELECT
    owner_user_id,
    COUNT(*) AS answer_count,
    SUM(score) AS total_answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_cohorts AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    u.creation_date,
    EXTRACT(YEAR FROM u.creation_date) AS join_year,
    CASE
      WHEN EXTRACT(YEAR FROM u.creation_date) BETWEEN 2008 AND 2012 THEN 'Early'
      WHEN EXTRACT(YEAR FROM u.creation_date) BETWEEN 2018 AND 2022 THEN 'Late'
    END AS cohort,
    COALESCE(a.answer_count, 0) AS answer_count,
    COALESCE(a.total_answer_score, 0) AS total_answer_score
  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN user_answer_stats a ON u.id = a.owner_user_id
  WHERE EXTRACT(YEAR FROM u.creation_date) BETWEEN 2008 AND 2012
     OR EXTRACT(YEAR FROM u.creation_date) BETWEEN 2018 AND 2022
),

-- More granular buckets to find crossover points
with_detailed_buckets AS (
  SELECT
    *,
    CASE
      WHEN answer_count = 0 THEN '00_0'
      WHEN answer_count BETWEEN 1 AND 2 THEN '01_1-2'
      WHEN answer_count BETWEEN 3 AND 5 THEN '02_3-5'
      WHEN answer_count BETWEEN 6 AND 10 THEN '03_6-10'
      WHEN answer_count BETWEEN 11 AND 20 THEN '04_11-20'
      WHEN answer_count BETWEEN 21 AND 50 THEN '05_21-50'
      WHEN answer_count BETWEEN 51 AND 100 THEN '06_51-100'
      WHEN answer_count BETWEEN 101 AND 200 THEN '07_101-200'
      WHEN answer_count BETWEEN 201 AND 500 THEN '08_201-500'
      WHEN answer_count BETWEEN 501 AND 1000 THEN '09_501-1000'
      ELSE '10_1000+'
    END AS activity_bucket
  FROM user_cohorts
)

SELECT
  cohort,
  activity_bucket,
  COUNT(*) AS user_count,
  -- Reputation metrics
  ROUND(AVG(reputation), 0) AS avg_rep,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(50)], 0) AS median_rep,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(75)], 0) AS p75_rep,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(90)], 0) AS p90_rep,
  -- Milestone rates
  ROUND(100.0 * COUNTIF(reputation >= 1000) / COUNT(*), 2) AS pct_1k,
  ROUND(100.0 * COUNTIF(reputation >= 5000) / COUNT(*), 2) AS pct_5k,
  ROUND(100.0 * COUNTIF(reputation >= 10000) / COUNT(*), 2) AS pct_10k,
  ROUND(100.0 * COUNTIF(reputation >= 25000) / COUNT(*), 2) AS pct_25k,
  -- Activity summary
  ROUND(AVG(answer_count), 1) AS avg_answers
FROM with_detailed_buckets
WHERE answer_count > 0  -- Focus on active users
GROUP BY cohort, activity_bucket
ORDER BY cohort, activity_bucket
