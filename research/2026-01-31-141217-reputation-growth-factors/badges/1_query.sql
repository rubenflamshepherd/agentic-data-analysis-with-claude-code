/*
 * Badge Distribution Analysis
 *
 * Analyzes the distribution of badges by class (Gold/Silver/Bronze) and type (tag-based vs general).
 * This helps understand what activities drive badge acquisition, which correlates with reputation growth.
 * Gold badges are rare and indicate significant contributions; Bronze badges are common entry-level achievements.
 */
SELECT
    CASE class
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
        ELSE 'Unknown'
    END AS badge_class,
    tag_based,
    COUNT(*) AS badge_count,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT name) AS unique_badge_names,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM `bigquery-public-data.stackoverflow.badges`
GROUP BY class, tag_based
ORDER BY class, tag_based
