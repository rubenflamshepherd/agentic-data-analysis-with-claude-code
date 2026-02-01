/*
Query 2: Tag-Level Opportunity Ranking
--------------------------------------
Purpose: Identify specific tags within DevOps, ML/AI, and Cloud domains
that offer the best reputation opportunity.

Opportunity Score = question_volume * unanswered_rate * avg_answer_score_when_answered

This formula balances:
- Volume: enough questions to matter
- Unanswered rate: supply gap (underserved)
- Avg answer score: quality premium when good answers are provided

Date filter: 2020-09 to 2022-09 (2 years of available data)
*/

WITH tag_metrics AS (
    SELECT
        t.tag_name,
        t.count AS total_tag_questions,
        CASE
            WHEN LOWER(t.tag_name) LIKE '%aws%' OR LOWER(t.tag_name) LIKE '%amazon-%'
                OR LOWER(t.tag_name) LIKE '%azure%' OR LOWER(t.tag_name) LIKE '%gcp%'
                OR LOWER(t.tag_name) LIKE '%google-cloud%' THEN 'Cloud Platform'
            WHEN LOWER(t.tag_name) LIKE '%docker%' OR LOWER(t.tag_name) LIKE '%kubernetes%'
                OR LOWER(t.tag_name) LIKE '%k8s%' OR LOWER(t.tag_name) LIKE '%terraform%'
                OR LOWER(t.tag_name) LIKE '%ansible%' OR LOWER(t.tag_name) LIKE '%jenkins%'
                OR LOWER(t.tag_name) LIKE '%ci-cd%' OR LOWER(t.tag_name) LIKE '%devops%'
                OR LOWER(t.tag_name) LIKE '%helm%' OR LOWER(t.tag_name) LIKE '%gitlab%' THEN 'DevOps'
            WHEN LOWER(t.tag_name) LIKE '%tensorflow%' OR LOWER(t.tag_name) LIKE '%pytorch%'
                OR LOWER(t.tag_name) LIKE '%keras%' OR LOWER(t.tag_name) LIKE '%scikit%'
                OR LOWER(t.tag_name) LIKE '%machine-learning%' OR LOWER(t.tag_name) LIKE '%deep-learning%'
                OR LOWER(t.tag_name) LIKE '%neural-network%' OR LOWER(t.tag_name) LIKE '%nlp%'
                OR LOWER(t.tag_name) LIKE '%computer-vision%' THEN 'ML/AI'
            ELSE NULL
        END AS domain
    FROM `bigquery-public-data.stackoverflow.tags` t
    WHERE t.count >= 500  -- Minimum volume threshold
),

question_stats AS (
    SELECT
        tm.tag_name,
        tm.domain,
        tm.total_tag_questions,
        COUNT(DISTINCT q.id) AS recent_questions,
        COUNTIF(q.answer_count = 0 OR q.answer_count IS NULL) AS unanswered,
        COUNTIF(q.accepted_answer_id IS NOT NULL) AS has_accepted,
        AVG(q.score) AS avg_question_score
    FROM tag_metrics tm
    JOIN `bigquery-public-data.stackoverflow.posts_questions` q
        ON LOWER(q.tags) LIKE CONCAT('%', LOWER(tm.tag_name), '%')
    WHERE tm.domain IS NOT NULL
      AND q.creation_date >= TIMESTAMP('2020-09-01')
      AND q.creation_date < TIMESTAMP('2022-09-25')
    GROUP BY tm.tag_name, tm.domain, tm.total_tag_questions
),

answer_quality AS (
    SELECT
        qs.tag_name,
        AVG(a.score) AS avg_answer_score
    FROM question_stats qs
    JOIN `bigquery-public-data.stackoverflow.posts_questions` q
        ON LOWER(q.tags) LIKE CONCAT('%', LOWER(qs.tag_name), '%')
    JOIN `bigquery-public-data.stackoverflow.posts_answers` a
        ON q.id = a.parent_id
    WHERE q.creation_date >= TIMESTAMP('2020-09-01')
      AND q.creation_date < TIMESTAMP('2022-09-25')
    GROUP BY qs.tag_name
)

SELECT
    qs.domain,
    qs.tag_name,
    qs.total_tag_questions,
    qs.recent_questions,
    qs.unanswered,
    ROUND(100.0 * qs.unanswered / NULLIF(qs.recent_questions, 0), 1) AS unanswered_pct,
    qs.has_accepted,
    ROUND(100.0 * qs.has_accepted / NULLIF(qs.recent_questions, 0), 1) AS acceptance_rate,
    ROUND(aq.avg_answer_score, 2) AS avg_answer_score,
    -- Opportunity Score: volume * unanswered_rate * quality_premium
    ROUND(
        qs.recent_questions *
        (qs.unanswered / NULLIF(qs.recent_questions, 0)) *
        COALESCE(aq.avg_answer_score, 0.5),
        0
    ) AS opportunity_score
FROM question_stats qs
LEFT JOIN answer_quality aq ON qs.tag_name = aq.tag_name
WHERE qs.recent_questions >= 100  -- Filter to meaningful volume
ORDER BY opportunity_score DESC
LIMIT 50
