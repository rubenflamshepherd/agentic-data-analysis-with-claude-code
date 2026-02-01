/*
Query 1: Reputation Distribution by Account Tenure
Examines how reputation varies by account age (years since creation),
to understand the relationship between time on platform and reputation growth.
This helps identify if tenure is a primary driver of reputation.
*/
SELECT
  DATE_DIFF(CURRENT_DATE(), DATE(creation_date), YEAR) AS account_age_years,
  COUNT(*) AS user_count,
  ROUND(AVG(reputation), 2) AS avg_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(50)], 2) AS median_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(90)], 2) AS p90_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(99)], 2) AS p99_reputation,
  MAX(reputation) AS max_reputation,
  SUM(reputation) AS total_reputation,
  ROUND(AVG(up_votes), 2) AS avg_up_votes_given,
  ROUND(AVG(down_votes), 2) AS avg_down_votes_given,
  ROUND(AVG(views), 2) AS avg_profile_views
FROM `bigquery-public-data.stackoverflow.users`
WHERE creation_date IS NOT NULL
GROUP BY account_age_years
ORDER BY account_age_years
