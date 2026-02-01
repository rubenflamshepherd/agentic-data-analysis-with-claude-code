/*
Query 2: Tag Opportunity Scoring for New Users

Purpose: Calculate an "opportunity score" for each tag that identifies the best
topics for new users to specialize in, balancing:
- Average score potential (reward)
- Question volume (opportunity size)
- Competition level (answers per question, unique answerers)
- Acceptance rate (easier to get accepted answers)

Opportunity Score = (avg_score * acceptance_rate * question_volume) / (competition_factor)
Where competition_factor = sqrt(unique_answerers) * answers_per_question

This favors tags with:
- High scores per answer
- High acceptance rates
- Lots of questions
- Fewer established answerers (lower competition)
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
    CASE WHEN a.id = q.accepted_answer_id THEN 1 ELSE 0 END AS is_accepted
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.creation_date >= '2020-01-01'
    AND a.creation_date < '2024-01-01'
),

-- Unnest the tags
answer_tags AS (
  SELECT
    answer_id,
    answer_score,
    owner_user_id,
    answer_date,
    question_id,
    is_accepted,
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
    SAFE_DIVIDE(COUNT(DISTINCT answer_id), COUNT(DISTINCT question_id)) AS answers_per_question
  FROM answer_tags
  GROUP BY tag
  HAVING COUNT(DISTINCT answer_id) >= 1000
)

SELECT
  tag,
  total_answers,
  unique_answerers,
  unique_questions,
  ROUND(avg_score_per_answer, 3) AS avg_score,
  ROUND(acceptance_rate * 100, 2) AS accept_rate_pct,
  ROUND(answers_per_question, 2) AS answers_per_q,
  -- Opportunity score calculation
  ROUND(
    (avg_score_per_answer * acceptance_rate * unique_questions) /
    (SQRT(unique_answerers) * answers_per_question),
    2
  ) AS opportunity_score,
  -- Component breakdown
  ROUND(avg_score_per_answer * acceptance_rate, 3) AS expected_score_per_answer,
  ROUND(SAFE_DIVIDE(unique_questions, unique_answerers), 2) AS questions_per_answerer,
  -- Categorize by opportunity tier
  CASE
    WHEN (avg_score_per_answer * acceptance_rate * unique_questions) /
         (SQRT(unique_answerers) * answers_per_question) >= 100 THEN 'A - High Opportunity'
    WHEN (avg_score_per_answer * acceptance_rate * unique_questions) /
         (SQRT(unique_answerers) * answers_per_question) >= 50 THEN 'B - Medium-High'
    WHEN (avg_score_per_answer * acceptance_rate * unique_questions) /
         (SQRT(unique_answerers) * answers_per_question) >= 25 THEN 'C - Medium'
    ELSE 'D - Lower Opportunity'
  END AS opportunity_tier
FROM tag_metrics
ORDER BY opportunity_score DESC
LIMIT 100
