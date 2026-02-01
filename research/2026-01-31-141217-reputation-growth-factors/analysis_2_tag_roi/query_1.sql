/*
 * Query 1: Tag Reputation ROI Analysis
 *
 * Purpose: Join posts_answers to posts_questions to get tags for each answer,
 * then calculate reputation metrics per tag including:
 * - Average answer score (reputation ROI proxy)
 * - Total reputation earned (sum of positive scores)
 * - Volume of answers
 * - Percentage of positive answers
 *
 * Tags are stored as pipe-delimited strings like "python|pandas|dataframe",
 * so we extract the first (primary) tag for attribution.
 *
 * Filter: Only include tags with 1000+ answers for statistical significance
 */

WITH answer_with_tags AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    a.owner_user_id,
    a.creation_date AS answer_date,
    q.tags,
    -- Extract primary tag (first tag in the pipe-delimited list)
    SPLIT(q.tags, '|')[OFFSET(0)] AS primary_tag
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.owner_user_id IS NOT NULL
    AND q.tags IS NOT NULL
    AND q.tags != ''
),

tag_metrics AS (
  SELECT
    primary_tag,
    COUNT(*) AS total_answers,
    SUM(answer_score) AS total_score,
    SUM(CASE WHEN answer_score > 0 THEN answer_score ELSE 0 END) AS total_positive_score,
    AVG(answer_score) AS avg_score,
    COUNTIF(answer_score > 0) AS positive_answers,
    COUNTIF(answer_score = 0) AS zero_answers,
    COUNTIF(answer_score < 0) AS negative_answers,
    SAFE_DIVIDE(COUNTIF(answer_score > 0), COUNT(*)) * 100 AS pct_positive,
    SAFE_DIVIDE(COUNTIF(answer_score >= 10), COUNT(*)) * 100 AS pct_high_score,
    APPROX_QUANTILES(answer_score, 100)[OFFSET(50)] AS median_score,
    APPROX_QUANTILES(answer_score, 100)[OFFSET(90)] AS p90_score,
    APPROX_QUANTILES(answer_score, 100)[OFFSET(99)] AS p99_score
  FROM answer_with_tags
  WHERE primary_tag IS NOT NULL
  GROUP BY primary_tag
  HAVING COUNT(*) >= 1000  -- Statistical significance threshold
)

SELECT
  primary_tag AS tag,
  total_answers,
  total_score,
  total_positive_score,
  ROUND(avg_score, 3) AS avg_score,
  median_score,
  p90_score,
  p99_score,
  ROUND(pct_positive, 2) AS pct_positive,
  ROUND(pct_high_score, 2) AS pct_high_score_10plus,
  positive_answers,
  zero_answers,
  negative_answers,
  -- Reputation ROI rank
  RANK() OVER (ORDER BY avg_score DESC) AS roi_rank
FROM tag_metrics
ORDER BY avg_score DESC
LIMIT 500
