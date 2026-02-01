/*
Query 3: Profile Completeness Impact on Reputation
----------------------------------------------------------------------
Analyzing whether users who invest in completing their profile (about_me,
location, website_url) achieve higher reputation. This tests the hypothesis
that profile engagement signals user investment in the platform.

Note: Data snapshot is from September 2022. Filtering for active users.
*/

SELECT
  -- Profile completeness segment
  CASE
    WHEN about_me IS NOT NULL AND location IS NOT NULL AND website_url IS NOT NULL THEN '3_all_fields'
    WHEN (about_me IS NOT NULL AND location IS NOT NULL) OR
         (about_me IS NOT NULL AND website_url IS NOT NULL) OR
         (location IS NOT NULL AND website_url IS NOT NULL) THEN '2_two_fields'
    WHEN about_me IS NOT NULL OR location IS NOT NULL OR website_url IS NOT NULL THEN '1_one_field'
    ELSE '0_no_fields'
  END as profile_completeness,

  COUNT(*) as user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_users,

  -- Reputation metrics
  ROUND(AVG(reputation), 0) as avg_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(50)] as median_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(90)] as p90_reputation,
  APPROX_QUANTILES(reputation, 100)[OFFSET(99)] as p99_reputation,

  -- Voting activity
  ROUND(AVG(up_votes), 1) as avg_up_votes,
  ROUND(AVG(down_votes), 1) as avg_down_votes,

  -- Profile views (potential reward for profile investment)
  ROUND(AVG(views), 1) as avg_profile_views,

  -- Account characteristics
  ROUND(AVG(DATE_DIFF(DATE('2022-09-25'), DATE(creation_date), DAY)), 0) as avg_account_age_days,

  -- Elite user concentration (10k+ rep)
  COUNTIF(reputation >= 10000) as elite_users,
  ROUND(COUNTIF(reputation >= 10000) * 100.0 / COUNT(*), 2) as pct_elite

FROM `bigquery-public-data.stackoverflow.users`
WHERE last_access_date >= TIMESTAMP('2022-06-27')
GROUP BY profile_completeness
ORDER BY profile_completeness DESC
