/*
 * Query 3: Tag Documentation Coverage Analysis
 *
 * Purpose: Analyze the relationship between tag popularity and documentation
 * completeness (excerpt_post_id and wiki_post_id presence). Tags with
 * documentation may indicate more mature communities with clearer answering
 * guidelines, potentially affecting how users can earn reputation. This also
 * identifies gaps where users could earn reputation by improving tag wikis.
 *
 * Documentation status:
 * - Both: Tags with both excerpt and wiki (fully documented)
 * - Excerpt only: Tags with just summary description
 * - Wiki only: Tags with full wiki but no excerpt (rare)
 * - Neither: Undocumented tags (potential contribution opportunity)
 */
SELECT
    CASE
        WHEN excerpt_post_id IS NOT NULL AND wiki_post_id IS NOT NULL THEN 'Both (excerpt + wiki)'
        WHEN excerpt_post_id IS NOT NULL THEN 'Excerpt only'
        WHEN wiki_post_id IS NOT NULL THEN 'Wiki only'
        ELSE 'No documentation'
    END AS documentation_status,
    COUNT(*) AS num_tags,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_tags,
    SUM(count) AS total_questions,
    ROUND(SUM(count) * 100.0 / SUM(SUM(count)) OVER (), 2) AS pct_of_questions,
    ROUND(AVG(count), 0) AS avg_questions_per_tag,
    -- Include some tag popularity metrics
    ROUND(APPROX_QUANTILES(count, 100)[OFFSET(50)], 0) AS median_questions,
    ROUND(APPROX_QUANTILES(count, 100)[OFFSET(90)], 0) AS p90_questions,
    MAX(count) AS max_questions
FROM `bigquery-public-data.stackoverflow.tags`
GROUP BY 1
ORDER BY total_questions DESC
