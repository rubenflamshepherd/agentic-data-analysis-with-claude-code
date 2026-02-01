/*
 * Voting Premium Analysis - Within-Stratum Comparison
 *
 * Calculates the "voting premium" - how much extra reputation voters earn
 * compared to matched non-voters with the same tenure and activity level.
 *
 * Uses median reputation for comparison (more robust to outliers).
 * Reports both absolute premium and relative lift.
 */

WITH user_activity AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS answer_count
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
  GROUP BY owner_user_id
),

user_base AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    u.up_votes,
    COALESCE(ua.answer_count, 0) AS answer_count,

    -- Tenure bucket
    CASE
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 15 THEN '15+ years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 12 THEN '12-14 years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 9 THEN '9-11 years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 6 THEN '6-8 years'
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 3 THEN '3-5 years'
      ELSE '0-2 years'
    END AS tenure_bucket,

    -- Activity bucket (simplified for cleaner comparison)
    CASE
      WHEN COALESCE(ua.answer_count, 0) >= 5 THEN 'active (5+ answers)'
      WHEN COALESCE(ua.answer_count, 0) >= 1 THEN 'minimal (1-4 answers)'
      ELSE 'passive (0 answers)'
    END AS activity_bucket,

    CASE
      WHEN u.up_votes >= 100 THEN 'voter'
      WHEN u.up_votes = 0 THEN 'non_voter'
      ELSE 'excluded'
    END AS voting_cohort

  FROM `bigquery-public-data.stackoverflow.users` u
  LEFT JOIN user_activity ua ON u.id = ua.user_id
  WHERE u.id > 0
),

aggregated AS (
  SELECT
    tenure_bucket,
    activity_bucket,
    voting_cohort,
    COUNT(*) AS user_count,
    APPROX_QUANTILES(reputation, 100)[OFFSET(50)] AS median_reputation,
    AVG(reputation) AS avg_reputation
  FROM user_base
  WHERE voting_cohort IN ('voter', 'non_voter')
  GROUP BY tenure_bucket, activity_bucket, voting_cohort
)

SELECT
  v.tenure_bucket,
  v.activity_bucket,

  -- Sample sizes
  nv.user_count AS non_voter_count,
  v.user_count AS voter_count,

  -- Median reputation comparison
  nv.median_reputation AS non_voter_median_rep,
  v.median_reputation AS voter_median_rep,

  -- Voting premium (absolute and relative)
  v.median_reputation - nv.median_reputation AS median_premium_absolute,
  ROUND(SAFE_DIVIDE(v.median_reputation - nv.median_reputation, nv.median_reputation) * 100, 1) AS median_premium_pct,

  -- Also show average comparison
  ROUND(nv.avg_reputation, 0) AS non_voter_avg_rep,
  ROUND(v.avg_reputation, 0) AS voter_avg_rep,
  ROUND(SAFE_DIVIDE(v.avg_reputation - nv.avg_reputation, nv.avg_reputation) * 100, 1) AS avg_premium_pct

FROM aggregated v
JOIN aggregated nv
  ON v.tenure_bucket = nv.tenure_bucket
  AND v.activity_bucket = nv.activity_bucket
  AND v.voting_cohort = 'voter'
  AND nv.voting_cohort = 'non_voter'

ORDER BY
  CASE v.tenure_bucket
    WHEN '15+ years' THEN 1
    WHEN '12-14 years' THEN 2
    WHEN '9-11 years' THEN 3
    WHEN '6-8 years' THEN 4
    WHEN '3-5 years' THEN 5
    ELSE 6
  END,
  CASE v.activity_bucket
    WHEN 'active (5+ answers)' THEN 1
    WHEN 'minimal (1-4 answers)' THEN 2
    ELSE 3
  END
