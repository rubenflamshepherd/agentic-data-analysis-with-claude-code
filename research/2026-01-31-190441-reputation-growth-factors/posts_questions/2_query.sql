/*
 * Query 2: Top Tags by Question Performance and Reputation Potential
 *
 * Purpose: Identify which technology tags are associated with higher question scores
 * and better engagement. Users asking questions in high-performing tags may have
 * better reputation growth opportunities.
 *
 * Analyzes the top 25 most popular tags by volume and their associated metrics.
 *
 * Note: Table data ends at 2022-09-25, analyzing last 365 days of available data.
 * Tags are pipe-delimited (e.g., "python|pandas|dataframe")
 */

WITH tag_stats AS (
  SELECT
    -- Extract the first tag (primary tag) from the pipe-delimited tags field
    SPLIT(tags, '|')[SAFE_OFFSET(0)] AS primary_tag,
    score,
    view_count,
    answer_count,
    CASE WHEN accepted_answer_id IS NOT NULL THEN 1 ELSE 0 END AS has_accepted
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2021-09-25'
    AND creation_date < '2022-09-25'
    AND tags IS NOT NULL
)

SELECT
  primary_tag,
  COUNT(*) AS question_count,
  ROUND(AVG(score), 2) AS avg_score,
  SUM(CASE WHEN score > 0 THEN 1 ELSE 0 END) AS positive_score_count,
  ROUND(SUM(CASE WHEN score > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_positive,
  SUM(CASE WHEN score >= 5 THEN 1 ELSE 0 END) AS high_score_count,
  ROUND(SUM(CASE WHEN score >= 5 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_high_score,
  ROUND(AVG(view_count), 0) AS avg_views,
  ROUND(AVG(answer_count), 2) AS avg_answers,
  ROUND(SUM(has_accepted) * 100.0 / COUNT(*), 2) AS pct_accepted
FROM tag_stats
WHERE primary_tag IS NOT NULL
GROUP BY primary_tag
HAVING COUNT(*) >= 1000
ORDER BY question_count DESC
LIMIT 25
