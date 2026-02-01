/*
 * Query 1: Question Performance Distribution by Score Buckets
 *
 * Purpose: Understand the distribution of question scores to see what percentage
 * of questions receive upvotes (positive reputation impact) vs downvotes.
 * Score directly affects reputation: +10 for upvote, -2 for downvote on questions.
 *
 * This helps identify what proportion of questions contribute positively to
 * user reputation growth.
 *
 * Note: Table data ends at 2022-09-25, so analyzing last 365 days of available data.
 */

SELECT
  CASE
    WHEN score < -5 THEN 'a. Very Negative (<-5)'
    WHEN score < 0 THEN 'b. Negative (-5 to -1)'
    WHEN score = 0 THEN 'c. Zero'
    WHEN score <= 1 THEN 'd. Low Positive (1)'
    WHEN score <= 5 THEN 'e. Moderate (2-5)'
    WHEN score <= 10 THEN 'f. Good (6-10)'
    WHEN score <= 50 THEN 'g. High (11-50)'
    WHEN score <= 100 THEN 'h. Very High (51-100)'
    ELSE 'i. Exceptional (>100)'
  END AS score_bucket,
  COUNT(*) AS question_count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
  ROUND(AVG(view_count), 0) AS avg_views,
  ROUND(AVG(answer_count), 2) AS avg_answers,
  ROUND(SUM(CASE WHEN accepted_answer_id IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_with_accepted_answer
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE creation_date >= '2021-09-25'
  AND creation_date < '2022-09-25'
GROUP BY score_bucket
ORDER BY score_bucket
