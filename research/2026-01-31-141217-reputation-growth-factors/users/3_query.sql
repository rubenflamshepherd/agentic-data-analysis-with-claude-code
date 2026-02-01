/*
Query 3: User Reputation Tiers and Activity Patterns
Segments users by reputation level to understand the distribution of reputation
and characteristics of each tier. Tests hypothesis: reputation tiers have
distinct behavioral profiles (recency, engagement).
*/
SELECT
  CASE
    WHEN reputation = 1 THEN '01_newcomer_1'
    WHEN reputation BETWEEN 2 AND 15 THEN '02_starter_2-15'
    WHEN reputation BETWEEN 16 AND 100 THEN '03_contributor_16-100'
    WHEN reputation BETWEEN 101 AND 500 THEN '04_established_101-500'
    WHEN reputation BETWEEN 501 AND 2000 THEN '05_trusted_501-2000'
    WHEN reputation BETWEEN 2001 AND 10000 THEN '06_expert_2001-10000'
    WHEN reputation BETWEEN 10001 AND 50000 THEN '07_veteran_10001-50000'
    WHEN reputation > 50000 THEN '08_legend_50000+'
  END AS reputation_tier,
  COUNT(*) AS user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_users,
  SUM(reputation) AS total_reputation,
  ROUND(SUM(reputation) * 100.0 / SUM(SUM(reputation)) OVER(), 2) AS pct_of_total_reputation,
  ROUND(AVG(up_votes), 2) AS avg_upvotes_given,
  ROUND(AVG(down_votes), 2) AS avg_downvotes_given,
  ROUND(AVG(views), 2) AS avg_profile_views,
  ROUND(AVG(DATE_DIFF(CURRENT_DATE(), DATE(creation_date), YEAR)), 2) AS avg_account_age_years,
  ROUND(AVG(DATE_DIFF(CURRENT_DATE(), DATE(last_access_date), DAY)), 2) AS avg_days_since_last_access,
  ROUND(APPROX_QUANTILES(DATE_DIFF(CURRENT_DATE(), DATE(last_access_date), DAY), 100)[OFFSET(50)], 0) AS median_days_since_access
FROM `bigquery-public-data.stackoverflow.users`
WHERE reputation IS NOT NULL
GROUP BY reputation_tier
ORDER BY reputation_tier
