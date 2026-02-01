/*
Query 1: Domain-Level Opportunity Metrics
-----------------------------------------
Purpose: Compare key opportunity metrics across technology domains to identify
underserved areas with high reputation potential. We analyze:
- Unanswered question rate (supply/demand gap)
- Average time to first answer (urgency indicator)
- Average answer score (quality/competition indicator)

Domains analyzed:
- Opportunity domains: DevOps, ML/AI, Cloud Platform
- Established domains: JavaScript, Python, Java (as baselines)

Date filter: Last 2 years of available data (2020-09-01 to 2022-09-25)
Note: Tags are pipe-separated (e.g., "python|pandas|dataframe")
*/

WITH domain_classified_questions AS (
    SELECT
        q.id AS question_id,
        q.creation_date,
        q.accepted_answer_id,
        q.answer_count,
        q.score AS question_score,
        q.tags,
        CASE
            -- Established domains (baselines)
            WHEN (LOWER(q.tags) = 'javascript'
                  OR LOWER(q.tags) LIKE 'javascript|%'
                  OR LOWER(q.tags) LIKE '%|javascript|%'
                  OR LOWER(q.tags) LIKE '%|javascript')
                 AND LOWER(q.tags) NOT LIKE '%typescript%' THEN 'JavaScript (Baseline)'
            WHEN LOWER(q.tags) = 'python'
                 OR LOWER(q.tags) LIKE 'python|%'
                 OR LOWER(q.tags) LIKE '%|python|%'
                 OR LOWER(q.tags) LIKE '%|python' THEN 'Python (Baseline)'
            WHEN (LOWER(q.tags) = 'java'
                  OR LOWER(q.tags) LIKE 'java|%'
                  OR LOWER(q.tags) LIKE '%|java|%'
                  OR LOWER(q.tags) LIKE '%|java')
                 AND LOWER(q.tags) NOT LIKE '%javascript%' THEN 'Java (Baseline)'

            -- Cloud Platform
            WHEN LOWER(q.tags) LIKE '%aws%' OR LOWER(q.tags) LIKE '%amazon-%'
                OR LOWER(q.tags) LIKE '%azure%' OR LOWER(q.tags) LIKE '%gcp%'
                OR LOWER(q.tags) LIKE '%google-cloud%' THEN 'Cloud Platform'

            -- DevOps
            WHEN LOWER(q.tags) LIKE '%docker%' OR LOWER(q.tags) LIKE '%kubernetes%'
                OR LOWER(q.tags) LIKE '%k8s%' OR LOWER(q.tags) LIKE '%terraform%'
                OR LOWER(q.tags) LIKE '%ansible%' OR LOWER(q.tags) LIKE '%jenkins%'
                OR LOWER(q.tags) LIKE '%ci-cd%' OR LOWER(q.tags) LIKE '%devops%'
                OR LOWER(q.tags) LIKE '%helm%' OR LOWER(q.tags) LIKE '%gitlab%' THEN 'DevOps'

            -- ML/AI
            WHEN LOWER(q.tags) LIKE '%tensorflow%' OR LOWER(q.tags) LIKE '%pytorch%'
                OR LOWER(q.tags) LIKE '%keras%' OR LOWER(q.tags) LIKE '%scikit%'
                OR LOWER(q.tags) LIKE '%machine-learning%' OR LOWER(q.tags) LIKE '%deep-learning%'
                OR LOWER(q.tags) LIKE '%neural-network%' OR LOWER(q.tags) LIKE '%nlp%'
                OR LOWER(q.tags) LIKE '%computer-vision%' THEN 'ML/AI'

            ELSE NULL
        END AS domain
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    WHERE q.creation_date >= TIMESTAMP('2020-09-01')
      AND q.creation_date < TIMESTAMP('2022-09-25')
),

questions_with_first_answer AS (
    SELECT
        dcq.question_id,
        dcq.domain,
        dcq.creation_date AS question_date,
        dcq.accepted_answer_id,
        dcq.answer_count,
        dcq.question_score,
        MIN(a.creation_date) AS first_answer_date,
        AVG(a.score) AS avg_answer_score
    FROM domain_classified_questions dcq
    LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` a
        ON dcq.question_id = a.parent_id
    WHERE dcq.domain IS NOT NULL
    GROUP BY dcq.question_id, dcq.domain, dcq.creation_date, dcq.accepted_answer_id, dcq.answer_count, dcq.question_score
)

SELECT
    domain,
    COUNT(*) AS total_questions,
    COUNTIF(answer_count = 0 OR answer_count IS NULL) AS unanswered_questions,
    ROUND(100.0 * COUNTIF(answer_count = 0 OR answer_count IS NULL) / COUNT(*), 1) AS unanswered_pct,
    COUNTIF(accepted_answer_id IS NOT NULL) AS accepted_answers,
    ROUND(100.0 * COUNTIF(accepted_answer_id IS NOT NULL) / COUNT(*), 1) AS accepted_pct,
    ROUND(AVG(TIMESTAMP_DIFF(first_answer_date, question_date, HOUR)), 1) AS avg_hours_to_first_answer,
    ROUND(AVG(avg_answer_score), 2) AS avg_answer_score,
    ROUND(AVG(question_score), 2) AS avg_question_score,
    ROUND(AVG(answer_count), 1) AS avg_answers_per_question
FROM questions_with_first_answer
GROUP BY domain
ORDER BY unanswered_pct DESC
