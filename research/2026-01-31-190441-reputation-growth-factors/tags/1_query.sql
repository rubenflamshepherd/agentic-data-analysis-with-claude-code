/*
 * Query 1: Top Tags by Question Count
 *
 * Purpose: Identify the most popular technology tags on Stack Overflow.
 * Tags with high question counts represent areas where users have more
 * opportunities to answer questions and earn reputation. Understanding
 * which technologies dominate can inform reputation growth strategies.
 *
 * Note: The tags table is a reference table without date partitioning.
 * The 'count' field represents cumulative questions tagged with each tag.
 */
SELECT
    tag_name,
    count AS question_count,
    -- Calculate percentage of total questions this tag represents
    ROUND(count * 100.0 / SUM(count) OVER (), 4) AS pct_of_total,
    -- Calculate cumulative percentage for Pareto analysis
    ROUND(SUM(count) OVER (ORDER BY count DESC) * 100.0 / SUM(count) OVER (), 2) AS cumulative_pct,
    -- Rank by popularity
    RANK() OVER (ORDER BY count DESC) AS popularity_rank
FROM `bigquery-public-data.stackoverflow.tags`
WHERE count > 0
ORDER BY count DESC
LIMIT 100
