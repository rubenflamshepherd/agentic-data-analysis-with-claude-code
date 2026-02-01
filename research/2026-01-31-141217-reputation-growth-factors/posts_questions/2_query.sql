/*
 * Query 2: Question Score Distribution and Success Factors
 *
 * Analyzes the distribution of question scores to understand what percentage
 * of questions achieve various score thresholds. Also examines the relationship
 * between engagement metrics (views, answers, accepted answers) and score.
 *
 * This helps understand: What makes a question successful at earning reputation?
 * How do views, answers, and accepting answers correlate with higher scores?
 */
WITH question_stats AS (
  SELECT
    CASE
      WHEN score < 0 THEN 'negative'
      WHEN score = 0 THEN 'zero'
      WHEN score = 1 THEN 'score_1'
      WHEN score BETWEEN 2 AND 4 THEN 'score_2-4'
      WHEN score BETWEEN 5 AND 9 THEN 'score_5-9'
      WHEN score BETWEEN 10 AND 24 THEN 'score_10-24'
      WHEN score BETWEEN 25 AND 49 THEN 'score_25-49'
      WHEN score BETWEEN 50 AND 99 THEN 'score_50-99'
      WHEN score BETWEEN 100 AND 499 THEN 'score_100-499'
      WHEN score >= 500 THEN 'score_500+'
    END AS score_bucket,
    CASE
      WHEN score < 0 THEN 1
      WHEN score = 0 THEN 2
      WHEN score = 1 THEN 3
      WHEN score BETWEEN 2 AND 4 THEN 4
      WHEN score BETWEEN 5 AND 9 THEN 5
      WHEN score BETWEEN 10 AND 24 THEN 6
      WHEN score BETWEEN 25 AND 49 THEN 7
      WHEN score BETWEEN 50 AND 99 THEN 8
      WHEN score BETWEEN 100 AND 499 THEN 9
      WHEN score >= 500 THEN 10
    END AS bucket_order,
    score,
    view_count,
    answer_count,
    CASE WHEN accepted_answer_id IS NOT NULL THEN 1 ELSE 0 END AS has_accepted_answer,
    favorite_count
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
)
SELECT
  score_bucket,
  COUNT(*) AS question_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
  SUM(score) AS total_score_contribution,
  ROUND(SUM(score) * 100.0 / SUM(SUM(score)) OVER(), 2) AS pct_of_total_score,
  ROUND(AVG(view_count), 0) AS avg_views,
  ROUND(AVG(answer_count), 2) AS avg_answers,
  ROUND(AVG(has_accepted_answer) * 100, 2) AS pct_with_accepted_answer,
  ROUND(AVG(favorite_count), 2) AS avg_favorites
FROM question_stats
GROUP BY score_bucket, bucket_order
ORDER BY bucket_order
