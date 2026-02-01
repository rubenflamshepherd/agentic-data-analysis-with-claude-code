/*
 * Query 2: Tag ROI vs Popularity Matrix
 *
 * Purpose: Cross-reference reputation ROI with tag popularity to identify
 * "sweet spot" opportunities - tags with high ROI that aren't oversaturated.
 *
 * We create volume tiers and ROI tiers to find the intersection of:
 * - Good reputation return (high avg score per answer)
 * - Reasonable competition (not too many answers already)
 * - Sufficient opportunity (enough questions being asked)
 *
 * Strategy: Classify tags into popularity tiers and ROI tiers,
 * then identify underrated gems (high ROI + medium popularity)
 */

WITH answer_with_tags AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    a.creation_date AS answer_date,
    q.tags,
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
    AVG(answer_score) AS avg_score,
    SAFE_DIVIDE(COUNTIF(answer_score > 0), COUNT(*)) * 100 AS pct_positive,
    SUM(answer_score) AS total_score,
    -- Recent activity (answers in last 3 years)
    COUNTIF(answer_date >= '2020-01-01') AS recent_answers,
    -- Recent avg score (to check if opportunity is still good)
    AVG(CASE WHEN answer_date >= '2020-01-01' THEN answer_score END) AS recent_avg_score
  FROM answer_with_tags
  WHERE primary_tag IS NOT NULL
  GROUP BY primary_tag
  HAVING COUNT(*) >= 500  -- Lower threshold to capture more tags
),

classified_tags AS (
  SELECT
    *,
    -- Volume tier classification
    CASE
      WHEN total_answers >= 100000 THEN '1_mega (100K+)'
      WHEN total_answers >= 30000 THEN '2_large (30K-100K)'
      WHEN total_answers >= 10000 THEN '3_medium (10K-30K)'
      WHEN total_answers >= 3000 THEN '4_small (3K-10K)'
      ELSE '5_niche (500-3K)'
    END AS volume_tier,
    -- ROI tier classification based on avg score
    CASE
      WHEN avg_score >= 5.0 THEN 'A_high_roi (5+)'
      WHEN avg_score >= 3.0 THEN 'B_medium_roi (3-5)'
      WHEN avg_score >= 2.0 THEN 'C_low_roi (2-3)'
      ELSE 'D_poor_roi (<2)'
    END AS roi_tier,
    -- Recent trend indicator
    CASE
      WHEN recent_avg_score > avg_score * 1.1 THEN 'improving'
      WHEN recent_avg_score < avg_score * 0.7 THEN 'declining'
      ELSE 'stable'
    END AS recent_trend
  FROM tag_metrics
)

SELECT
  primary_tag AS tag,
  volume_tier,
  roi_tier,
  total_answers,
  total_score,
  ROUND(avg_score, 3) AS avg_score,
  ROUND(pct_positive, 2) AS pct_positive,
  recent_answers,
  ROUND(recent_avg_score, 3) AS recent_avg_score,
  recent_trend,
  -- Opportunity score: higher is better (good ROI + not oversaturated + still active)
  ROUND(
    avg_score *
    (CASE WHEN total_answers < 50000 THEN 1.5 ELSE 1.0 END) *
    (CASE WHEN recent_answers > 1000 THEN 1.2 ELSE 1.0 END),
    2
  ) AS opportunity_score
FROM classified_tags
ORDER BY
  CASE
    WHEN volume_tier = '3_medium (10K-30K)' AND roi_tier IN ('A_high_roi (5+)', 'B_medium_roi (3-5)') THEN 1
    WHEN volume_tier = '4_small (3K-10K)' AND roi_tier = 'A_high_roi (5+)' THEN 2
    ELSE 3
  END,
  avg_score DESC
LIMIT 200
