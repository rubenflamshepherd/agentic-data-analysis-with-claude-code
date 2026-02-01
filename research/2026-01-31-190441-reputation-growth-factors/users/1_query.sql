/*
Query 1: Reputation Distribution and Correlation with Voting Activity
----------------------------------------------------------------------
Understanding the distribution of user reputation and its relationship
with up_votes, down_votes, and profile views to identify what factors
correlate with higher reputation. Uses percentile buckets to show how
these metrics vary across reputation tiers.

Note: Data snapshot is from September 2022. Filtering for users active
within 90 days of the data cutoff date (2022-09-25).
*/

SELECT
  reputation_tier,
  COUNT(*) as user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_users,

  -- Reputation stats within tier
  MIN(reputation) as min_reputation,
  MAX(reputation) as max_reputation,
  ROUND(AVG(reputation), 0) as avg_reputation,

  -- Voting activity correlation
  ROUND(AVG(up_votes), 1) as avg_up_votes,
  ROUND(AVG(down_votes), 1) as avg_down_votes,
  ROUND(SAFE_DIVIDE(SUM(up_votes), SUM(up_votes) + SUM(down_votes)) * 100, 1) as up_vote_pct,

  -- Profile engagement
  ROUND(AVG(views), 1) as avg_profile_views,

  -- Account age (days since creation as of data snapshot 2022-09-25)
  ROUND(AVG(DATE_DIFF(DATE('2022-09-25'), DATE(creation_date), DAY)), 0) as avg_account_age_days,

  -- Activity recency (days since last access as of data snapshot)
  ROUND(AVG(DATE_DIFF(DATE('2022-09-25'), DATE(last_access_date), DAY)), 0) as avg_days_since_last_access

FROM (
  SELECT
    *,
    CASE
      WHEN reputation = 1 THEN '1_reputation_1'
      WHEN reputation BETWEEN 2 AND 10 THEN '2_reputation_2_10'
      WHEN reputation BETWEEN 11 AND 100 THEN '3_reputation_11_100'
      WHEN reputation BETWEEN 101 AND 1000 THEN '4_reputation_101_1000'
      WHEN reputation BETWEEN 1001 AND 10000 THEN '5_reputation_1k_10k'
      WHEN reputation BETWEEN 10001 AND 100000 THEN '6_reputation_10k_100k'
      ELSE '7_reputation_100k_plus'
    END as reputation_tier
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE last_access_date >= TIMESTAMP('2022-06-27')  -- 90 days before data cutoff
)
GROUP BY reputation_tier
ORDER BY reputation_tier
