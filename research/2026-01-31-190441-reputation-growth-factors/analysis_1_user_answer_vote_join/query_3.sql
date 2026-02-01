/*
 * Query 3: Reputation ROI by Activity Type
 *
 * Purpose: Compare reputation earned per answer vs per question
 * to quantify the ROI of different activity types. This helps
 * answer "what should a new user focus on to grow reputation fastest?"
 *
 * Joins users to both their questions and answers, calculating
 * score per activity and comparing across user tiers.
 */

WITH user_answer_stats AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS answer_count,
    SUM(score) AS answer_score_total,
    COUNTIF(score > 0) AS positive_answers
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_question_stats AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS question_count,
    SUM(score) AS question_score_total,
    COUNTIF(score > 0) AS positive_questions
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_combined AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    CASE
      WHEN u.reputation >= 100000 THEN '6_Elite_100k+'
      WHEN u.reputation >= 10000 THEN '5_Expert_10k-100k'
      WHEN u.reputation >= 1000 THEN '4_Established_1k-10k'
      WHEN u.reputation >= 100 THEN '3_Active_100-1k'
      WHEN u.reputation >= 10 THEN '2_Beginner_10-100'
      ELSE '1_New_1-10'
    END AS reputation_tier,
    COALESCE(a.answer_count, 0) AS answer_count,
    COALESCE(a.answer_score_total, 0) AS answer_score,
    COALESCE(a.positive_answers, 0) AS positive_answers,
    COALESCE(q.question_count, 0) AS question_count,
    COALESCE(q.question_score_total, 0) AS question_score,
    COALESCE(q.positive_questions, 0) AS positive_questions
  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN user_answer_stats a ON u.id = a.user_id
  LEFT JOIN user_question_stats q ON u.id = q.user_id
  WHERE u.reputation >= 1
)

SELECT
  reputation_tier,
  COUNT(*) AS user_count,
  -- Activity counts
  SUM(answer_count) AS total_answers,
  SUM(question_count) AS total_questions,
  ROUND(SAFE_DIVIDE(SUM(answer_count), SUM(question_count)), 2) AS answer_to_question_ratio,
  -- Score per activity (ROI metrics)
  ROUND(SAFE_DIVIDE(SUM(answer_score), SUM(answer_count)), 3) AS score_per_answer,
  ROUND(SAFE_DIVIDE(SUM(question_score), SUM(question_count)), 3) AS score_per_question,
  -- Reputation per activity (estimated)
  -- Answers: +10 per upvote (approximated by score)
  -- Questions: +5 per upvote (approximated by score)
  ROUND(SAFE_DIVIDE(SUM(answer_score) * 10, SUM(answer_count)), 2) AS est_rep_per_answer,
  ROUND(SAFE_DIVIDE(SUM(question_score) * 5, SUM(question_count)), 2) AS est_rep_per_question,
  -- Success rate comparison
  ROUND(SAFE_DIVIDE(SUM(positive_answers), SUM(answer_count)) * 100, 2) AS pct_positive_answers,
  ROUND(SAFE_DIVIDE(SUM(positive_questions), SUM(question_count)) * 100, 2) AS pct_positive_questions,
  -- Total reputation attribution estimate
  SUM(answer_score * 10) AS total_est_rep_from_answers,
  SUM(question_score * 5) AS total_est_rep_from_questions,
  ROUND(SAFE_DIVIDE(SUM(answer_score * 10), SUM(answer_score * 10) + SUM(question_score * 5)) * 100, 2) AS pct_rep_from_answers
FROM user_combined
GROUP BY reputation_tier
ORDER BY reputation_tier DESC
