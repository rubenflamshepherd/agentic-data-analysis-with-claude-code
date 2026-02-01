/*
 * Query 3: Tag Popularity and Reputation Potential by Topic Area
 *
 * Analyzes which technology tags are associated with higher average question
 * scores. This helps identify which topic areas offer better reputation
 * growth opportunities for question askers.
 *
 * Focus: Top 75 most popular tags by question volume, comparing their
 * average scores, view counts, and engagement metrics.
 */
WITH tag_extracted AS (
  SELECT
    SPLIT(tags, '|')[SAFE_OFFSET(0)] AS primary_tag,
    score,
    view_count,
    answer_count,
    CASE WHEN accepted_answer_id IS NOT NULL THEN 1 ELSE 0 END AS has_accepted_answer,
    favorite_count
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
    AND tags IS NOT NULL
),
tag_stats AS (
  SELECT
    primary_tag,
    COUNT(*) AS question_count,
    SUM(score) AS total_score,
    AVG(score) AS avg_score,
    AVG(view_count) AS avg_views,
    AVG(answer_count) AS avg_answers,
    AVG(has_accepted_answer) * 100 AS pct_accepted_answer,
    AVG(favorite_count) AS avg_favorites,
    COUNTIF(score >= 10) AS high_score_questions,
    COUNTIF(score >= 10) * 100.0 / COUNT(*) AS pct_high_score
  FROM tag_extracted
  WHERE primary_tag IS NOT NULL
  GROUP BY primary_tag
  HAVING COUNT(*) >= 10000  -- Focus on popular tags
)
SELECT
  primary_tag,
  question_count,
  total_score,
  ROUND(avg_score, 2) AS avg_score,
  ROUND(avg_views, 0) AS avg_views,
  ROUND(avg_answers, 2) AS avg_answers,
  ROUND(pct_accepted_answer, 2) AS pct_accepted_answer,
  ROUND(avg_favorites, 2) AS avg_favorites,
  high_score_questions,
  ROUND(pct_high_score, 2) AS pct_high_score
FROM tag_stats
ORDER BY question_count DESC
LIMIT 75
