/*
 * Query 2: Tag Distribution by Question Count Buckets
 *
 * Purpose: Analyze the distribution of tags by question volume to understand
 * the long-tail characteristics of Stack Overflow topics. This reveals whether
 * reputation growth opportunities are concentrated in a few popular tags or
 * distributed across many niche topics.
 *
 * Buckets represent different scales of tag activity:
 * - High-volume tags (100K+): Major technologies with massive question bases
 * - Medium-volume tags (10K-100K): Established but more specialized topics
 * - Low-volume tags (1K-10K): Niche technologies or specific use cases
 * - Very low tags (<1K): Emerging, deprecated, or highly specialized topics
 */
SELECT
    CASE
        WHEN count >= 1000000 THEN '1M+ questions'
        WHEN count >= 100000 THEN '100K-1M questions'
        WHEN count >= 10000 THEN '10K-100K questions'
        WHEN count >= 1000 THEN '1K-10K questions'
        WHEN count >= 100 THEN '100-1K questions'
        WHEN count >= 10 THEN '10-100 questions'
        ELSE '<10 questions'
    END AS question_count_bucket,
    COUNT(*) AS num_tags,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_tags,
    SUM(count) AS total_questions_in_bucket,
    ROUND(SUM(count) * 100.0 / SUM(SUM(count)) OVER (), 2) AS pct_of_questions,
    MIN(count) AS min_questions_in_bucket,
    MAX(count) AS max_questions_in_bucket,
    ROUND(AVG(count), 0) AS avg_questions_per_tag
FROM `bigquery-public-data.stackoverflow.tags`
GROUP BY 1
ORDER BY
    CASE question_count_bucket
        WHEN '1M+ questions' THEN 1
        WHEN '100K-1M questions' THEN 2
        WHEN '10K-100K questions' THEN 3
        WHEN '1K-10K questions' THEN 4
        WHEN '100-1K questions' THEN 5
        WHEN '10-100 questions' THEN 6
        ELSE 7
    END
