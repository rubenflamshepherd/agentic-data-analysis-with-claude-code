/*
 * Query 1: Answer Score Distribution and User Activity Patterns
 *
 * Purpose: Understand the distribution of answer scores and how prolific
 * answerers (by volume) perform in terms of reputation-driving metrics.
 * This helps identify if quantity or quality of answers drives reputation.
 *
 * Focus: Score distribution, user activity levels, and score per answer patterns
 */

WITH user_answer_stats AS (
  SELECT
    owner_user_id,
    COUNT(*) as total_answers,
    SUM(score) as total_score,
    AVG(score) as avg_score_per_answer,
    SUM(CASE WHEN score > 0 THEN 1 ELSE 0 END) as positive_score_answers,
    SUM(CASE WHEN score = 0 THEN 1 ELSE 0 END) as zero_score_answers,
    SUM(CASE WHEN score < 0 THEN 1 ELSE 0 END) as negative_score_answers,
    MAX(score) as max_answer_score,
    MIN(score) as min_answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),
user_activity_buckets AS (
  SELECT
    *,
    CASE
      WHEN total_answers >= 1000 THEN '1000+ answers'
      WHEN total_answers >= 100 THEN '100-999 answers'
      WHEN total_answers >= 10 THEN '10-99 answers'
      WHEN total_answers >= 2 THEN '2-9 answers'
      ELSE '1 answer'
    END as activity_bucket,
    CASE
      WHEN total_answers >= 1000 THEN 5
      WHEN total_answers >= 100 THEN 4
      WHEN total_answers >= 10 THEN 3
      WHEN total_answers >= 2 THEN 2
      ELSE 1
    END as bucket_order
  FROM user_answer_stats
)
SELECT
  activity_bucket,
  COUNT(*) as user_count,
  SUM(total_answers) as total_answers_in_bucket,
  SUM(total_score) as total_score_in_bucket,
  ROUND(AVG(avg_score_per_answer), 2) as avg_score_per_answer,
  ROUND(AVG(total_score), 1) as avg_total_score_per_user,
  ROUND(SUM(positive_score_answers) * 100.0 / SUM(total_answers), 1) as pct_positive_answers,
  ROUND(SUM(zero_score_answers) * 100.0 / SUM(total_answers), 1) as pct_zero_answers,
  ROUND(SUM(negative_score_answers) * 100.0 / SUM(total_answers), 1) as pct_negative_answers,
  MAX(max_answer_score) as highest_single_answer_score
FROM user_activity_buckets
GROUP BY activity_bucket, bucket_order
ORDER BY bucket_order DESC
