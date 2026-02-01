/*
 * Query 3: Answer Activity Trends and Comment Engagement Patterns
 *
 * Purpose: Analyze how answer creation has evolved over time and whether
 * comment engagement correlates with higher scores. Comments indicate
 * discussion/clarification which may signal more complex/valuable answers.
 *
 * Focus: Year-over-year trends, comment count vs score correlation
 */

WITH yearly_stats AS (
  SELECT
    EXTRACT(YEAR FROM creation_date) as answer_year,
    COUNT(*) as total_answers,
    SUM(score) as total_score,
    AVG(score) as avg_score,
    APPROX_QUANTILES(score, 100)[OFFSET(50)] as median_score,
    APPROX_QUANTILES(score, 100)[OFFSET(90)] as p90_score,
    APPROX_QUANTILES(score, 100)[OFFSET(99)] as p99_score,
    SUM(CASE WHEN score > 0 THEN 1 ELSE 0 END) as positive_answers,
    SUM(CASE WHEN score >= 10 THEN 1 ELSE 0 END) as high_score_answers,
    AVG(comment_count) as avg_comments,
    SUM(comment_count) as total_comments,
    COUNT(DISTINCT owner_user_id) as unique_answerers
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE EXTRACT(YEAR FROM creation_date) >= 2008
    AND EXTRACT(YEAR FROM creation_date) <= 2024
  GROUP BY answer_year
)
SELECT
  answer_year,
  total_answers,
  total_score,
  ROUND(avg_score, 2) as avg_score,
  median_score,
  p90_score,
  p99_score,
  ROUND(positive_answers * 100.0 / total_answers, 1) as pct_positive,
  ROUND(high_score_answers * 100.0 / total_answers, 2) as pct_high_score,
  unique_answerers,
  ROUND(total_answers * 1.0 / unique_answerers, 1) as answers_per_user,
  ROUND(avg_comments, 2) as avg_comments_per_answer,
  total_comments,
  -- Year over year growth
  ROUND((total_answers - LAG(total_answers) OVER (ORDER BY answer_year)) * 100.0 /
        NULLIF(LAG(total_answers) OVER (ORDER BY answer_year), 0), 1) as yoy_answer_growth_pct
FROM yearly_stats
ORDER BY answer_year
