/*
 * Query 2: Answer Score Trends Over Time (Yearly)
 *
 * Purpose: Examine how answer scores have changed over time to understand
 * if reputation growth opportunities have changed. Older answers may accumulate
 * more upvotes, or the platform dynamics may have shifted.
 *
 * Key metrics:
 * - Average score by year of creation
 * - Total answers and users per year
 * - Distribution of scores (positive, zero, negative) by year
 */

SELECT
  EXTRACT(YEAR FROM creation_date) as creation_year,
  COUNT(*) as total_answers,
  COUNT(DISTINCT owner_user_id) as unique_answerers,
  ROUND(AVG(score), 2) as avg_score,
  ROUND(APPROX_QUANTILES(score, 100)[OFFSET(50)], 2) as median_score,
  ROUND(APPROX_QUANTILES(score, 100)[OFFSET(90)], 2) as p90_score,
  ROUND(APPROX_QUANTILES(score, 100)[OFFSET(99)], 2) as p99_score,
  SUM(score) as total_score,
  ROUND(COUNTIF(score > 0) * 100.0 / COUNT(*), 2) as pct_positive,
  ROUND(COUNTIF(score = 0) * 100.0 / COUNT(*), 2) as pct_zero,
  ROUND(COUNTIF(score < 0) * 100.0 / COUNT(*), 2) as pct_negative,
  ROUND(AVG(comment_count), 2) as avg_comment_count
FROM `bigquery-public-data.stackoverflow.posts_answers`
WHERE creation_date IS NOT NULL
  AND EXTRACT(YEAR FROM creation_date) >= 2008
  AND EXTRACT(YEAR FROM creation_date) <= 2024
GROUP BY creation_year
ORDER BY creation_year
