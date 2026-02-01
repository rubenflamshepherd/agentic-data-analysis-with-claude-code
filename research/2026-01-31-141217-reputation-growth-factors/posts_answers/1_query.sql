/*
 * Query 1: Answer Score Distribution and User Productivity Analysis
 *
 * Purpose: Understand the distribution of answer scores and how they relate to
 * user productivity (number of answers posted). This helps identify what
 * factors drive reputation growth - is it volume of answers or quality?
 *
 * Key metrics:
 * - Distribution of scores across all answers
 * - Relationship between user answer count and average score
 * - Score percentiles to understand the long tail
 */

WITH user_answer_stats AS (
  SELECT
    owner_user_id,
    COUNT(*) as total_answers,
    SUM(score) as total_score,
    AVG(score) as avg_score,
    MAX(score) as max_score,
    COUNTIF(score > 0) as positive_answers,
    COUNTIF(score = 0) as zero_score_answers,
    COUNTIF(score < 0) as negative_answers
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),
user_buckets AS (
  SELECT
    CASE
      WHEN total_answers = 1 THEN '1_answer'
      WHEN total_answers BETWEEN 2 AND 5 THEN '2-5_answers'
      WHEN total_answers BETWEEN 6 AND 10 THEN '6-10_answers'
      WHEN total_answers BETWEEN 11 AND 50 THEN '11-50_answers'
      WHEN total_answers BETWEEN 51 AND 100 THEN '51-100_answers'
      WHEN total_answers BETWEEN 101 AND 500 THEN '101-500_answers'
      WHEN total_answers > 500 THEN '500+_answers'
    END as answer_bucket,
    total_answers,
    total_score,
    avg_score,
    max_score,
    positive_answers,
    zero_score_answers,
    negative_answers
  FROM user_answer_stats
)
SELECT
  answer_bucket,
  COUNT(*) as user_count,
  SUM(total_answers) as total_answers_in_bucket,
  ROUND(AVG(total_score), 2) as avg_total_score_per_user,
  ROUND(AVG(avg_score), 2) as avg_score_per_answer,
  ROUND(AVG(max_score), 2) as avg_max_score,
  ROUND(AVG(SAFE_DIVIDE(positive_answers, total_answers) * 100), 2) as avg_pct_positive_answers,
  ROUND(AVG(SAFE_DIVIDE(zero_score_answers, total_answers) * 100), 2) as avg_pct_zero_score,
  ROUND(AVG(SAFE_DIVIDE(negative_answers, total_answers) * 100), 2) as avg_pct_negative_answers
FROM user_buckets
GROUP BY answer_bucket
ORDER BY
  CASE answer_bucket
    WHEN '1_answer' THEN 1
    WHEN '2-5_answers' THEN 2
    WHEN '6-10_answers' THEN 3
    WHEN '11-50_answers' THEN 4
    WHEN '51-100_answers' THEN 5
    WHEN '101-500_answers' THEN 6
    WHEN '500+_answers' THEN 7
  END
