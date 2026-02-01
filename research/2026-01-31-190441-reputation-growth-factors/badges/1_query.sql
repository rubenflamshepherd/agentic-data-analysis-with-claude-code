/*
Badge distribution by class and tag-based status.
This query examines the types of badges earned in the last 90 days of available data
to understand which badge categories (Gold/Silver/Bronze) and whether tag-based vs
general badges are more commonly earned. This provides insight into which activities
drive badge acquisition, a factor in user engagement and reputation growth.
*/
SELECT
  class,
  CASE class
    WHEN 1 THEN 'Gold'
    WHEN 2 THEN 'Silver'
    WHEN 3 THEN 'Bronze'
    ELSE 'Unknown'
  END AS class_name,
  tag_based,
  COUNT(*) AS badge_count,
  COUNT(DISTINCT user_id) AS unique_users,
  COUNT(DISTINCT name) AS unique_badge_types,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM `bigquery-public-data.stackoverflow.badges`
WHERE date BETWEEN TIMESTAMP_SUB(TIMESTAMP('2022-09-25'), INTERVAL 90 DAY)
  AND TIMESTAMP('2022-09-25')
GROUP BY class, tag_based
ORDER BY class, tag_based
