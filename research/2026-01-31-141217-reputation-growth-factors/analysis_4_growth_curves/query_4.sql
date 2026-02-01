/*
Query 4: Years to Reach 10K Reputation by Join Cohort
-----------------------------------------------------
For users who have achieved 10K+ reputation, calculate how many years
it took them to reach this milestone based on when they earned
cumulative reputation from their posts.

10K reputation is a significant milestone - it grants privileges like
deletion votes and access to moderator tools.
*/

WITH user_posts AS (
  SELECT
    owner_user_id,
    creation_date AS post_date,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL

  UNION ALL

  SELECT
    owner_user_id,
    creation_date AS post_date,
    score
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),

users_10k AS (
  -- Get users with 10K+ current reputation
  SELECT
    id AS user_id,
    creation_date AS user_creation_date,
    reputation,
    EXTRACT(YEAR FROM creation_date) AS join_year
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 10000
),

cumulative_scores AS (
  -- Calculate cumulative score at each year since joining
  SELECT
    u.user_id,
    u.user_creation_date,
    u.join_year,
    u.reputation AS current_reputation,
    DATE_DIFF(DATE(p.post_date), DATE(u.user_creation_date), YEAR) AS year_offset,
    SUM(p.score) AS score_in_year
  FROM users_10k u
  JOIN user_posts p ON u.user_id = p.owner_user_id
  WHERE DATE_DIFF(DATE(p.post_date), DATE(u.user_creation_date), YEAR) >= 0
    AND DATE_DIFF(DATE(p.post_date), DATE(u.user_creation_date), YEAR) <= 15
  GROUP BY u.user_id, u.user_creation_date, u.join_year, u.reputation,
           DATE_DIFF(DATE(p.post_date), DATE(u.user_creation_date), YEAR)
),

running_totals AS (
  -- Calculate running cumulative score for each user
  SELECT
    user_id,
    user_creation_date,
    join_year,
    current_reputation,
    year_offset,
    SUM(score_in_year) OVER(PARTITION BY user_id ORDER BY year_offset) AS cumulative_score
  FROM cumulative_scores
),

years_to_10k AS (
  -- Find the first year where cumulative score reaches ~1000 (approx 10K rep)
  -- Note: 10K rep ~ 1000 score from upvotes (10 rep per upvote on answers/questions)
  SELECT
    user_id,
    join_year,
    current_reputation,
    MIN(CASE WHEN cumulative_score >= 1000 THEN year_offset END) AS years_to_1k_score
  FROM running_totals
  GROUP BY user_id, join_year, current_reputation
),

join_cohorts AS (
  SELECT
    CASE
      WHEN join_year = 2008 THEN '2008'
      WHEN join_year = 2009 THEN '2009'
      WHEN join_year = 2010 THEN '2010'
      WHEN join_year = 2011 THEN '2011'
      WHEN join_year BETWEEN 2012 AND 2013 THEN '2012-2013'
      WHEN join_year BETWEEN 2014 AND 2015 THEN '2014-2015'
      WHEN join_year BETWEEN 2016 AND 2017 THEN '2016-2017'
      WHEN join_year >= 2018 THEN '2018+'
    END AS cohort,
    join_year,
    years_to_1k_score,
    current_reputation
  FROM years_to_10k
)

SELECT
  cohort,
  COUNT(*) AS users_with_10k_rep,
  ROUND(AVG(years_to_1k_score), 2) AS avg_years_to_milestone,
  ROUND(APPROX_QUANTILES(years_to_1k_score, 100)[OFFSET(50)], 2) AS median_years,
  ROUND(APPROX_QUANTILES(years_to_1k_score, 100)[OFFSET(25)], 2) AS p25_years,
  ROUND(APPROX_QUANTILES(years_to_1k_score, 100)[OFFSET(75)], 2) AS p75_years,
  ROUND(AVG(current_reputation), 0) AS avg_current_reputation,
  ROUND(SUM(CASE WHEN years_to_1k_score <= 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_reached_in_1_year,
  ROUND(SUM(CASE WHEN years_to_1k_score <= 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_reached_in_3_years
FROM join_cohorts
WHERE cohort IS NOT NULL
  AND years_to_1k_score IS NOT NULL
GROUP BY cohort
ORDER BY cohort
