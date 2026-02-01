/*
Query 3: Untapped Reputation Potential Estimation
-------------------------------------------------
Purpose: Quantify the total reputation opportunity in underserved domains by:
1. Counting unanswered questions in each domain
2. Estimating potential reputation from answering them based on:
   - Base answer upvote rate in that domain (using answered questions as proxy)
   - Accepted answer rate when answered
   - Applying SO reputation formula: upvote=+10, accepted=+15

Key assumptions:
- A new answer would earn similar upvotes to existing answered questions
- Acceptance rate would match current domain acceptance rate
- This is a theoretical maximum - actual results vary with answer quality

Date filter: Last year of data (2021-09 to 2022-09) for most recent patterns
*/

WITH domain_questions AS (
    SELECT
        q.id AS question_id,
        q.creation_date,
        q.answer_count,
        q.accepted_answer_id,
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
            -- Baselines
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

answered_question_stats AS (
    SELECT
        dq.domain,
        dq.question_id,
        AVG(a.score) AS avg_answer_score_per_q
    FROM domain_questions dq
    JOIN `bigquery-public-data.stackoverflow.posts_answers` a
        ON dq.question_id = a.parent_id
    WHERE dq.domain IS NOT NULL
      AND dq.answer_count > 0
    GROUP BY dq.domain, dq.question_id
),

domain_answer_quality AS (
    SELECT
        domain,
        COUNT(*) AS answered_questions,
        AVG(avg_answer_score_per_q) AS avg_score_when_answered
    FROM answered_question_stats
    GROUP BY domain
),

domain_summary AS (
    SELECT
        dq.domain,
        COUNT(*) AS total_questions,
        COUNTIF(dq.answer_count = 0 OR dq.answer_count IS NULL) AS unanswered_questions,
        COUNTIF(dq.accepted_answer_id IS NOT NULL) AS accepted_answers,
        ROUND(100.0 * COUNTIF(dq.accepted_answer_id IS NOT NULL) /
              NULLIF(COUNTIF(dq.answer_count > 0), 0), 1) AS acceptance_rate_when_answered
    FROM domain_questions dq
    WHERE dq.domain IS NOT NULL
    GROUP BY dq.domain
)

SELECT
    ds.domain,
    ds.total_questions,
    ds.unanswered_questions,
    ROUND(100.0 * ds.unanswered_questions / ds.total_questions, 1) AS unanswered_pct,
    ds.acceptance_rate_when_answered,
    ROUND(daq.avg_score_when_answered, 2) AS avg_upvotes_per_answer,

    -- Reputation potential calculation
    -- If we answered all unanswered questions and got:
    -- - Base 10 rep per answer
    -- - Average upvotes * 10 (estimated from domain avg)
    -- - Acceptance bonus (15) * acceptance rate
    ROUND(ds.unanswered_questions * (
        10 +  -- Base answer
        (COALESCE(daq.avg_score_when_answered, 0) * 10) +  -- Expected upvote rep
        (ds.acceptance_rate_when_answered / 100.0 * 15)   -- Expected acceptance rep
    ), 0) AS total_potential_reputation,

    -- Per-answer expected reputation
    ROUND(10 + (COALESCE(daq.avg_score_when_answered, 0) * 10) + (ds.acceptance_rate_when_answered / 100.0 * 15), 1) AS expected_rep_per_answer,

    -- Questions per day (run rate over ~390 days in period)
    ROUND(ds.unanswered_questions / 390.0, 1) AS unanswered_per_day

FROM domain_summary ds
LEFT JOIN domain_answer_quality daq ON ds.domain = daq.domain
ORDER BY total_potential_reputation DESC
