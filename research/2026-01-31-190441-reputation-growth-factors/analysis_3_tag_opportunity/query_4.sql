/*
Query 4: Tag Category Comparison for New User Strategy

Purpose: Group tags into technology categories and compare opportunity metrics
across categories to help new users decide which domain to focus on.

Categories:
- Data Science (python, r, pandas, numpy, tensorflow, etc.)
- Web Frontend (javascript, reactjs, angular, vue, css, html)
- Web Backend (node.js, django, flask, php, ruby-on-rails)
- Mobile (android, ios, flutter, react-native, swift, kotlin)
- Systems/Low-level (c, c++, rust, assembly)
- DevOps/Cloud (docker, kubernetes, aws, azure, terraform)
- Databases (sql, mysql, postgresql, mongodb)
*/

WITH answer_with_tags AS (
  SELECT
    a.id AS answer_id,
    a.score AS answer_score,
    a.owner_user_id,
    q.id AS question_id,
    q.tags,
    q.accepted_answer_id,
    CASE WHEN a.id = q.accepted_answer_id THEN 1 ELSE 0 END AS is_accepted
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  INNER JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id
  WHERE a.creation_date >= '2020-01-01'
    AND a.creation_date < '2024-01-01'
),

answer_tags AS (
  SELECT
    answer_id,
    answer_score,
    owner_user_id,
    question_id,
    is_accepted,
    TRIM(tag) AS tag
  FROM answer_with_tags,
  UNNEST(SPLIT(REPLACE(tags, '|', ','), ',')) AS tag
  WHERE TRIM(tag) != ''
),

categorized_tags AS (
  SELECT
    *,
    CASE
      WHEN tag IN ('python', 'r', 'pandas', 'numpy', 'tensorflow', 'pytorch', 'keras',
                   'scikit-learn', 'matplotlib', 'dataframe', 'machine-learning',
                   'deep-learning', 'data-science', 'jupyter-notebook', 'ggplot2',
                   'dplyr', 'tidyverse', 'seaborn', 'plotly') THEN 'Data Science'
      WHEN tag IN ('javascript', 'reactjs', 'angular', 'vue.js', 'typescript',
                   'html', 'css', 'jquery', 'next.js', 'svelte', 'webpack',
                   'sass', 'tailwind-css', 'bootstrap', 'react-hooks') THEN 'Web Frontend'
      WHEN tag IN ('node.js', 'django', 'flask', 'php', 'ruby-on-rails', 'express',
                   'spring', 'spring-boot', 'laravel', 'asp.net', 'asp.net-core',
                   'fastapi', 'rails', 'ruby') THEN 'Web Backend'
      WHEN tag IN ('android', 'ios', 'flutter', 'react-native', 'swift', 'kotlin',
                   'swiftui', 'dart', 'android-studio', 'xcode', 'objective-c',
                   'xamarin') THEN 'Mobile'
      WHEN tag IN ('c', 'c++', 'rust', 'assembly', 'haskell', 'go', 'zig',
                   'c++17', 'c++20', 'cmake', 'makefile') THEN 'Systems/Low-level'
      WHEN tag IN ('docker', 'kubernetes', 'amazon-web-services', 'azure',
                   'google-cloud-platform', 'terraform', 'jenkins', 'github-actions',
                   'ci-cd', 'devops', 'nginx', 'linux', 'bash', 'shell') THEN 'DevOps/Cloud'
      WHEN tag IN ('sql', 'mysql', 'postgresql', 'mongodb', 'sql-server', 'oracle',
                   'sqlite', 'redis', 'elasticsearch', 'firebase', 'dynamodb',
                   'google-bigquery', 'snowflake-cloud-data-platform') THEN 'Databases'
      ELSE 'Other'
    END AS category
  FROM answer_tags
),

category_metrics AS (
  SELECT
    category,
    COUNT(DISTINCT answer_id) AS total_answers,
    COUNT(DISTINCT owner_user_id) AS unique_answerers,
    COUNT(DISTINCT question_id) AS unique_questions,
    SUM(answer_score) AS total_score,
    AVG(answer_score) AS avg_score_per_answer,
    SAFE_DIVIDE(SUM(is_accepted), COUNT(DISTINCT answer_id)) AS acceptance_rate,
    SAFE_DIVIDE(COUNT(DISTINCT answer_id), COUNT(DISTINCT question_id)) AS answers_per_question,
    SAFE_DIVIDE(COUNT(DISTINCT question_id), COUNT(DISTINCT owner_user_id)) AS questions_per_answerer
  FROM categorized_tags
  WHERE category != 'Other'
  GROUP BY category
)

SELECT
  category,
  total_answers,
  unique_answerers,
  unique_questions,
  ROUND(avg_score_per_answer, 3) AS avg_score,
  ROUND(acceptance_rate * 100, 2) AS accept_rate_pct,
  ROUND(answers_per_question, 2) AS answers_per_q,
  ROUND(questions_per_answerer, 2) AS questions_per_answerer,
  ROUND(total_score * 1.0 / unique_answerers, 2) AS avg_total_score_per_user,
  -- Expected annual reputation if answering 1 question per day
  ROUND(365 * avg_score_per_answer * 10, 0) AS est_annual_rep_1pd,
  -- Opportunity ranking
  ROUND(
    (avg_score_per_answer * acceptance_rate * questions_per_answerer) / answers_per_question * 100,
    2
  ) AS opportunity_index,
  RANK() OVER (ORDER BY
    (avg_score_per_answer * acceptance_rate * questions_per_answerer) / answers_per_question DESC
  ) AS opportunity_rank
FROM category_metrics
ORDER BY opportunity_index DESC
