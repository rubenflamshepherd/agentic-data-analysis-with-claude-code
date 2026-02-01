/*
Analyze vote type distribution and daily volumes to understand:
1. What types of votes exist in Stack Overflow
2. Their relative frequency (which vote types are most common)
3. Daily voting patterns over the last 90 days of available data

This helps identify which vote types drive reputation and their relative importance.
Note: Data ends at 2022-09-25 - using last 90 days of available data
*/
SELECT
  vote_type_id,
  DATE(creation_date) as vote_date,
  COUNT(*) as vote_count
FROM `bigquery-public-data.stackoverflow.votes`
WHERE creation_date BETWEEN TIMESTAMP('2022-06-28')
                        AND TIMESTAMP('2022-09-25 23:59:59')
GROUP BY vote_type_id, DATE(creation_date)
ORDER BY vote_date DESC, vote_count DESC
