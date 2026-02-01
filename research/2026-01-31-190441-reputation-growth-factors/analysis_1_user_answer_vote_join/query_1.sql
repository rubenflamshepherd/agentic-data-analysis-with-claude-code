/*
 * Query 1: User-Answer Join - Reputation Earned from Answers
 *
 * Purpose: Join users to their answers to calculate actual reputation earned
 * from answer upvotes. This directly addresses the gap identified in initial
 * analysis: correlating individual user activities to reputation.
 *
 * Reputation mechanics:
 * - Answer upvote: +10 rep (vote_type_id = 2)
 * - Answer downvote: -2 rep (vote_type_id = 3)
 * - Accepted answer: +15 rep (vote_type_id = 1)
 *
 * We bucket users by reputation tier and analyze their answer-based earnings.
 */

WITH user_answer_stats AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    u.creation_date AS user_creation_date,
    COUNT(a.id) AS total_answers,
    SUM(a.score) AS total_answer_score,
    COUNTIF(a.score > 0) AS positive_answers,
    COUNTIF(a.score = 0) AS zero_score_answers,
    COUNTIF(a.score < 0) AS negative_answers,
    -- Reputation from answer score (upvotes give +10, downvotes give -2)
    -- Net score approximation: each net +1 score = approximately +8 rep (one upvote minus fraction of downvote)
    -- More accurate: positive score * 10 for upvotes, negative portion * 2 for downvotes
    SUM(CASE WHEN a.score > 0 THEN a.score * 10 ELSE 0 END) AS estimated_rep_from_upvotes,
    SUM(CASE WHEN a.score < 0 THEN ABS(a.score) * 2 ELSE 0 END) AS estimated_rep_lost_from_downvotes
  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON u.id = a.owner_user_id
  WHERE u.reputation >= 1
  GROUP BY u.id, u.reputation, u.creation_date
),

user_tiers AS (
  SELECT
    *,
    CASE
      WHEN reputation >= 100000 THEN '6_Elite_100k+'
      WHEN reputation >= 10000 THEN '5_Expert_10k-100k'
      WHEN reputation >= 1000 THEN '4_Established_1k-10k'
      WHEN reputation >= 100 THEN '3_Active_100-1k'
      WHEN reputation >= 10 THEN '2_Beginner_10-100'
      ELSE '1_New_1-10'
    END AS reputation_tier
  FROM user_answer_stats
)

SELECT
  reputation_tier,
  COUNT(*) AS user_count,
  -- Answer activity metrics
  ROUND(AVG(total_answers), 2) AS avg_answers_per_user,
  SUM(total_answers) AS total_answers_in_tier,
  -- Score metrics
  ROUND(AVG(total_answer_score), 2) AS avg_total_score_per_user,
  SUM(total_answer_score) AS total_score_in_tier,
  -- Answer quality breakdown
  ROUND(SAFE_DIVIDE(SUM(positive_answers), SUM(total_answers)) * 100, 2) AS pct_positive_answers,
  ROUND(SAFE_DIVIDE(SUM(negative_answers), SUM(total_answers)) * 100, 2) AS pct_negative_answers,
  -- Estimated reputation from answers
  SUM(estimated_rep_from_upvotes) AS total_est_rep_from_upvotes,
  SUM(estimated_rep_lost_from_downvotes) AS total_est_rep_lost_from_downvotes,
  SUM(estimated_rep_from_upvotes) - SUM(estimated_rep_lost_from_downvotes) AS net_est_rep_from_answers,
  -- Compare to actual reputation
  SUM(reputation) AS total_actual_reputation,
  ROUND(SAFE_DIVIDE(
    SUM(estimated_rep_from_upvotes) - SUM(estimated_rep_lost_from_downvotes),
    SUM(reputation)
  ) * 100, 2) AS answers_pct_of_total_rep
FROM user_tiers
GROUP BY reputation_tier
ORDER BY reputation_tier DESC
