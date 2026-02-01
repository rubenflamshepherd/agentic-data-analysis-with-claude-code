/*
 * Top Badge Names by Award Count
 *
 * Identifies the most frequently awarded badges to understand which specific behaviors
 * drive user engagement and reputation. Non-tag-based badges represent general platform
 * activities (answering, asking, voting) while tag-based badges represent topic expertise.
 */
SELECT
    name AS badge_name,
    CASE class
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
        ELSE 'Unknown'
    END AS badge_class,
    tag_based,
    COUNT(*) AS times_awarded,
    COUNT(DISTINCT user_id) AS unique_recipients,
    ROUND(COUNT(*) / COUNT(DISTINCT user_id), 2) AS avg_awards_per_user
FROM `bigquery-public-data.stackoverflow.badges`
GROUP BY name, class, tag_based
ORDER BY times_awarded DESC
LIMIT 50
