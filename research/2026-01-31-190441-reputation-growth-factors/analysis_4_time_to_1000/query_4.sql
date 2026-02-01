/*
 * Query 4: Stratified Analysis - Score Per Answer by Activity Level and Cohort
 *
 * Purpose: Definitive test of whether conditions degraded or selection changed.
 * For users with EXACTLY the same early activity level (10-20 answers in first year),
 * compare score earned across cohorts.
 *
 * This isolates the effect of platform conditions from user behavior differences.
 */

WITH user_cohorts AS (
  SELECT
    id AS user_id,
    EXTRACT(YEAR FROM creation_date) AS cohort_year,
    creation_date
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) BETWEEN 2008 AND 2020
),

first_year_answers AS (
  SELECT
    uc.user_id,
    uc.cohort_year,
    a.score
  FROM user_cohorts uc
  INNER JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON uc.user_id = a.owner_user_id
    AND a.creation_date BETWEEN uc.creation_date
        AND TIMESTAMP_ADD(uc.creation_date, INTERVAL 365 DAY)
),

user_stats AS (
  SELECT
    user_id,
    cohort_year,
    COUNT(*) AS answer_count,
    SUM(score) AS total_score,
    SAFE_DIVIDE(SUM(score), COUNT(*)) AS avg_score
  FROM first_year_answers
  GROUP BY user_id, cohort_year
),

activity_matched AS (
  -- Select users with similar activity level: 10-20 answers in first year
  SELECT *
  FROM user_stats
  WHERE answer_count BETWEEN 10 AND 20
)

SELECT
  cohort_year,
  COUNT(*) AS users,
  AVG(answer_count) AS avg_answers,
  AVG(total_score) AS avg_total_score,
  AVG(avg_score) AS avg_score_per_answer,
  APPROX_QUANTILES(total_score, 100)[OFFSET(50)] AS median_total_score,
  APPROX_QUANTILES(avg_score, 100)[OFFSET(50)] AS median_score_per_answer,
  -- Success rates
  SAFE_DIVIDE(COUNTIF(total_score >= 100), COUNT(*)) * 100 AS pct_100_plus_score,
  SAFE_DIVIDE(COUNTIF(total_score >= 200), COUNT(*)) * 100 AS pct_200_plus_score
FROM activity_matched
GROUP BY cohort_year
ORDER BY cohort_year
