/*
 * Query 5: Top Tags by Cohort - Which Topics Does Each Cohort Focus On
 *
 * Purpose: Identify the most popular tags answered by each cohort
 * to see if there are topic differences between power users and average users.
 */

WITH user_cohorts AS (
  SELECT
    id as user_id,
    reputation,
    CASE
      WHEN reputation >= 1419 THEN 'power_user_top1pct'
      WHEN reputation BETWEEN 1 AND 100 THEN 'average_user_1_100rep'
      ELSE 'other'
    END as cohort
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1
),

-- Extract individual tags from answers
answer_tags AS (
  SELECT
    a.owner_user_id as user_id,
    a.score as answer_score,
    TRIM(tag) as tag
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q ON a.parent_id = q.id
  CROSS JOIN UNNEST(SPLIT(REPLACE(REPLACE(q.tags, '<', ''), '>', ' '), ' ')) as tag
  WHERE a.owner_user_id IS NOT NULL
    AND q.tags IS NOT NULL
    AND LENGTH(TRIM(tag)) > 0
),

-- Aggregate by cohort and tag
cohort_tag_stats AS (
  SELECT
    c.cohort,
    t.tag,
    COUNT(*) as answer_count,
    AVG(t.answer_score) as avg_score,
    SUM(t.answer_score) as total_score,
    COUNT(DISTINCT t.user_id) as user_count
  FROM user_cohorts c
  JOIN answer_tags t ON c.user_id = t.user_id
  WHERE c.cohort IN ('power_user_top1pct', 'average_user_1_100rep')
  GROUP BY c.cohort, t.tag
),

-- Rank tags within each cohort
ranked_tags AS (
  SELECT
    cohort,
    tag,
    answer_count,
    avg_score,
    total_score,
    user_count,
    ROW_NUMBER() OVER (PARTITION BY cohort ORDER BY answer_count DESC) as rank_by_count
  FROM cohort_tag_stats
)

SELECT
  cohort,
  tag,
  answer_count,
  ROUND(avg_score, 2) as avg_score,
  total_score,
  user_count,
  rank_by_count
FROM ranked_tags
WHERE rank_by_count <= 15
ORDER BY cohort DESC, rank_by_count;
