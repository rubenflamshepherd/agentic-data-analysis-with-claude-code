/*
 * Query 2: Same-Era Answer Performance - Controlling for Time Period
 *
 * To isolate whether early adopters have an inherent skill/quality advantage
 * vs simply benefiting from answering in a "golden era" of higher scores,
 * we compare answer performance during the same time window (2018-2022)
 * for both cohorts.
 *
 * This controls for platform-wide score deflation and tests:
 * "Do early adopters still earn higher scores per answer even when answering
 *  in the same era as late joiners?"
 */

WITH user_cohorts AS (
  SELECT
    id AS user_id,
    CASE
      WHEN EXTRACT(YEAR FROM creation_date) BETWEEN 2008 AND 2012 THEN 'Early (2008-2012)'
      WHEN EXTRACT(YEAR FROM creation_date) BETWEEN 2018 AND 2022 THEN 'Late (2018-2022)'
      ELSE 'Other'
    END AS cohort
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE EXTRACT(YEAR FROM creation_date) BETWEEN 2008 AND 2012
     OR EXTRACT(YEAR FROM creation_date) BETWEEN 2018 AND 2022
),

-- Get answers posted ONLY in 2018-2022 for both cohorts
same_era_answers AS (
  SELECT
    a.owner_user_id,
    c.cohort,
    COUNT(*) AS answer_count_2018_2022,
    SUM(a.score) AS total_score_2018_2022,
    AVG(a.score) AS avg_score_2018_2022,
    COUNTIF(a.score > 0) AS positive_answers,
    COUNTIF(a.score = 0) AS zero_answers,
    COUNTIF(a.score < 0) AS negative_answers
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN user_cohorts c ON a.owner_user_id = c.user_id
  WHERE EXTRACT(YEAR FROM a.creation_date) BETWEEN 2018 AND 2022
    AND a.owner_user_id IS NOT NULL
  GROUP BY a.owner_user_id, c.cohort
),

-- Bucket by activity level during this period
with_buckets AS (
  SELECT
    *,
    CASE
      WHEN answer_count_2018_2022 BETWEEN 1 AND 5 THEN '1_1-5'
      WHEN answer_count_2018_2022 BETWEEN 6 AND 20 THEN '2_6-20'
      WHEN answer_count_2018_2022 BETWEEN 21 AND 100 THEN '3_21-100'
      WHEN answer_count_2018_2022 > 100 THEN '4_100+'
      ELSE '0_none'
    END AS activity_bucket_2018_2022
  FROM same_era_answers
)

SELECT
  cohort,
  activity_bucket_2018_2022,
  COUNT(*) AS users_active_2018_2022,
  SUM(answer_count_2018_2022) AS total_answers,
  ROUND(AVG(answer_count_2018_2022), 1) AS avg_answers_per_user,
  -- Score efficiency in same era
  ROUND(AVG(avg_score_2018_2022), 3) AS avg_user_score_per_answer,
  ROUND(SUM(total_score_2018_2022) * 1.0 / SUM(answer_count_2018_2022), 3) AS cohort_score_per_answer,
  -- Answer quality distribution
  ROUND(100.0 * SUM(positive_answers) / SUM(answer_count_2018_2022), 1) AS pct_positive,
  ROUND(100.0 * SUM(zero_answers) / SUM(answer_count_2018_2022), 1) AS pct_zero,
  ROUND(100.0 * SUM(negative_answers) / SUM(answer_count_2018_2022), 1) AS pct_negative
FROM with_buckets
GROUP BY cohort, activity_bucket_2018_2022
ORDER BY cohort, activity_bucket_2018_2022
