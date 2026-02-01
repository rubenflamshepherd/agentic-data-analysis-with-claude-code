/*
 * Propensity Matching Analysis: Voters vs Non-Voters
 *
 * This query creates stratified cohorts by:
 * 1. Tenure (years since joining) - bucketed into 3-year ranges
 * 2. Activity level (number of answers posted) - bucketed by volume
 *
 * Within each stratum, we compare:
 * - Voters: users who have given 100+ upvotes (active community participants)
 * - Non-voters: users who have given 0 upvotes (passive consumers)
 *
 * This controls for confounders since we're comparing users with
 * similar tenure and activity levels who differ only in voting behavior.
 */

WITH user_activity AS (
  -- Calculate answer counts per user
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS answer_count
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_base AS (
  -- Join users with their activity levels and create cohorts
  SELECT
    u.id AS user_id,
    u.reputation,
    u.up_votes,
    u.creation_date,
    COALESCE(ua.answer_count, 0) AS answer_count,

    -- Tenure bucket (years since joining)
    CASE
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 15 THEN '15+ years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 12 THEN '12-14 years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 9 THEN '9-11 years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 6 THEN '6-8 years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 3 THEN '3-5 years'
      ELSE '0-2 years'
    END AS tenure_bucket,

    -- Activity level bucket
    CASE
      WHEN COALESCE(ua.answer_count, 0) >= 100 THEN '100+ answers'
      WHEN COALESCE(ua.answer_count, 0) >= 25 THEN '25-99 answers'
      WHEN COALESCE(ua.answer_count, 0) >= 5 THEN '5-24 answers'
      WHEN COALESCE(ua.answer_count, 0) >= 1 THEN '1-4 answers'
      ELSE '0 answers'
    END AS activity_bucket,

    -- Voting cohort (treatment vs control)
    CASE
      WHEN u.up_votes >= 100 THEN 'voter'
      WHEN u.up_votes = 0 THEN 'non_voter'
      ELSE 'excluded'  -- Users with 1-99 upvotes are excluded for cleaner comparison
    END AS voting_cohort

  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN user_activity ua ON u.id = ua.user_id
  WHERE u.id > 0  -- Exclude system users
)

SELECT
  tenure_bucket,
  activity_bucket,
  voting_cohort,

  -- Sample sizes
  COUNT(*) AS user_count,

  -- Reputation metrics
  ROUND(AVG(reputation), 2) AS avg_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(50)] AS median_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(25)] AS p25_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(75)] AS p75_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(90)] AS p90_reputation,

  -- Activity metrics
  ROUND(AVG(answer_count), 2) AS avg_answers,
  ROUND(AVG(up_votes), 2) AS avg_upvotes_given

FROM user_base
WHERE voting_cohort IN ('voter', 'non_voter')  -- Only compare treatment vs control
GROUP BY tenure_bucket, activity_bucket, voting_cohort
ORDER BY
  CASE tenure_bucket
    WHEN '15+ years' THEN 1
    WHEN '12-14 years' THEN 2
    WHEN '9-11 years' THEN 3
    WHEN '6-8 years' THEN 4
    WHEN '3-5 years' THEN 5
    ELSE 6
  END,
  CASE activity_bucket
    WHEN '100+ answers' THEN 1
    WHEN '25-99 answers' THEN 2
    WHEN '5-24 answers' THEN 3
    WHEN '1-4 answers' THEN 4
    ELSE 5
  END,
  voting_cohort
