/*
 * Query 3: Score Per Answer by Cohort Year (Controlling for Answer Timing)
 *
 * Purpose: Quantify the "difficulty multiplier" - how much harder is it
 * to earn reputation from answers in later years vs 2008?
 *
 * This measures raw conditions: for identical answer volume at the same
 * point in their tenure, how much less do later cohorts earn?
 *
 * Approach: Compare average score per answer earned in the first year
 * of account existence, by cohort year. This controls for accumulated time
 * advantage since we're comparing the same tenure window.
 */

WITH user_cohorts AS (
  SELECT
    id AS user_id,
    EXTRACT(YEAR FROM creation_date) AS cohort_year,
    creation_date
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) BETWEEN 2008 AND 2021
),

first_year_answers AS (
  -- Answers posted within first 365 days of account creation
  SELECT
    uc.user_id,
    uc.cohort_year,
    a.id AS answer_id,
    a.score,
    a.creation_date AS answer_date
  FROM user_cohorts uc
  INNER JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON uc.user_id = a.owner_user_id
    AND a.creation_date BETWEEN uc.creation_date
        AND TIMESTAMP_ADD(uc.creation_date, INTERVAL 365 DAY)
),

user_first_year_stats AS (
  SELECT
    user_id,
    cohort_year,
    COUNT(*) AS answers_first_year,
    SUM(score) AS total_score_first_year,
    SAFE_DIVIDE(SUM(score), COUNT(*)) AS avg_score_per_answer
  FROM first_year_answers
  GROUP BY user_id, cohort_year
)

SELECT
  cohort_year,
  COUNT(*) AS users_with_answers,
  SUM(answers_first_year) AS total_answers,
  SUM(total_score_first_year) AS total_score,
  -- Overall average score per answer
  SAFE_DIVIDE(SUM(total_score_first_year), SUM(answers_first_year)) AS avg_score_per_answer,
  -- User-level average (weights each user equally)
  AVG(avg_score_per_answer) AS avg_user_score_per_answer,
  -- Distribution of user performance
  APPROX_QUANTILES(avg_score_per_answer, 100)[OFFSET(50)] AS median_user_score_per_answer,
  APPROX_QUANTILES(avg_score_per_answer, 100)[OFFSET(90)] AS p90_user_score_per_answer,
  -- Success rate metrics
  SAFE_DIVIDE(COUNTIF(total_score_first_year >= 100), COUNT(*)) * 100 AS pct_reaching_100_score,
  SAFE_DIVIDE(COUNTIF(total_score_first_year >= 1000), COUNT(*)) * 100 AS pct_reaching_1000_score
FROM user_first_year_stats
GROUP BY cohort_year
ORDER BY cohort_year
