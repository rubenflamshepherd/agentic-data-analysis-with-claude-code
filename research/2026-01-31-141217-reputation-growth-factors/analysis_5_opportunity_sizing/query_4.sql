/*
Query 4: Competition Analysis - Answerer Concentration by Domain
----------------------------------------------------------------
Purpose: Understand competition density in each domain by analyzing:
1. Number of unique answerers per domain
2. Average reputation of answerers (quality of competition)
3. High-reputation answerer concentration

This helps identify domains where:
- Fewer experts are present (less competition)
- Questions are more distributed among answerers (easier entry)

Date filter: Last year of data (2021-09 to 2022-09)
*/

WITH domain_questions AS (
    SELECT
        q.id AS question_id,
        CASE
            WHEN LOWER(q.tags) LIKE '%aws%' OR LOWER(q.tags) LIKE '%amazon-%'
                OR LOWER(q.tags) LIKE '%azure%' OR LOWER(q.tags) LIKE '%gcp%'
                OR LOWER(q.tags) LIKE '%google-cloud%' THEN 'Cloud Platform'
            WHEN LOWER(q.tags) LIKE '%docker%' OR LOWER(q.tags) LIKE '%kubernetes%'
                OR LOWER(q.tags) LIKE '%k8s%' OR LOWER(q.tags) LIKE '%terraform%'
                OR LOWER(q.tags) LIKE '%ansible%' OR LOWER(q.tags) LIKE '%jenkins%'
                OR LOWER(q.tags) LIKE '%ci-cd%' OR LOWER(q.tags) LIKE '%devops%'
                OR LOWER(q.tags) LIKE '%helm%' OR LOWER(q.tags) LIKE '%gitlab%' THEN 'DevOps'
            WHEN LOWER(q.tags) LIKE '%tensorflow%' OR LOWER(q.tags) LIKE '%pytorch%'
                OR LOWER(q.tags) LIKE '%keras%' OR LOWER(q.tags) LIKE '%scikit%'
                OR LOWER(q.tags) LIKE '%machine-learning%' OR LOWER(q.tags) LIKE '%deep-learning%'
                OR LOWER(q.tags) LIKE '%neural-network%' OR LOWER(q.tags) LIKE '%nlp%'
                OR LOWER(q.tags) LIKE '%computer-vision%' THEN 'ML/AI'
            WHEN LOWER(q.tags) = 'javascript' OR LOWER(q.tags) LIKE 'javascript|%'
                OR LOWER(q.tags) LIKE '%|javascript|%' OR LOWER(q.tags) LIKE '%|javascript' THEN 'JavaScript (Baseline)'
            WHEN LOWER(q.tags) = 'python' OR LOWER(q.tags) LIKE 'python|%'
                OR LOWER(q.tags) LIKE '%|python|%' OR LOWER(q.tags) LIKE '%|python' THEN 'Python (Baseline)'
            ELSE NULL
        END AS domain
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    WHERE q.creation_date >= TIMESTAMP('2021-09-01')
      AND q.creation_date < TIMESTAMP('2022-09-25')
),

domain_answers AS (
    SELECT
        dq.domain,
        a.id AS answer_id,
        a.owner_user_id,
        a.score AS answer_score,
        a.creation_date
    FROM domain_questions dq
    JOIN `bigquery-public-data.stackoverflow.posts_answers` a
        ON dq.question_id = a.parent_id
    WHERE dq.domain IS NOT NULL
      AND a.owner_user_id IS NOT NULL
),

answerer_with_rep AS (
    SELECT
        da.domain,
        da.owner_user_id,
        da.answer_id,
        da.answer_score,
        u.reputation AS user_reputation
    FROM domain_answers da
    LEFT JOIN `bigquery-public-data.stackoverflow.users` u
        ON da.owner_user_id = u.id
)

SELECT
    domain,
    COUNT(DISTINCT owner_user_id) AS unique_answerers,
    COUNT(*) AS total_answers,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT owner_user_id), 1) AS answers_per_person,
    ROUND(AVG(user_reputation), 0) AS avg_answerer_reputation,
    COUNT(DISTINCT CASE WHEN user_reputation >= 10000 THEN owner_user_id END) AS high_rep_answerers_10k,
    COUNT(DISTINCT CASE WHEN user_reputation >= 50000 THEN owner_user_id END) AS high_rep_answerers_50k,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN user_reputation >= 10000 THEN owner_user_id END) /
          COUNT(DISTINCT owner_user_id), 1) AS high_rep_pct,
    -- Competition index: higher = more competitive
    -- (more total answers) / (more unique answerers) = more saturated
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT owner_user_id), 2) AS competition_index
FROM answerer_with_rep
GROUP BY domain
ORDER BY high_rep_pct ASC
