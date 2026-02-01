/*
 * Query 1: Vote Type Distribution Over Time (Last 90 Days of Available Data)
 *
 * Purpose: Understand which vote types are most common and how they trend
 * over time. This helps identify the primary mechanisms for reputation growth
 * (upvotes on answers = +10, upvotes on questions = +5, accepted answers = +15).
 *
 * Vote types relevant to reputation:
 * - 1 = Accepted answer (+15 for answerer)
 * - 2 = Upvote (+10 for answer, +5 for question)
 * - 3 = Downvote (-2 for post owner, -1 for voter on answers)
 */
SELECT
    DATE(creation_date) AS vote_date,
    vote_type_id,
    COUNT(*) AS vote_count
FROM `bigquery-public-data.stackoverflow.votes`
WHERE creation_date BETWEEN '2022-06-27' AND '2022-09-24'
GROUP BY vote_date, vote_type_id
ORDER BY vote_date, vote_type_id
LIMIT 2000
