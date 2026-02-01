/*
 * Query 3: Pareto Analysis - What Percentage of Users Drive Reputation
 *
 * Purpose: Understand the concentration of reputation - do the top users
 * earn a disproportionate share of scores? This helps identify if
 * reputation growth is achievable for average users or concentrated
 * among a small elite.
 *
 * Key metrics:
 * - Score distribution across user percentiles
 * - Concentration of total score among top users
 * - Characteristics of top performers vs average users
 */

WITH user_scores AS (
  SELECT
    owner_user_id,
    COUNT(*) as answer_count,
    SUM(score) as total_score,
    AVG(score) as avg_score,
    MAX(score) as max_score,
    MIN(EXTRACT(YEAR FROM creation_date)) as first_answer_year
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),
ranked_users AS (
  SELECT
    *,
    NTILE(100) OVER (ORDER BY total_score DESC) as score_percentile
  FROM user_scores
),
percentile_stats AS (
  SELECT
    score_percentile,
    COUNT(*) as user_count,
    SUM(answer_count) as total_answers,
    SUM(total_score) as total_score_in_percentile,
    ROUND(AVG(answer_count), 2) as avg_answers_per_user,
    ROUND(AVG(total_score), 2) as avg_score_per_user,
    ROUND(AVG(avg_score), 2) as avg_score_per_answer,
    ROUND(AVG(max_score), 2) as avg_max_score,
    ROUND(AVG(first_answer_year), 1) as avg_first_year
  FROM ranked_users
  GROUP BY score_percentile
)
SELECT
  score_percentile,
  user_count,
  total_answers,
  total_score_in_percentile,
  avg_answers_per_user,
  avg_score_per_user,
  avg_score_per_answer,
  avg_max_score,
  avg_first_year,
  ROUND(total_score_in_percentile * 100.0 / SUM(total_score_in_percentile) OVER (), 2) as pct_of_total_score,
  ROUND(SUM(total_score_in_percentile) OVER (ORDER BY score_percentile) * 100.0 / SUM(total_score_in_percentile) OVER (), 2) as cumulative_pct_score
FROM percentile_stats
WHERE score_percentile <= 20  -- Focus on top 20% to see concentration
   OR score_percentile IN (25, 50, 75, 90, 95, 99, 100)  -- Plus key percentiles
ORDER BY score_percentile
