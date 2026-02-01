/*
Query 3: Underserved High-Opportunity Tags for New Users

Purpose: Identify "hidden gem" tags that are underserved relative to their
question volume - ideal for new users to specialize in.

Key metrics:
- questions_per_answerer > 2.5 (lots of questions per person = less competition)
- avg_score >= 1.0 (decent reward potential)
- acceptance_rate >= 35% (achievable to get accepted)
- unique_questions >= 5000 (sufficient volume to sustain activity)

This finds niches where demand outstrips supply of answerers.
*/

WITH answer_with_tags AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    a.owner_user_id,
    a.creation_date AS answer_date,
    q.id AS question_id,
    q.tags,
    q.accepted_answer_id,
    q.answer_count,
    CASE WHEN a.id = q.accepted_answer_id THEN 1 ELSE 0 END AS is_accepted
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.creation_date >= '2020-01-01'
    AND a.creation_date < '2024-01-01'
),

answer_tags AS (
  SELECT
    answer_id,
    answer_score,
    owner_user_id,
    answer_date,
    question_id,
    is_accepted,
    answer_count,
    TRIM(tag) AS tag
  FROM answer_with_tags,
  UNNEST(SPLIT(REPLACE(tags, '|', ','), ',')) AS tag
  WHERE TRIM(tag) != ''
),

tag_metrics AS (
  SELECT
    tag,
    COUNT(DISTINCT answer_id) AS total_answers,
    COUNT(DISTINCT owner_user_id) AS unique_answerers,
    COUNT(DISTINCT question_id) AS unique_questions,
    SUM(answer_score) AS total_score,
    AVG(answer_score) AS avg_score_per_answer,
    SAFE_DIVIDE(SUM(is_accepted), COUNT(DISTINCT answer_id)) AS acceptance_rate,
    SAFE_DIVIDE(COUNT(DISTINCT answer_id), COUNT(DISTINCT question_id)) AS answers_per_question,
    SAFE_DIVIDE(COUNT(DISTINCT question_id), COUNT(DISTINCT owner_user_id)) AS questions_per_answerer,
    AVG(CAST(answer_count AS INT64)) AS avg_answer_count_on_questions
  FROM answer_tags
  GROUP BY tag
  HAVING COUNT(DISTINCT answer_id) >= 1000
    AND COUNT(DISTINCT question_id) >= 5000
)

SELECT
  tag,
  unique_questions,
  unique_answerers,
  total_answers,
  ROUND(questions_per_answerer, 2) AS questions_per_answerer,
  ROUND(avg_score_per_answer, 3) AS avg_score,
  ROUND(acceptance_rate * 100, 2) AS accept_rate_pct,
  ROUND(answers_per_question, 2) AS answers_per_q,
  ROUND(avg_answer_count_on_questions, 2) AS avg_answers_on_q,
  -- Calculate "underserved score": high questions/answerer * good score * acceptance rate
  ROUND(questions_per_answerer * avg_score_per_answer * acceptance_rate * 100, 2) AS underserved_score,
  -- Expected reputation per year if answering 1 question per day in this tag
  ROUND(365 * avg_score_per_answer * 10, 0) AS est_rep_per_year_1pd,
  CASE
    WHEN questions_per_answerer >= 4.0 AND avg_score_per_answer >= 1.0 AND acceptance_rate >= 0.4 THEN 'HIDDEN GEM'
    WHEN questions_per_answerer >= 3.0 AND avg_score_per_answer >= 0.9 AND acceptance_rate >= 0.35 THEN 'HIGH POTENTIAL'
    WHEN questions_per_answerer >= 2.5 AND avg_score_per_answer >= 0.8 THEN 'MODERATE POTENTIAL'
    ELSE 'COMPETITIVE'
  END AS opportunity_category
FROM tag_metrics
WHERE questions_per_answerer >= 2.0  -- Filter for underserved
ORDER BY underserved_score DESC
LIMIT 50
