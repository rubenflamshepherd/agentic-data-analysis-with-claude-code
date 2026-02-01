/*
 * Badge Acquisition Trends by Year and Class
 *
 * Examines how badge awards have changed over time to understand platform growth patterns
 * and whether certain badge classes are becoming more or less common. This reveals
 * whether the community is maturing (more gold badges) or attracting new users (more bronze).
 */
SELECT
    EXTRACT(YEAR FROM date) AS award_year,
    CASE class
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
        ELSE 'Unknown'
    END AS badge_class,
    COUNT(*) AS badges_awarded,
    COUNT(DISTINCT user_id) AS unique_users,
    ROUND(COUNT(*) / COUNT(DISTINCT user_id), 2) AS badges_per_user
FROM `bigquery-public-data.stackoverflow.badges`
WHERE date IS NOT NULL
  AND EXTRACT(YEAR FROM date) >= 2008
  AND EXTRACT(YEAR FROM date) <= 2024
GROUP BY award_year, badge_class
ORDER BY award_year, badge_class
