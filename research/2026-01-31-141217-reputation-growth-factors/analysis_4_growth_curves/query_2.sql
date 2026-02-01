/*
Query 2: Classify Users by Growth Curve Type
---------------------------------------------
For users with 100+ posts and 5+ years tenure, classify them into growth
curve shapes based on when they earned their reputation:
- Early Bloomers: 60%+ of score in first 2 years
- Late Bloomers: 60%+ of score in years 3+
- Steady Growers: Relatively even distribution across years
- Plateau Users: Peak early, then sharp decline (low ongoing contribution)

We calculate the share of total score earned in each time period and
classify accordingly.
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

user_stats AS (
  -- Get users with 100+ posts and 5+ years of tenure
  SELECT
    u.id AS user_id,
    u.creation_date AS user_creation_date,
    u.reputation,
    COUNT(*) AS total_posts
  FROM `bigquery-public-data.stackoverflow.users` u
  JOIN user_posts p ON u.id = p.owner_user_id
  WHERE DATE_DIFF(CURRENT_DATE(), DATE(u.creation_date), YEAR) >= 5
  GROUP BY u.id, u.creation_date, u.reputation
  HAVING COUNT(*) >= 100
),

period_scores AS (
  -- Calculate score earned in each period for qualifying users
  SELECT
    us.user_id,
    us.reputation AS current_reputation,
    us.total_posts,
    EXTRACT(YEAR FROM us.user_creation_date) AS join_year,
    DATE_DIFF(CURRENT_DATE(), DATE(us.user_creation_date), YEAR) AS tenure_years,

    -- Score by period
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) BETWEEN 0 AND 1 THEN p.score ELSE 0 END) AS score_years_0_1,
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) BETWEEN 2 AND 4 THEN p.score ELSE 0 END) AS score_years_2_4,
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) >= 5 THEN p.score ELSE 0 END) AS score_years_5_plus,
    SUM(p.score) AS total_score_earned,

    -- Posts by period
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) BETWEEN 0 AND 1 THEN 1 ELSE 0 END) AS posts_years_0_1,
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) BETWEEN 2 AND 4 THEN 1 ELSE 0 END) AS posts_years_2_4,
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) >= 5 THEN 1 ELSE 0 END) AS posts_years_5_plus
  FROM user_stats us
  JOIN user_posts p ON us.user_id = p.owner_user_id
  WHERE DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) >= 0
  GROUP BY us.user_id, us.reputation, us.total_posts,
           EXTRACT(YEAR FROM us.user_creation_date),
           DATE_DIFF(CURRENT_DATE(), DATE(us.user_creation_date), YEAR)
),

classified_users AS (
  SELECT
    *,
    -- Calculate percentages
    SAFE_DIVIDE(score_years_0_1, total_score_earned) * 100 AS pct_early,
    SAFE_DIVIDE(score_years_2_4, total_score_earned) * 100 AS pct_mid,
    SAFE_DIVIDE(score_years_5_plus, total_score_earned) * 100 AS pct_late,

    -- Classify growth curve type
    CASE
      WHEN SAFE_DIVIDE(score_years_0_1, total_score_earned) >= 0.6 THEN 'Early Bloomer'
      WHEN SAFE_DIVIDE(score_years_5_plus, total_score_earned) >= 0.5 THEN 'Late Bloomer'
      WHEN SAFE_DIVIDE(score_years_5_plus, total_score_earned) <= 0.1 AND tenure_years >= 7 THEN 'Plateau'
      ELSE 'Steady Grower'
    END AS growth_type
  FROM period_scores
  WHERE total_score_earned > 0  -- Exclude users with negative total scores
)

-- Aggregate by growth type
SELECT
  growth_type,
  COUNT(*) AS user_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_users,
  ROUND(AVG(current_reputation), 0) AS avg_reputation,
  ROUND(APPROX_QUANTILES(current_reputation, 100)[OFFSET(50)], 0) AS median_reputation,
  ROUND(AVG(total_posts), 0) AS avg_total_posts,
  ROUND(AVG(tenure_years), 1) AS avg_tenure_years,
  ROUND(AVG(pct_early), 1) AS avg_pct_early,
  ROUND(AVG(pct_mid), 1) AS avg_pct_mid,
  ROUND(AVG(pct_late), 1) AS avg_pct_late,
  ROUND(AVG(SAFE_DIVIDE(total_score_earned, total_posts)), 2) AS avg_score_per_post
FROM classified_users
GROUP BY growth_type
ORDER BY user_count DESC
