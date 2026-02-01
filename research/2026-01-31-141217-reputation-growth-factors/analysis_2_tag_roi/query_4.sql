/*
 * Query 4: Bottom Performers - Tags to Avoid
 *
 * Purpose: Identify tags with poor reputation ROI to help users
 * avoid wasting effort on low-return topics. Also provides
 * actionable guidance by contrasting high vs low ROI.
 *
 * Focus on recent data (2020+) for current relevance.
 */

WITH recent_answers AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    q.id AS question_id,
    q.accepted_answer_id,
    SPLIT(q.tags, '|')[OFFSET(0)] AS primary_tag,
    CASE WHEN a.id = q.accepted_answer_id THEN 1 ELSE 0 END AS is_accepted
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.owner_user_id IS NOT NULL
    AND q.tags IS NOT NULL
    AND q.tags != ''
    AND a.creation_date >= '2020-01-01'
),

tag_metrics AS (
  SELECT
    primary_tag,
    COUNT(*) AS total_answers,
    AVG(answer_score) AS avg_score,
    SAFE_DIVIDE(COUNTIF(answer_score > 0), COUNT(*)) * 100 AS pct_positive,
    SUM(is_accepted) AS accepted_answers,
    SAFE_DIVIDE(SUM(is_accepted), COUNT(*)) * 100 AS acceptance_rate,
    AVG(answer_score * 10 + is_accepted * 15) AS avg_rep_per_answer,
    APPROX_QUANTILES(answer_score, 100)[OFFSET(50)] AS median_score
  FROM recent_answers
  WHERE primary_tag IS NOT NULL
  GROUP BY primary_tag
  HAVING COUNT(*) >= 1000  -- Higher threshold for confidence
)

SELECT
  primary_tag AS tag,
  total_answers,
  ROUND(avg_score, 3) AS avg_score,
  median_score,
  ROUND(pct_positive, 2) AS pct_positive,
  accepted_answers,
  ROUND(acceptance_rate, 2) AS acceptance_rate_pct,
  ROUND(avg_rep_per_answer, 2) AS avg_rep_per_answer,
  'bottom_performer' AS category
FROM tag_metrics
ORDER BY avg_rep_per_answer ASC
LIMIT 50
