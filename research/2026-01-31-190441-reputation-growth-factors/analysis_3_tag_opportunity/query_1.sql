/*
Query 1: Average Score Per Answer by Tag (Top 100 Tags)

Purpose: Calculate the average score earned per answer for each tag by joining
answers to their parent questions and extracting individual tags.

Methodology:
- Join posts_answers to posts_questions via parent_id -> id
- Split the tags string (pipe-delimited format like "|python|pandas|")
- Calculate metrics per tag: avg score, total answers, total score
- Filter to top 100 tags by answer volume for meaningful sample sizes
*/

WITH answer_with_tags AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    a.owner_user_id,
    a.creation_date AS answer_date,
    q.id AS question_id,
    q.tags,
    q.view_count AS question_views,
    q.accepted_answer_id,
    CASE WHEN a.id = q.accepted_answer_id THEN 1 ELSE 0 END AS is_accepted
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.creation_date >= '2020-01-01'
    AND a.creation_date < '2024-01-01'
),

-- Unnest the tags (stored as "|tag1|tag2|tag3|" format)
answer_tags AS (
  SELECT
    answer_id,
    answer_score,
    owner_user_id,
    answer_date,
    question_id,
    question_views,
    is_accepted,
    TRIM(tag) AS tag
  FROM answer_with_tags,
  UNNEST(SPLIT(REPLACE(tags, '|', ','), ',')) AS tag
  WHERE TRIM(tag) != ''
)

SELECT
  tag,
  COUNT(DISTINCT answer_id) AS total_answers,
  COUNT(DISTINCT owner_user_id) AS unique_answerers,
  COUNT(DISTINCT question_id) AS unique_questions,
  SUM(answer_score) AS total_score,
  ROUND(AVG(answer_score), 3) AS avg_score_per_answer,
  ROUND(SAFE_DIVIDE(SUM(answer_score), COUNT(DISTINCT owner_user_id)), 3) AS avg_score_per_user,
  SUM(is_accepted) AS accepted_answers,
  ROUND(SAFE_DIVIDE(SUM(is_accepted) * 100.0, COUNT(DISTINCT answer_id)), 2) AS acceptance_rate_pct,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT answer_id), COUNT(DISTINCT question_id)), 2) AS answers_per_question
FROM answer_tags
GROUP BY tag
HAVING COUNT(DISTINCT answer_id) >= 1000  -- Minimum sample size
ORDER BY total_answers DESC
LIMIT 100
