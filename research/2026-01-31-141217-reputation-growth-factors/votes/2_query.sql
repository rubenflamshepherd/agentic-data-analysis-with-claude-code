/*
Analyze vote concentration to understand:
1. How votes are distributed across posts (Pareto analysis)
2. What percentage of posts receive the majority of votes
3. Whether votes concentrate on few posts or spread widely

This reveals whether reputation comes from a few highly-voted posts
or is distributed across many posts.
*/
WITH post_votes AS (
  SELECT
    post_id,
    SUM(CASE WHEN vote_type_id = 2 THEN 1 ELSE 0 END) as upvotes,
    SUM(CASE WHEN vote_type_id = 3 THEN 1 ELSE 0 END) as downvotes,
    SUM(CASE WHEN vote_type_id = 1 THEN 1 ELSE 0 END) as accepted,
    COUNT(*) as total_votes
  FROM `bigquery-public-data.stackoverflow.votes`
  WHERE creation_date BETWEEN TIMESTAMP('2022-06-28') AND TIMESTAMP('2022-09-25 23:59:59')
  GROUP BY post_id
),
vote_buckets AS (
  SELECT
    CASE
      WHEN upvotes = 0 THEN '0'
      WHEN upvotes = 1 THEN '1'
      WHEN upvotes BETWEEN 2 AND 5 THEN '2-5'
      WHEN upvotes BETWEEN 6 AND 10 THEN '6-10'
      WHEN upvotes BETWEEN 11 AND 25 THEN '11-25'
      WHEN upvotes BETWEEN 26 AND 50 THEN '26-50'
      WHEN upvotes BETWEEN 51 AND 100 THEN '51-100'
      ELSE '100+'
    END as upvote_bucket,
    COUNT(*) as post_count,
    SUM(upvotes) as total_upvotes,
    SUM(downvotes) as total_downvotes,
    SUM(accepted) as total_accepted
  FROM post_votes
  GROUP BY 1
)
SELECT
  upvote_bucket,
  post_count,
  total_upvotes,
  total_downvotes,
  total_accepted,
  ROUND(post_count * 100.0 / SUM(post_count) OVER(), 2) as pct_of_posts,
  ROUND(total_upvotes * 100.0 / SUM(total_upvotes) OVER(), 2) as pct_of_upvotes
FROM vote_buckets
ORDER BY
  CASE upvote_bucket
    WHEN '0' THEN 1
    WHEN '1' THEN 2
    WHEN '2-5' THEN 3
    WHEN '6-10' THEN 4
    WHEN '11-25' THEN 5
    WHEN '26-50' THEN 6
    WHEN '51-100' THEN 7
    ELSE 8
  END
