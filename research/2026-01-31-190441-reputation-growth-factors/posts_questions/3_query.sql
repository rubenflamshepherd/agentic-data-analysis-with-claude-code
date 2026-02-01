/*
 * Query 3: User Question Activity Patterns and Reputation Accumulation
 *
 * Purpose: Analyze the relationship between user question-asking patterns
 * and total reputation earned from questions. Examines:
 * - How many questions do successful users ask?
 * - What is the score distribution per user?
 * - Does question frequency correlate with per-question performance?
 *
 * Note: Table data ends at 2022-09-25, analyzing last 365 days of available data.
 */

WITH user_stats AS (
  SELECT
    owner_user_id,
    COUNT(*) AS question_count,
    SUM(score) AS total_score,
    SUM(CASE WHEN score > 0 THEN score ELSE 0 END) AS positive_score_sum,
    SUM(CASE WHEN score < 0 THEN score ELSE 0 END) AS negative_score_sum,
    ROUND(AVG(score), 2) AS avg_score_per_question,
    SUM(CASE WHEN score > 0 THEN 1 ELSE 0 END) AS positive_questions,
    SUM(CASE WHEN score >= 5 THEN 1 ELSE 0 END) AS high_score_questions,
    SUM(CASE WHEN accepted_answer_id IS NOT NULL THEN 1 ELSE 0 END) AS accepted_answer_questions,
    SUM(view_count) AS total_views,
    SUM(answer_count) AS total_answers
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2021-09-25'
    AND creation_date < '2022-09-25'
    AND owner_user_id IS NOT NULL
  GROUP BY owner_user_id
)

SELECT
  CASE
    WHEN question_count = 1 THEN 'a. 1 question'
    WHEN question_count <= 3 THEN 'b. 2-3 questions'
    WHEN question_count <= 5 THEN 'c. 4-5 questions'
    WHEN question_count <= 10 THEN 'd. 6-10 questions'
    WHEN question_count <= 20 THEN 'e. 11-20 questions'
    WHEN question_count <= 50 THEN 'f. 21-50 questions'
    ELSE 'g. 50+ questions'
  END AS activity_bucket,
  COUNT(*) AS user_count,
  SUM(question_count) AS total_questions,
  ROUND(AVG(total_score), 2) AS avg_total_score,
  ROUND(AVG(avg_score_per_question), 2) AS avg_score_per_q,
  ROUND(SUM(positive_questions) * 100.0 / SUM(question_count), 2) AS pct_positive_questions,
  ROUND(SUM(high_score_questions) * 100.0 / SUM(question_count), 2) AS pct_high_score_questions,
  ROUND(SUM(accepted_answer_questions) * 100.0 / SUM(question_count), 2) AS pct_with_accepted,
  ROUND(SUM(total_views) * 1.0 / SUM(question_count), 0) AS avg_views_per_q
FROM user_stats
GROUP BY activity_bucket
ORDER BY activity_bucket
