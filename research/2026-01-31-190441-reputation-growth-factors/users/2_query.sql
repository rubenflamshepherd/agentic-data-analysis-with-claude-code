/*
Query 2: Reputation Growth Rate by Account Age Cohort
----------------------------------------------------------------------
Analyzing whether reputation growth is primarily driven by time on platform
or by user engagement quality. Calculates reputation per day of account age
across different creation year cohorts to understand velocity of reputation
building.

Note: Data snapshot is from September 2022. Filtering for active users.
*/

WITH user_metrics AS (
  SELECT
    id,
    reputation,
    up_votes,
    down_votes,
    views,
    creation_date,
    last_access_date,
    DATE_DIFF(DATE('2022-09-25'), DATE(creation_date), DAY) as account_age_days,
    EXTRACT(YEAR FROM creation_date) as creation_year
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE last_access_date >= TIMESTAMP('2022-06-27')  -- Active in last 90 days
    AND creation_date IS NOT NULL
    AND reputation >= 1
)

SELECT
  creation_year,
  COUNT(*) as user_count,

  -- Average metrics
  ROUND(AVG(account_age_days), 0) as avg_account_age_days,
  ROUND(AVG(reputation), 0) as avg_reputation,

  -- Reputation velocity (rep per day)
  ROUND(AVG(SAFE_DIVIDE(reputation, account_age_days)), 3) as avg_rep_per_day,

  -- Percentiles of reputation velocity
  ROUND(APPROX_QUANTILES(SAFE_DIVIDE(reputation, account_age_days), 100)[OFFSET(50)], 3) as median_rep_per_day,
  ROUND(APPROX_QUANTILES(SAFE_DIVIDE(reputation, account_age_days), 100)[OFFSET(90)], 3) as p90_rep_per_day,
  ROUND(APPROX_QUANTILES(SAFE_DIVIDE(reputation, account_age_days), 100)[OFFSET(99)], 3) as p99_rep_per_day,

  -- Voting activity correlation
  ROUND(AVG(up_votes), 1) as avg_up_votes,
  ROUND(AVG(down_votes), 1) as avg_down_votes,

  -- High performer count (users with >1 rep/day)
  COUNTIF(SAFE_DIVIDE(reputation, account_age_days) > 1) as high_velocity_users,
  ROUND(COUNTIF(SAFE_DIVIDE(reputation, account_age_days) > 1) * 100.0 / COUNT(*), 2) as pct_high_velocity

FROM user_metrics
WHERE account_age_days > 0  -- Exclude same-day accounts
GROUP BY creation_year
ORDER BY creation_year
