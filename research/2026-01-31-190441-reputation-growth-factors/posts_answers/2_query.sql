/*
 * Query 2: Answer Score Distribution and Reputation Impact Analysis
 *
 * Purpose: Understand the distribution of individual answer scores to see
 * what score ranges are most common and how reputation accumulates.
 * On Stack Overflow, each upvote on an answer = +10 reputation.
 *
 * Focus: Score buckets, cumulative reputation contribution, percentile analysis
 */

WITH score_buckets AS (
  SELECT
    CASE
      WHEN score < 0 THEN 'Negative (<0)'
      WHEN score = 0 THEN 'Zero (0)'
      WHEN score = 1 THEN 'Low (1)'
      WHEN score BETWEEN 2 AND 5 THEN 'Moderate (2-5)'
      WHEN score BETWEEN 6 AND 10 THEN 'Good (6-10)'
      WHEN score BETWEEN 11 AND 25 THEN 'High (11-25)'
      WHEN score BETWEEN 26 AND 100 THEN 'Very High (26-100)'
      WHEN score BETWEEN 101 AND 500 THEN 'Exceptional (101-500)'
      ELSE 'Legendary (500+)'
    END as score_bucket,
    CASE
      WHEN score < 0 THEN 1
      WHEN score = 0 THEN 2
      WHEN score = 1 THEN 3
      WHEN score BETWEEN 2 AND 5 THEN 4
      WHEN score BETWEEN 6 AND 10 THEN 5
      WHEN score BETWEEN 11 AND 25 THEN 6
      WHEN score BETWEEN 26 AND 100 THEN 7
      WHEN score BETWEEN 101 AND 500 THEN 8
      ELSE 9
    END as bucket_order,
    score,
    1 as answer_count
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
bucket_stats AS (
  SELECT
    score_bucket,
    bucket_order,
    COUNT(*) as answer_count,
    SUM(score) as total_score,
    AVG(score) as avg_score,
    MIN(score) as min_score,
    MAX(score) as max_score
  FROM score_buckets
  GROUP BY score_bucket, bucket_order
),
totals AS (
  SELECT
    SUM(answer_count) as total_answers,
    SUM(total_score) as grand_total_score
  FROM bucket_stats
)
SELECT
  b.score_bucket,
  b.answer_count,
  ROUND(b.answer_count * 100.0 / t.total_answers, 2) as pct_of_answers,
  b.total_score,
  ROUND(b.total_score * 100.0 / t.grand_total_score, 2) as pct_of_total_score,
  ROUND(b.avg_score, 2) as avg_score_in_bucket,
  b.min_score,
  b.max_score,
  -- Reputation impact (10 rep per upvote on answers)
  b.total_score * 10 as estimated_reputation_generated
FROM bucket_stats b
CROSS JOIN totals t
ORDER BY b.bucket_order
