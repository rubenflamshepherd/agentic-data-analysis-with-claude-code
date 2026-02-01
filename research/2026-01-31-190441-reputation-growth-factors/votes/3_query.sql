/*
 * Query 3: Weekly Vote Volume Trends and Reputation Growth Patterns
 *
 * Purpose: Analyze weekly trends in reputation-affecting votes over the 90-day
 * period to identify any growth/decline patterns in the platform's reputation
 * economy. This helps understand whether reputation is becoming easier or harder
 * to earn over time.
 *
 * Calculates:
 * - Weekly vote volumes by type
 * - Week-over-week changes
 * - Net reputation impact per week
 */
WITH weekly_stats AS (
    SELECT
        DATE_TRUNC(DATE(creation_date), WEEK(MONDAY)) AS week_start,
        SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) AS accepted_answers,
        SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
        SUM(CASE WHEN vote_type_id = 3 THEN 1 ELSE 0 END) AS downvotes,
        COUNT(*) AS total_rep_votes,
        -- Estimated reputation (assuming 60% answers, 40% questions for upvotes)
        SUM(CASE WHEN vote_type_id = 1 THEN 15 ELSE 0 END) +
        CAST(SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) * 0.6 * 10 AS INT64) +
        CAST(SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) * 0.4 * 5 AS INT64) -
        SUM(CASE WHEN vote_type_id = 3 THEN 2 ELSE 0 END) AS estimated_rep_created
    FROM `bigquery-public-data.stackoverflow.votes`
    WHERE creation_date BETWEEN '2022-06-27' AND '2022-09-24'
      AND vote_type_id IN (1, 2, 3)
    GROUP BY week_start
)
SELECT
    week_start,
    accepted_answers,
    upvotes,
    downvotes,
    total_rep_votes,
    estimated_rep_created,
    ROUND(SAFE_DIVIDE(upvotes, downvotes), 2) AS up_down_ratio,
    -- Week-over-week changes
    LAG(upvotes) OVER (ORDER BY week_start) AS prev_week_upvotes,
    ROUND(SAFE_DIVIDE(upvotes - LAG(upvotes) OVER (ORDER BY week_start), LAG(upvotes) OVER (ORDER BY week_start)) * 100, 2) AS upvote_wow_pct_change
FROM weekly_stats
ORDER BY week_start
