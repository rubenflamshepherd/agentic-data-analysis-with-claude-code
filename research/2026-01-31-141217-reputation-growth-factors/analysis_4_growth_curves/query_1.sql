/*
Query 1: Cumulative Score Earned by Year Since Joining
------------------------------------------------------
For users with 100+ total posts (answers + questions), calculate the
cumulative score they earned each year since joining. This allows us to
track reputation trajectories over time.

We union answers and questions, then aggregate by user and year_offset
(years since user creation).
*/

WITH user_posts AS (
  -- Get all posts (answers and questions) with their scores
  SELECT
    owner_user_id,
    creation_date AS post_date,
    score,
    'answer' AS post_type
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL

  UNION ALL

  SELECT
    owner_user_id,
    creation_date AS post_date,
    score,
    'question' AS post_type
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),

user_stats AS (
  -- Get users with their creation dates and filter to 100+ posts
  SELECT
    u.id AS user_id,
    u.creation_date AS user_creation_date,
    u.reputation,
    COUNT(*) AS total_posts
  FROM `bigquery-public-data.stackoverflow.users` u
  JOIN user_posts p ON u.id = p.owner_user_id
  GROUP BY u.id, u.creation_date, u.reputation
  HAVING COUNT(*) >= 100
),

yearly_scores AS (
  -- For qualifying users, calculate score earned by year since joining
  SELECT
    us.user_id,
    us.user_creation_date,
    us.reputation AS current_reputation,
    us.total_posts,
    EXTRACT(YEAR FROM us.user_creation_date) AS join_year,
    -- Year offset: 0 = joined year, 1 = first full year, etc.
    DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) AS year_offset,
    SUM(p.score) AS score_earned,
    COUNT(*) AS posts_in_year,
    SUM(CASE WHEN p.post_type = 'answer' THEN p.score ELSE 0 END) AS answer_score,
    SUM(CASE WHEN p.post_type = 'question' THEN p.score ELSE 0 END) AS question_score
  FROM user_stats us
  JOIN user_posts p ON us.user_id = p.owner_user_id
  WHERE DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) >= 0
    AND DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) <= 15
  GROUP BY us.user_id, us.user_creation_date, us.reputation, us.total_posts,
           EXTRACT(YEAR FROM us.user_creation_date),
           DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR)
)

-- Aggregate to see typical growth patterns by year offset
SELECT
  year_offset,
  COUNT(DISTINCT user_id) AS users_with_data,
  ROUND(AVG(score_earned), 2) AS avg_score_earned,
  ROUND(APPROX_QUANTILES(score_earned, 100)[OFFSET(50)], 2) AS median_score_earned,
  ROUND(APPROX_QUANTILES(score_earned, 100)[OFFSET(25)], 2) AS p25_score,
  ROUND(APPROX_QUANTILES(score_earned, 100)[OFFSET(75)], 2) AS p75_score,
  ROUND(AVG(posts_in_year), 2) AS avg_posts,
  ROUND(SAFE_DIVIDE(SUM(answer_score), SUM(score_earned)) * 100, 2) AS pct_from_answers
FROM yearly_scores
GROUP BY year_offset
ORDER BY year_offset
