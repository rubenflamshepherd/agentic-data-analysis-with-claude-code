/*
 * Query 3: Response Time Analysis - Speed to Answer
 *
 * Purpose: Compare how quickly power users vs average users respond to questions.
 * Fast responders may capture more upvotes and accepted answers.
 *
 * Analysis:
 * - Average time between question creation and answer creation
 * - Distribution of response times (percentiles)
 * - Correlation between response speed and answer success
 */

WITH user_cohorts AS (
  SELECT
    id as user_id,
    reputation,
    CASE
      WHEN reputation >= 1419 THEN 'power_user_top1pct'  -- Using threshold from query 1
      WHEN reputation BETWEEN 1 AND 100 THEN 'average_user_1_100rep'
      ELSE 'other'
    END as cohort
  FROM `bigquery-public-data.stackoverflow.users`
  WHERE reputation >= 1
),

answer_response_times AS (
  SELECT
    a.owner_user_id as user_id,
    a.id as answer_id,
    a.score as answer_score,
    a.creation_date as answer_date,
    q.creation_date as question_date,
    TIMESTAMP_DIFF(a.creation_date, q.creation_date, MINUTE) as response_time_minutes,
    CASE WHEN q.accepted_answer_id = a.id THEN 1 ELSE 0 END as is_accepted
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.owner_user_id IS NOT NULL
    AND q.creation_date IS NOT NULL
    AND a.creation_date >= q.creation_date  -- Filter out invalid timestamps
    AND TIMESTAMP_DIFF(a.creation_date, q.creation_date, DAY) <= 365  -- Only answers within 1 year
)

SELECT
  c.cohort,
  COUNT(*) as total_answers,
  -- Response time metrics
  ROUND(AVG(r.response_time_minutes), 1) as avg_response_time_minutes,
  ROUND(AVG(r.response_time_minutes) / 60, 2) as avg_response_time_hours,
  -- Percentile distribution of response times
  ROUND(APPROX_QUANTILES(r.response_time_minutes, 100)[OFFSET(50)] / 60, 2) as median_response_time_hours,
  ROUND(APPROX_QUANTILES(r.response_time_minutes, 100)[OFFSET(25)] / 60, 2) as p25_response_time_hours,
  ROUND(APPROX_QUANTILES(r.response_time_minutes, 100)[OFFSET(75)] / 60, 2) as p75_response_time_hours,
  -- Speed buckets
  ROUND(SAFE_DIVIDE(COUNTIF(r.response_time_minutes <= 60), COUNT(*)) * 100, 2) as pct_answered_within_1hr,
  ROUND(SAFE_DIVIDE(COUNTIF(r.response_time_minutes <= 1440), COUNT(*)) * 100, 2) as pct_answered_within_24hr,
  -- Success by speed
  ROUND(AVG(CASE WHEN r.response_time_minutes <= 60 THEN r.answer_score END), 3) as avg_score_when_answered_within_1hr,
  ROUND(AVG(CASE WHEN r.response_time_minutes > 1440 THEN r.answer_score END), 3) as avg_score_when_answered_after_24hr,
  -- Acceptance rate
  ROUND(AVG(r.is_accepted) * 100, 2) as acceptance_rate_pct,
  ROUND(AVG(CASE WHEN r.response_time_minutes <= 60 THEN r.is_accepted END) * 100, 2) as acceptance_rate_when_within_1hr_pct
FROM user_cohorts c
JOIN answer_response_times r ON c.user_id = r.user_id
WHERE c.cohort IN ('power_user_top1pct', 'average_user_1_100rep')
GROUP BY c.cohort
ORDER BY avg_response_time_minutes;
