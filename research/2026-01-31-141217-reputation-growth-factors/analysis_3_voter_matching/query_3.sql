/*
 * Reputation Efficiency Analysis: Reputation per Answer
 *
 * For users with answers (to control for activity), compare:
 * - Reputation per answer for voters vs non-voters
 * - This isolates whether voters get MORE value per contribution
 *
 * This helps distinguish between:
 * a) Voters are simply more engaged and post more content
 * b) Voters somehow earn more reputation per unit of contribution
 *
 * Hypothesis: If voting itself helps build reputation, voters should have
 * higher reputation per answer even when comparing users with similar answer counts.
 */

WITH user_activity AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS answer_count,
    SUM(score) AS total_answer_score,
    AVG(score) AS avg_answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_base AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    u.up_votes,
    ua.answer_count,
    ua.total_answer_score,
    ua.avg_answer_score,

    -- Reputation per answer (efficiency metric)
    SAFE_DIVIDE(u.reputation, ua.answer_count) AS rep_per_answer,

    -- Tenure bucket
    CASE
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 12 THEN 'veteran (12+ years)'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 6 THEN 'established (6-11 years)'
      ELSE 'newer (0-5 years)'
    END AS tenure_bucket,

    -- Activity bucket
    CASE
      WHEN ua.answer_count >= 100 THEN '100+ answers'
      WHEN ua.answer_count >= 25 THEN '25-99 answers'
      WHEN ua.answer_count >= 5 THEN '5-24 answers'
      ELSE '1-4 answers'
    END AS activity_bucket,

    -- Voting cohort
    CASE
      WHEN u.up_votes >= 100 THEN 'voter'
      WHEN u.up_votes = 0 THEN 'non_voter'
      ELSE 'excluded'
    END AS voting_cohort

  FROM `bigquery-public-data.stackoverflow.users` u
  INNER JOIN user_activity ua ON u.id = ua.user_id  -- Only users with answers
  WHERE u.id > 0
    AND ua.answer_count >= 1
)

SELECT
  tenure_bucket,
  activity_bucket,
  voting_cohort,

  COUNT(*) AS user_count,

  -- Reputation efficiency
  ROUND(AVG(rep_per_answer), 2) AS avg_rep_per_answer,
  APPROX_QUANTILES(rep_per_answer, 100)[OFFSET(50)] AS median_rep_per_answer,

  -- Answer quality (potential confounder)
  ROUND(AVG(avg_answer_score), 2) AS avg_answer_score,
  APPROX_QUANTILES(avg_answer_score, 100)[OFFSET(50)] AS median_answer_score,

  -- Total reputation (for context)
  ROUND(AVG(reputation), 0) AS avg_reputation,
  ROUND(AVG(answer_count), 1) AS avg_answer_count

FROM user_base
WHERE voting_cohort IN ('voter', 'non_voter')
GROUP BY tenure_bucket, activity_bucket, voting_cohort
ORDER BY
  CASE tenure_bucket
    WHEN 'veteran (12+ years)' THEN 1
    WHEN 'established (6-11 years)' THEN 2
    ELSE 3
  END,
  CASE activity_bucket
    WHEN '100+ answers' THEN 1
    WHEN '25-99 answers' THEN 2
    WHEN '5-24 answers' THEN 3
    ELSE 4
  END,
  voting_cohort
