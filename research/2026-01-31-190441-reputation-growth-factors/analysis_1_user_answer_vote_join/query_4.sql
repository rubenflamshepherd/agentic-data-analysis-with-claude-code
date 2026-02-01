/*
 * Query 4: New User Success Factors
 *
 * Purpose: Analyze users who joined in the last 3 years of available data
 * and compare those who successfully grew reputation (100+) vs those who
 * didn't. This identifies what behaviors differentiate successful new users.
 *
 * Focuses on recent cohorts (2019-2022) to understand current conditions
 * for reputation growth.
 */

WITH recent_users AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    u.creation_date,
    DATE_DIFF(DATE('2022-09-25'), DATE(u.creation_date), DAY) AS account_age_days,
    CASE
      WHEN u.reputation >= 1000 THEN 'Success_1k+'
      WHEN u.reputation >= 100 THEN 'Growing_100-1k'
      WHEN u.reputation >= 10 THEN 'Struggling_10-100'
      ELSE 'Inactive_1-10'
    END AS growth_category
  FROM `bigquery-public-data.stackoverflow.users` u
  WHERE u.creation_date >= '2019-01-01'
    AND u.creation_date < '2022-09-01'
    AND u.reputation >= 1
),

user_answers AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS answer_count,
    SUM(score) AS answer_score,
    COUNTIF(score > 0) AS positive_answers,
    COUNTIF(score >= 5) AS good_answers,
    AVG(score) AS avg_score_per_answer,
    MIN(creation_date) AS first_answer_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE creation_date >= '2019-01-01'
    AND owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_questions AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS question_count,
    SUM(score) AS question_score,
    COUNTIF(score > 0) AS positive_questions,
    AVG(score) AS avg_score_per_question
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2019-01-01'
    AND owner_user_id IS NOT NULL
  GROUP BY owner_user_id
)

SELECT
  ru.growth_category,
  COUNT(*) AS user_count,
  -- Answer behavior
  ROUND(AVG(COALESCE(ua.answer_count, 0)), 2) AS avg_answers,
  ROUND(SAFE_DIVIDE(SUM(CASE WHEN ua.answer_count > 0 THEN 1 ELSE 0 END), COUNT(*)) * 100, 2) AS pct_with_answers,
  ROUND(AVG(CASE WHEN ua.answer_count > 0 THEN ua.avg_score_per_answer END), 3) AS avg_score_if_answered,
  ROUND(SAFE_DIVIDE(SUM(ua.positive_answers), SUM(ua.answer_count)) * 100, 2) AS pct_positive_answers,
  -- Question behavior
  ROUND(AVG(COALESCE(uq.question_count, 0)), 2) AS avg_questions,
  ROUND(SAFE_DIVIDE(SUM(CASE WHEN uq.question_count > 0 THEN 1 ELSE 0 END), COUNT(*)) * 100, 2) AS pct_with_questions,
  ROUND(AVG(CASE WHEN uq.question_count > 0 THEN uq.avg_score_per_question END), 3) AS avg_score_if_questioned,
  -- Activity mix
  ROUND(SAFE_DIVIDE(SUM(COALESCE(ua.answer_count, 0)), SUM(COALESCE(uq.question_count, 0))), 2) AS answer_question_ratio,
  -- Good answer rate (answers scoring 5+)
  ROUND(SAFE_DIVIDE(SUM(ua.good_answers), SUM(ua.answer_count)) * 100, 2) AS pct_good_answers,
  -- Engagement timing
  ROUND(AVG(ru.account_age_days), 0) AS avg_account_age_days,
  ROUND(AVG(CASE WHEN ua.first_answer_date IS NOT NULL
    THEN DATE_DIFF(DATE(ua.first_answer_date), DATE(ru.creation_date), DAY)
    END), 1) AS avg_days_to_first_answer,
  -- Reputation metrics
  SUM(ru.reputation) AS total_reputation,
  ROUND(AVG(ru.reputation), 2) AS avg_reputation,
  ROUND(AVG(SAFE_DIVIDE(ru.reputation, ru.account_age_days)), 4) AS avg_rep_per_day
FROM recent_users ru
LEFT JOIN user_answers ua ON ru.user_id = ua.user_id
LEFT JOIN user_questions uq ON ru.user_id = uq.user_id
GROUP BY ru.growth_category
ORDER BY ru.growth_category DESC
