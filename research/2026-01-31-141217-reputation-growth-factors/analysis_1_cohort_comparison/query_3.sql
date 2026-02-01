/*
 * Query 3: Answer-Derived Reputation Analysis
 *
 * Stack Overflow reputation comes from multiple sources:
 * - Answer upvotes: +10 per upvote
 * - Answer accepted: +15
 * - Question upvotes: +10
 * - Bounties awarded
 * - Suggested edits: +2
 * - Downvotes given: -1
 * - Etc.
 *
 * This query estimates what % of reputation is directly attributable to answer scores
 * (score * 10) and identifies if early adopters have extra reputation from other sources.
 *
 * Compares the relationship between answer score and actual reputation to understand
 * if there are compound effects (e.g., accepted answers, bounties) that benefit early adopters.
 */

WITH user_answer_stats AS (
  SELECT
    owner_user_id,
    COUNT(*) AS answer_count,
    SUM(score) AS total_answer_score,
    SUM(CASE WHEN score > 0 THEN score ELSE 0 END) AS positive_answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_cohorts AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    CASE
      WHEN EXTRACT(YEAR FROM u.creation_date) BETWEEN 2008 AND 2012 THEN 'Early (2008-2012)'
      WHEN EXTRACT(YEAR FROM u.creation_date) BETWEEN 2018 AND 2022 THEN 'Late (2018-2022)'
    END AS cohort,
    COALESCE(a.answer_count, 0) AS answer_count,
    COALESCE(a.total_answer_score, 0) AS total_answer_score,
    COALESCE(a.positive_answer_score, 0) AS positive_answer_score,
    -- Estimated reputation from answer upvotes alone (+10 per upvote)
    COALESCE(a.positive_answer_score * 10, 0) AS estimated_answer_rep
  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN user_answer_stats a ON u.id = a.owner_user_id
  WHERE EXTRACT(YEAR FROM u.creation_date) BETWEEN 2008 AND 2012
     OR EXTRACT(YEAR FROM u.creation_date) BETWEEN 2018 AND 2022
),

with_buckets AS (
  SELECT
    *,
    CASE
      WHEN answer_count = 0 THEN '0_none'
      WHEN answer_count BETWEEN 1 AND 5 THEN '1_1-5'
      WHEN answer_count BETWEEN 6 AND 20 THEN '2_6-20'
      WHEN answer_count BETWEEN 21 AND 100 THEN '3_21-100'
      WHEN answer_count BETWEEN 101 AND 500 THEN '4_101-500'
      ELSE '5_500+'
    END AS activity_bucket,
    -- How much "extra" reputation exists beyond answer upvote value?
    -- (This represents accepted answers, question upvotes, bounties, etc.)
    reputation - estimated_answer_rep AS non_answer_rep
  FROM user_cohorts
)

SELECT
  cohort,
  activity_bucket,
  COUNT(*) AS user_count,
  -- Answer-derived reputation
  ROUND(AVG(estimated_answer_rep), 2) AS avg_answer_derived_rep,
  ROUND(SUM(estimated_answer_rep) * 1.0 / NULLIF(SUM(reputation), 0) * 100, 1) AS pct_rep_from_answer_upvotes,
  -- Non-answer reputation (accepted, questions, bounties, etc.)
  ROUND(AVG(non_answer_rep), 2) AS avg_non_answer_rep,
  -- Total reputation
  ROUND(AVG(reputation), 2) AS avg_reputation,
  -- Efficiency ratio: reputation per answer
  ROUND(SUM(reputation) * 1.0 / NULLIF(SUM(answer_count), 0), 2) AS rep_per_answer,
  -- Bonus efficiency: non-answer rep per answer (accepted answers, bounties, etc.)
  ROUND(SUM(non_answer_rep) * 1.0 / NULLIF(SUM(answer_count), 0), 2) AS bonus_rep_per_answer
FROM with_buckets
GROUP BY cohort, activity_bucket
ORDER BY cohort, activity_bucket
