/*
Query 2: Reputation by Voting Activity Levels
Segments users by their voting activity (up_votes given) to understand
if active community participation correlates with personal reputation growth.
Tests hypothesis: users who vote more also earn more reputation.
*/
SELECT
  CASE
    WHEN up_votes = 0 THEN '0_no_votes'
    WHEN up_votes BETWEEN 1 AND 10 THEN '1_1-10_votes'
    WHEN up_votes BETWEEN 11 AND 50 THEN '2_11-50_votes'
    WHEN up_votes BETWEEN 51 AND 200 THEN '3_51-200_votes'
    WHEN up_votes BETWEEN 201 AND 1000 THEN '4_201-1000_votes'
    WHEN up_votes > 1000 THEN '5_1000+_votes'
  END AS voting_segment,
  COUNT(*) AS user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_users,
  ROUND(AVG(reputation), 2) AS avg_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(50)], 2) AS median_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(75)], 2) AS p75_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(90)], 2) AS p90_reputation,
  ROUND(APPROX_QUANTILES(reputation, 100)[OFFSET(99)], 2) AS p99_reputation,
  MAX(reputation) AS max_reputation,
  SUM(reputation) AS total_reputation_contribution,
  ROUND(AVG(views), 2) AS avg_profile_views,
  ROUND(AVG(DATE_DIFF(CURRENT_DATE(), DATE(creation_date), YEAR)), 2) AS avg_account_age_years
FROM `bigquery-public-data.stackoverflow.users`
WHERE up_votes IS NOT NULL
GROUP BY voting_segment
ORDER BY voting_segment
