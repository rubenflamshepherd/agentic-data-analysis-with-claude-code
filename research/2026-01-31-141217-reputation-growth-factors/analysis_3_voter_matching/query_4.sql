/*
 * Answer Quality-Controlled Voting Premium
 *
 * Final test: Among users with SIMILAR answer quality (avg score buckets),
 * do voters still have higher reputation?
 *
 * If yes: Suggests voting behavior is independently associated with reputation
 * If no: Suggests the correlation is fully explained by answer quality
 *
 * This is the most stringent test of the "voting premium" hypothesis.
 */

WITH user_activity AS (
  SELECT
    owner_user_id AS user_id,
    COUNT(*) AS answer_count,
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
    ua.avg_answer_score,

    -- Answer quality bucket (to control for this confounder)
    CASE
      WHEN ua.avg_answer_score >= 5 THEN 'high quality (avg 5+)'
      WHEN ua.avg_answer_score >= 2 THEN 'good quality (avg 2-5)'
      WHEN ua.avg_answer_score >= 1 THEN 'medium quality (avg 1-2)'
      WHEN ua.avg_answer_score >= 0 THEN 'low quality (avg 0-1)'
      ELSE 'negative (avg < 0)'
    END AS quality_bucket,

    -- Tenure bucket (simplified)
    CASE
      WHEN DATE_DIFF(DATE '2024-11-01', DATE(u.creation_date), YEAR) >= 10 THEN 'veteran (10+ years)'
      ELSE 'newer (0-9 years)'
    END AS tenure_bucket,

    -- Activity bucket
    CASE
      WHEN ua.answer_count >= 10 THEN 'active (10+ answers)'
      ELSE 'casual (1-9 answers)'
    END AS activity_bucket,

    CASE
      WHEN u.up_votes >= 100 THEN 'voter'
      WHEN u.up_votes = 0 THEN 'non_voter'
      ELSE 'excluded'
    END AS voting_cohort

  FROM `bigquery-public-data.stackoverflow.users` u
  INNER JOIN user_activity ua ON u.id = ua.user_id
  WHERE u.id > 0
    AND ua.answer_count >= 1
)

SELECT
  tenure_bucket,
  activity_bucket,
  quality_bucket,
  voting_cohort,

  COUNT(*) AS user_count,

  -- Reputation comparison
  ROUND(AVG(reputation), 0) AS avg_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(50)] AS median_reputation,

  -- Actual answer quality (to verify matching)
  ROUND(AVG(avg_answer_score), 2) AS actual_avg_score,
  ROUND(AVG(answer_count), 1) AS avg_answers

FROM user_base
WHERE voting_cohort IN ('voter', 'non_voter')
GROUP BY tenure_bucket, activity_bucket, quality_bucket, voting_cohort
HAVING COUNT(*) >= 20  -- Require minimum sample size for reliability
ORDER BY
  tenure_bucket,
  activity_bucket,
  CASE quality_bucket
    WHEN 'high quality (avg 5+)' THEN 1
    WHEN 'good quality (avg 2-5)' THEN 2
    WHEN 'medium quality (avg 1-2)' THEN 3
    WHEN 'low quality (avg 0-1)' THEN 4
    ELSE 5
  END,
  voting_cohort
