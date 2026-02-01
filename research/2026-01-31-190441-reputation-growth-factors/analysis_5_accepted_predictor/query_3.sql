/*
  Query 3: Acceptance Rate by Answerer Reputation Tier

  Purpose: Analyze whether users with higher reputation have better acceptance rates,
  and quantify the relationship between reputation and acceptance probability.

  Note: We use current user reputation as a proxy, since we don't have historical
  reputation snapshots. This is a limitation - high-rep users may have built reputation
  AFTER getting answers accepted.

  Reputation tiers:
  - Beginner: 1-100 rep
  - Intermediate: 101-1000 rep
  - Experienced: 1001-5000 rep
  - Expert: 5001-25000 rep
  - Elite: 25001-100000 rep
  - Legend: 100001+ rep
*/

WITH answer_data AS (
  SELECT
    a.id AS answer_id,
    a.parent_id AS question_id,
    a.owner_user_id,
    a.score AS answer_score,
    u.reputation AS user_reputation,
    CASE WHEN q.accepted_answer_id = a.id THEN 1 ELSE 0 END AS is_accepted,
    LENGTH(a.body) AS answer_length,
    TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) AS response_minutes
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  INNER JOIN `bigquery-public-data.stackoverflow.users` u
    ON a.owner_user_id = u.id
  WHERE a.owner_user_id IS NOT NULL
    AND a.creation_date >= q.creation_date
    AND EXTRACT(YEAR FROM a.creation_date) BETWEEN 2018 AND 2022
),
bucketed AS (
  SELECT
    *,
    CASE
      WHEN user_reputation <= 100 THEN '01. Beginner (1-100)'
      WHEN user_reputation <= 1000 THEN '02. Intermediate (101-1000)'
      WHEN user_reputation <= 5000 THEN '03. Experienced (1001-5000)'
      WHEN user_reputation <= 25000 THEN '04. Expert (5001-25000)'
      WHEN user_reputation <= 100000 THEN '05. Elite (25001-100000)'
      ELSE '06. Legend (100001+)'
    END AS reputation_tier
  FROM answer_data
)

SELECT
  reputation_tier,
  COUNT(*) AS total_answers,
  SUM(is_accepted) AS accepted_count,
  SAFE_DIVIDE(SUM(is_accepted), COUNT(*)) * 100 AS acceptance_rate_pct,
  AVG(answer_score) AS avg_score,
  AVG(answer_length) AS avg_answer_length,
  AVG(response_minutes) AS avg_response_minutes,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100 AS pct_of_all_answers
FROM bucketed
GROUP BY reputation_tier
ORDER BY reputation_tier
