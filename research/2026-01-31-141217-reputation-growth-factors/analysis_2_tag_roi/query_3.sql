/*
 * Query 3: Recent Tag Performance Analysis (2020-2024)
 *
 * Purpose: Focus on recent data to provide actionable guidance for
 * current reputation growth strategies. Includes analysis of:
 * - Recent average scores (what's working NOW)
 * - Accepted answer rates (additional +15 rep per accepted answer)
 * - Competition (answers per question ratio)
 * - Opportunity (questions still needing answers)
 *
 * Filter: Only 2020+ data for current relevance
 */

WITH recent_answers AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    a.owner_user_id,
    a.creation_date AS answer_date,
    q.id AS question_id,
    q.tags,
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
    SUM(answer_score) AS total_score,
    AVG(answer_score) AS avg_score,
    SAFE_DIVIDE(COUNTIF(answer_score > 0), COUNT(*)) * 100 AS pct_positive,
    SAFE_DIVIDE(COUNTIF(answer_score >= 5), COUNT(*)) * 100 AS pct_score_5plus,
    -- Acceptance metrics (key for reputation: +15 bonus)
    SUM(is_accepted) AS accepted_answers,
    SAFE_DIVIDE(SUM(is_accepted), COUNT(*)) * 100 AS acceptance_rate,
    -- Unique questions answered
    COUNT(DISTINCT question_id) AS questions_answered,
    -- Estimated total reputation per answer (score*10 + acceptance*15)
    AVG(answer_score * 10 + is_accepted * 15) AS avg_rep_per_answer,
    -- Percentiles
    APPROX_QUANTILES(answer_score, 100)[OFFSET(50)] AS median_score,
    APPROX_QUANTILES(answer_score, 100)[OFFSET(75)] AS p75_score,
    APPROX_QUANTILES(answer_score, 100)[OFFSET(90)] AS p90_score
  FROM recent_answers
  WHERE primary_tag IS NOT NULL
  GROUP BY primary_tag
  HAVING COUNT(*) >= 500
)

SELECT
  primary_tag AS tag,
  total_answers,
  questions_answered,
  ROUND(total_answers / questions_answered, 2) AS competition_ratio,
  total_score,
  ROUND(avg_score, 3) AS avg_score,
  median_score,
  p75_score,
  p90_score,
  ROUND(pct_positive, 2) AS pct_positive,
  ROUND(pct_score_5plus, 2) AS pct_score_5plus,
  accepted_answers,
  ROUND(acceptance_rate, 2) AS acceptance_rate_pct,
  ROUND(avg_rep_per_answer, 2) AS avg_rep_per_answer,
  -- Overall opportunity score: balance of ROI, acceptance, and manageable competition
  ROUND(
    avg_rep_per_answer *
    (CASE WHEN total_answers / questions_answered < 2 THEN 1.3 ELSE 1.0 END) *
    (CASE WHEN acceptance_rate > 20 THEN 1.2 ELSE 1.0 END),
    2
  ) AS recent_opportunity_score
FROM tag_metrics
ORDER BY avg_rep_per_answer DESC
LIMIT 100
