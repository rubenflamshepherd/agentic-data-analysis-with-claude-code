/*
Weekly badge award trends over the last 90 days of available data.
This query analyzes weekly patterns in badge awarding to understand temporal
trends in user activity. By segmenting by badge class, we can see if
Gold/Silver/Bronze badges follow different patterns and identify any
seasonality or trends in user engagement.
*/
SELECT
  DATE_TRUNC(DATE(date), WEEK) AS week_start,
  class,
  CASE class
    WHEN 1 THEN 'Gold'
    WHEN 2 THEN 'Silver'
    WHEN 3 THEN 'Bronze'
    ELSE 'Unknown'
  END AS class_name,
  COUNT(*) AS badges_awarded,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(DISTINCT name) AS unique_badge_types
FROM `bigquery-public-data.stackoverflow.badges`
WHERE date BETWEEN TIMESTAMP_SUB(TIMESTAMP('2022-09-25'), INTERVAL 90 DAY)
  AND TIMESTAMP('2022-09-25')
GROUP BY week_start, class
ORDER BY week_start, class
