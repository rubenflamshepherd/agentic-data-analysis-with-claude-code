/*
Query 3: Detailed Characteristics by Growth Curve Type
------------------------------------------------------
For each growth curve type, analyze:
- Answer vs question mix
- Post frequency patterns
- Join cohort (era of joining)
- Score efficiency metrics
*/

WITH user_posts AS (
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
  SELECT
    us.user_id,
    us.reputation AS current_reputation,
    us.total_posts,
    us.user_creation_date,
    EXTRACT(YEAR FROM us.user_creation_date) AS join_year,
    DATE_DIFF(CURRENT_DATE(), DATE(us.user_creation_date), YEAR) AS tenure_years,

    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) BETWEEN 0 AND 1 THEN p.score ELSE 0 END) AS score_years_0_1,
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) BETWEEN 2 AND 4 THEN p.score ELSE 0 END) AS score_years_2_4,
    SUM(CASE WHEN DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) >= 5 THEN p.score ELSE 0 END) AS score_years_5_plus,
    SUM(p.score) AS total_score_earned,

    -- Answer vs question breakdown
    SUM(CASE WHEN p.post_type = 'answer' THEN 1 ELSE 0 END) AS answer_count,
    SUM(CASE WHEN p.post_type = 'question' THEN 1 ELSE 0 END) AS question_count,
    SUM(CASE WHEN p.post_type = 'answer' THEN p.score ELSE 0 END) AS answer_score,
    SUM(CASE WHEN p.post_type = 'question' THEN p.score ELSE 0 END) AS question_score
  FROM user_stats us
  JOIN user_posts p ON us.user_id = p.owner_user_id
  WHERE DATE_DIFF(DATE(p.post_date), DATE(us.user_creation_date), YEAR) >= 0
  GROUP BY us.user_id, us.reputation, us.total_posts, us.user_creation_date,
           EXTRACT(YEAR FROM us.user_creation_date),
           DATE_DIFF(CURRENT_DATE(), DATE(us.user_creation_date), YEAR)
),

classified_users AS (
  SELECT
    *,
    SAFE_DIVIDE(score_years_0_1, total_score_earned) AS pct_early,
    SAFE_DIVIDE(score_years_5_plus, total_score_earned) AS pct_late,
    CASE
      WHEN SAFE_DIVIDE(score_years_0_1, total_score_earned) >= 0.6 THEN 'Early Bloomer'
      WHEN SAFE_DIVIDE(score_years_5_plus, total_score_earned) >= 0.5 THEN 'Late Bloomer'
      WHEN SAFE_DIVIDE(score_years_5_plus, total_score_earned) <= 0.1 AND tenure_years >= 7 THEN 'Plateau'
      ELSE 'Steady Grower'
    END AS growth_type,
    -- Era classification
    CASE
      WHEN EXTRACT(YEAR FROM user_creation_date) BETWEEN 2008 AND 2011 THEN '2008-2011 (Pioneer)'
      WHEN EXTRACT(YEAR FROM user_creation_date) BETWEEN 2012 AND 2015 THEN '2012-2015 (Growth)'
      WHEN EXTRACT(YEAR FROM user_creation_date) >= 2016 THEN '2016+ (Mature)'
    END AS join_era
  FROM period_scores
  WHERE total_score_earned > 0
)

SELECT
  growth_type,
  join_era,
  COUNT(*) AS users,
  ROUND(AVG(current_reputation), 0) AS avg_reputation,
  ROUND(SAFE_DIVIDE(SUM(answer_count), SUM(answer_count) + SUM(question_count)) * 100, 1) AS pct_posts_are_answers,
  ROUND(SAFE_DIVIDE(SUM(answer_score), SUM(total_score_earned)) * 100, 1) AS pct_score_from_answers,
  ROUND(AVG(SAFE_DIVIDE(answer_score, answer_count)), 2) AS avg_score_per_answer,
  ROUND(AVG(SAFE_DIVIDE(question_score, question_count)), 2) AS avg_score_per_question,
  ROUND(AVG(SAFE_DIVIDE(total_posts, tenure_years)), 1) AS avg_posts_per_year
FROM classified_users
GROUP BY growth_type, join_era
ORDER BY growth_type, join_era
