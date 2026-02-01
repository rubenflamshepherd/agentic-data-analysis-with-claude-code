/*
 * Query 2: Vote Type Breakdown by User Tier
 *
 * Purpose: Join users -> answers -> votes to calculate actual reputation
 * earned from each vote type (upvotes, downvotes, accepted answers).
 * This gives precise reputation attribution by source.
 *
 * Vote type IDs:
 * - 1: Accepted Answer (+15 rep to answerer)
 * - 2: Upvote (+10 rep)
 * - 3: Downvote (-2 rep to recipient)
 *
 * We use a sample of recent votes (last year of data) to keep query efficient.
 */

WITH user_tiers AS (
  SELECT
    id AS user_id,
    reputation,
    CASE
      WHEN reputation >= 100000 THEN '6_Elite_100k+'
      WHEN reputation >= 10000 THEN '5_Expert_10k-100k'
      WHEN reputation >= 1000 THEN '4_Established_1k-10k'
      WHEN reputation >= 100 THEN '3_Active_100-1k'
      WHEN reputation >= 10 THEN '2_Beginner_10-100'
      ELSE '1_New_1-10'
    END AS reputation_tier
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1
),

answer_votes AS (
  SELECT
    a.owner_user_id,
    v.vote_type_id,
    COUNT(*) AS vote_count,
    -- Calculate reputation impact
    CASE
      WHEN v.vote_type_id = 1 THEN COUNT(*) * 15  -- Accepted answer
      WHEN v.vote_type_id = 2 THEN COUNT(*) * 10  -- Upvote
      WHEN v.vote_type_id = 3 THEN COUNT(*) * -2  -- Downvote
      ELSE 0
    END AS rep_impact
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.votes` v
    ON a.id = v.post_id
  WHERE v.vote_type_id IN (1, 2, 3)  -- Only reputation-affecting votes
    AND v.creation_date >= '2021-09-01'  -- Last year of data
    AND v.creation_date < '2022-09-25'
  GROUP BY a.owner_user_id, v.vote_type_id
)

SELECT
  t.reputation_tier,
  COUNT(DISTINCT t.user_id) AS users_in_tier,
  -- Upvote stats
  SUM(CASE WHEN av.vote_type_id = 2 THEN av.vote_count ELSE 0 END) AS total_upvotes_received,
  SUM(CASE WHEN av.vote_type_id = 2 THEN av.rep_impact ELSE 0 END) AS rep_from_upvotes,
  -- Downvote stats
  SUM(CASE WHEN av.vote_type_id = 3 THEN av.vote_count ELSE 0 END) AS total_downvotes_received,
  SUM(CASE WHEN av.vote_type_id = 3 THEN av.rep_impact ELSE 0 END) AS rep_from_downvotes,
  -- Accepted answer stats
  SUM(CASE WHEN av.vote_type_id = 1 THEN av.vote_count ELSE 0 END) AS total_accepted_answers,
  SUM(CASE WHEN av.vote_type_id = 1 THEN av.rep_impact ELSE 0 END) AS rep_from_accepted,
  -- Totals and ratios
  SUM(av.rep_impact) AS total_rep_earned_from_answers,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN av.vote_type_id = 2 THEN av.vote_count ELSE 0 END),
    SUM(CASE WHEN av.vote_type_id = 3 THEN av.vote_count ELSE 0 END)
  ), 2) AS upvote_downvote_ratio,
  -- Per-user averages
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN av.vote_type_id = 2 THEN av.vote_count ELSE 0 END),
    COUNT(DISTINCT CASE WHEN av.vote_type_id = 2 THEN t.user_id END)
  ), 2) AS avg_upvotes_per_active_user,
  -- Rep source breakdown (percentage)
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN av.vote_type_id = 2 THEN av.rep_impact ELSE 0 END),
    SUM(CASE WHEN av.rep_impact > 0 THEN av.rep_impact ELSE 0 END)
  ) * 100, 2) AS pct_rep_from_upvotes,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN av.vote_type_id = 1 THEN av.rep_impact ELSE 0 END),
    SUM(CASE WHEN av.rep_impact > 0 THEN av.rep_impact ELSE 0 END)
  ) * 100, 2) AS pct_rep_from_accepted
FROM user_tiers t
LEFT JOIN answer_votes av ON t.user_id = av.owner_user_id
GROUP BY t.reputation_tier
ORDER BY t.reputation_tier DESC
