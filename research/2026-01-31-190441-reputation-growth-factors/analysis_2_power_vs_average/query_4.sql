/*
 * Query 4: Topic Specialization Analysis - Tag Focus by Cohort
 *
 * Purpose: Compare which tags/topics each cohort focuses on.
 * Analyze if power users are more specialized or more diversified.
 *
 * Analysis:
 * - Top tags answered by each cohort
 * - Average number of distinct tags per user
 * - Tag concentration (are power users generalists or specialists?)
 */

WITH user_cohorts AS (
  SELECT
    id as user_id,
    reputation,
    CASE
      WHEN reputation >= 1419 THEN 'power_user_top1pct'  -- Using threshold from query 1
      WHEN reputation BETWEEN 1 AND 100 THEN 'average_user_1_100rep'
      ELSE 'other'
    END as cohort
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1
),

-- Extract individual tags from answers (tags are stored on the question)
answer_tags AS (
  SELECT
    a.owner_user_id as user_id,
    a.id as answer_id,
    a.score as answer_score,
    TRIM(tag) as tag
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q ON a.parent_id = q.id
  CROSS JOIN UNNEST(SPLIT(REPLACE(REPLACE(q.tags, '<', ''), '>', ' '), ' ')) as tag
  WHERE a.owner_user_id IS NOT NULL
    AND q.tags IS NOT NULL
    AND LENGTH(TRIM(tag)) > 0
),

-- User-level tag diversity metrics
user_tag_diversity AS (
  SELECT
    user_id,
    COUNT(DISTINCT tag) as distinct_tags,
    COUNT(*) as total_tag_answers,
    SAFE_DIVIDE(COUNT(DISTINCT tag), COUNT(*)) as tag_diversity_ratio
  FROM answer_tags
  GROUP BY user_id
),

-- Top tag per user (specialization)
user_top_tag AS (
  SELECT
    user_id,
    tag as top_tag,
    tag_answers,
    tag_score
  FROM (
    SELECT
      user_id,
      tag,
      COUNT(*) as tag_answers,
      SUM(answer_score) as tag_score,
      ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY COUNT(*) DESC) as rn
    FROM answer_tags
    GROUP BY user_id, tag
  )
  WHERE rn = 1
),

-- Concentration of answers in top tag
user_concentration AS (
  SELECT
    t.user_id,
    t.top_tag,
    t.tag_answers as top_tag_answers,
    d.total_tag_answers,
    SAFE_DIVIDE(t.tag_answers, d.total_tag_answers) as top_tag_concentration
  FROM user_top_tag t
  JOIN user_tag_diversity d ON t.user_id = d.user_id
)

SELECT
  c.cohort,
  COUNT(DISTINCT c.user_id) as users_with_answers,
  -- Tag diversity
  ROUND(AVG(d.distinct_tags), 2) as avg_distinct_tags_per_user,
  ROUND(AVG(d.total_tag_answers), 2) as avg_tag_answers_per_user,
  -- Specialization metrics
  ROUND(AVG(con.top_tag_concentration) * 100, 2) as avg_top_tag_concentration_pct,
  -- Distribution of tag focus
  ROUND(SAFE_DIVIDE(COUNTIF(d.distinct_tags = 1), COUNT(*)) * 100, 2) as pct_single_tag_users,
  ROUND(SAFE_DIVIDE(COUNTIF(d.distinct_tags >= 10), COUNT(*)) * 100, 2) as pct_10plus_tag_users,
  ROUND(SAFE_DIVIDE(COUNTIF(d.distinct_tags >= 50), COUNT(*)) * 100, 2) as pct_50plus_tag_users
FROM user_cohorts c
JOIN user_tag_diversity d ON c.user_id = d.user_id
LEFT JOIN user_concentration con ON c.user_id = con.user_id
WHERE c.cohort IN ('power_user_top1pct', 'average_user_1_100rep')
GROUP BY c.cohort
ORDER BY avg_distinct_tags_per_user DESC;
