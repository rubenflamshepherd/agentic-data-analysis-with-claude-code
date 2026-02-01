/*
Analyze weekly voting trends and day-of-week patterns to understand:
1. Weekly volume trends - is voting activity growing, stable, or declining?
2. Day-of-week patterns - when do most upvotes/downvotes occur?
3. Ratio of upvotes to downvotes by day

This reveals temporal patterns that affect reputation growth timing.
*/
SELECT
  DATE_TRUNC(DATE(creation_date), WEEK(MONDAY)) as week_start,
  EXTRACT(DAYOFWEEK FROM creation_date) as day_of_week,
  CASE EXTRACT(DAYOFWEEK FROM creation_date)
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END as day_name,
  SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) as upvotes,
  SUM(CASE WHEN vote_type_id = 3 THEN 1 ELSE 0 END) as downvotes,
  SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) as accepted,
  COUNT(*) as total_votes,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END),
    SUM(CASE WHEN vote_type_id = 3 THEN 1 ELSE 0 END)
  ), 2) as upvote_downvote_ratio
FROM `bigquery-public-data.stackoverflow.votes`
WHERE creation_date BETWEEN TIMESTAMP('2022-06-28') AND TIMESTAMP('2022-09-25 23:59:59')
GROUP BY 1, 2, 3
ORDER BY week_start, day_of_week
