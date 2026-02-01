/*
Query 1: Top Tags by Question Volume and Documentation Status
-------------------------------------------------------------
Purpose: Identify the most active tags on Stack Overflow and their documentation
completeness. Tags with high usage counts represent areas where answering questions
could maximize reputation opportunities. Also checking documentation status
(excerpt_post_id and wiki_post_id) to understand tag maturity.

Relevance to reputation growth: Users can strategically focus on high-volume tags
to maximize exposure and potential upvotes.
*/

SELECT
    tag_name,
    count AS question_count,
    CASE WHEN excerpt_post_id IS NOT NULL THEN 1 ELSE 0 END AS has_excerpt,
    CASE WHEN wiki_post_id IS NOT NULL THEN 1 ELSE 0 END AS has_wiki,
    CASE
        WHEN excerpt_post_id IS NOT NULL AND wiki_post_id IS NOT NULL THEN 'Fully Documented'
        WHEN excerpt_post_id IS NOT NULL OR wiki_post_id IS NOT NULL THEN 'Partially Documented'
        ELSE 'Undocumented'
    END AS documentation_status,
    RANK() OVER (ORDER BY count DESC) AS popularity_rank
FROM `bigquery-public-data.stackoverflow.tags`
ORDER BY count DESC
LIMIT 500
