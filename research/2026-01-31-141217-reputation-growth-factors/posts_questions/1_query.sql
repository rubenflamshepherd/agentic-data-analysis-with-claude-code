/*
 * Query 1: User Question Performance Distribution
 *
 * Analyzes how question scores (which directly contribute to reputation via upvotes)
 * distribute across users. Examines the relationship between question volume,
 * engagement metrics (answers, views, favorites), and score accumulation.
 *
 * This helps understand: Do users who ask more questions earn more reputation?
 * What engagement patterns correlate with higher question scores?
 */
SELECT
  owner_user_id,
  COUNT(*) AS total_questions,
  SUM(score) AS total_score,
  AVG(score) AS avg_score_per_question,
  SUM(view_count) AS total_views,
  AVG(view_count) AS avg_views_per_question,
  SUM(answer_count) AS total_answers_received,
  AVG(answer_count) AS avg_answers_per_question,
  SUM(favorite_count) AS total_favorites,
  COUNTIF(accepted_answer_id IS NOT NULL) AS questions_with_accepted_answer,
  ROUND(SAFE_DIVIDE(COUNTIF(accepted_answer_id IS NOT NULL), COUNT(*)) * 100, 2) AS pct_accepted_answer,
  ROUND(SAFE_DIVIDE(SUM(score), COUNT(*)), 2) AS reputation_efficiency
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE owner_user_id IS NOT NULL
GROUP BY owner_user_id
HAVING COUNT(*) >= 5  -- Focus on users with meaningful question activity
ORDER BY total_score DESC
LIMIT 10000
