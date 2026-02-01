/*
Top 30 most frequently earned badges in the last 90 days of available data.
This query identifies which specific badges are most commonly awarded, providing
insight into the primary activities and achievements that drive user engagement
on Stack Overflow. Badge names reveal which behaviors (e.g., answering questions,
voting, profile completion) are most incentivized.
*/
SELECT
  name AS badge_name,
  class,
  CASE class
    WHEN 1 THEN 'Gold'
    WHEN 2 THEN 'Silver'
    WHEN 3 THEN 'Bronze'
    ELSE 'Unknown'
  END AS class_name,
  tag_based,
  COUNT(*) AS times_awarded,
  COUNT(DISTINCT user_id) AS unique_recipients,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM `bigquery-public-data.stackoverflow.badges`
WHERE date BETWEEN TIMESTAMP_SUB(TIMESTAMP('2022-09-25'), INTERVAL 90 DAY)
  AND TIMESTAMP('2022-09-25')
GROUP BY name, class, tag_based
ORDER BY times_awarded DESC
LIMIT 30
