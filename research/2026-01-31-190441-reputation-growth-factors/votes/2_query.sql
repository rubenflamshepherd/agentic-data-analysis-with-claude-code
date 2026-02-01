/*
 * Query 2: Day-of-Week Patterns for Reputation-Affecting Votes
 *
 * Purpose: Analyze which days of the week generate the most reputation-affecting
 * votes to understand optimal times for content contribution. This helps identify
 * when users should focus on answering questions to maximize reputation gain.
 *
 * Vote types analyzed:
 * - 1 = Accepted answer (+15 for answerer)
 * - 2 = Upvote (+10 for answer, +5 for question)
 * - 3 = Downvote (-2 for post owner)
 *
 * Calculates estimated reputation delta assuming 60% of upvotes go to answers.
 */
SELECT
    FORMAT_DATE('%A', DATE(creation_date)) AS day_of_week,
    EXTRACT(DAYOFWEEK FROM creation_date) AS day_num,
    COUNT(*) AS total_votes,
    SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) AS accepted_answers,
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) AS upvotes,
    SUM(CASE WHEN vote_type_id = 3 THEN 1 ELSE 0 END) AS downvotes,
    -- Estimated reputation impact (assuming 60% of upvotes go to answers at +10, 40% to questions at +5)
    SUM(CASE WHEN vote_type_id = 1 THEN 15 ELSE 0 END) +
    SUM(CASE WHEN vote_type_id = 2 THEN 8 ELSE 0 END) -  -- weighted average of 10 and 5
    SUM(CASE WHEN vote_type_id = 3 THEN 2 ELSE 0 END) AS estimated_rep_delta,
    -- Ratios
    ROUND(SAFE_DIVIDE(
        SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END),
        SUM(CASE WHEN vote_type_id = 3 THEN 1 ELSE 0 END)
    ), 2) AS upvote_to_downvote_ratio,
    COUNT(DISTINCT DATE(creation_date)) AS num_days
FROM `bigquery-public-data.stackoverflow.votes`
WHERE creation_date BETWEEN '2022-06-27' AND '2022-09-24'
  AND vote_type_id IN (1, 2, 3)
GROUP BY day_of_week, day_num
ORDER BY day_num
