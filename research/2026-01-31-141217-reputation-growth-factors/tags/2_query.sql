/*
Query 2: Tag Distribution Analysis - Question Volume Tiers and Documentation Gaps
---------------------------------------------------------------------------------
Purpose: Understand the full distribution of tags across volume tiers to identify
underserved areas where reputation growth may be easier. Also examine documentation
completeness across different tag sizes.

Relevance to reputation growth: Tags with fewer questions but growing activity or
lacking documentation may represent underserved niches where answering questions
could yield higher reputation-per-effort due to less competition.
*/

SELECT
    CASE
        WHEN count >= 1000000 THEN '1. 1M+ questions'
        WHEN count >= 100000 THEN '2. 100K-999K questions'
        WHEN count >= 10000 THEN '3. 10K-99K questions'
        WHEN count >= 1000 THEN '4. 1K-9.9K questions'
        WHEN count >= 100 THEN '5. 100-999 questions'
        ELSE '6. <100 questions'
    END AS volume_tier,
    COUNT(*) AS tag_count,
    SUM(count) AS total_questions,
    ROUND(AVG(count), 0) AS avg_questions_per_tag,
    SUM(CASE WHEN excerpt_post_id IS NOT NULL AND wiki_post_id IS NOT NULL THEN 1 ELSE 0 END) AS fully_documented_count,
    SUM(CASE WHEN excerpt_post_id IS NOT NULL OR wiki_post_id IS NOT NULL THEN 1 ELSE 0 END) AS has_some_docs_count,
    SUM(CASE WHEN excerpt_post_id IS NULL AND wiki_post_id IS NULL THEN 1 ELSE 0 END) AS undocumented_count,
    ROUND(
        100.0 * SUM(CASE WHEN excerpt_post_id IS NOT NULL AND wiki_post_id IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS pct_fully_documented
FROM `bigquery-public-data.stackoverflow.tags`
GROUP BY volume_tier
ORDER BY volume_tier
