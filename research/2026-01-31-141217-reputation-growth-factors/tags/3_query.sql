/*
Query 3: Tag Category Analysis - Identifying Technology Domains and Niches
---------------------------------------------------------------------------
Purpose: Categorize tags by technology domain using naming patterns to understand
which technology areas have the most activity and opportunity. Also identify
version-specific vs generic tags and framework/library ecosystem patterns.

Relevance to reputation growth: Understanding technology domains helps users
identify which ecosystems to focus on. Version-specific tags may indicate
rapidly evolving technologies where up-to-date knowledge is valued.
*/

SELECT
    CASE
        -- Programming languages
        WHEN LOWER(tag_name) IN ('javascript', 'python', 'java', 'c#', 'php', 'c++', 'c', 'ruby', 'swift', 'kotlin', 'go', 'rust', 'typescript', 'scala', 'perl', 'r', 'matlab', 'lua', 'dart', 'objective-c', 'assembly', 'fortran', 'cobol', 'haskell', 'elixir', 'erlang', 'clojure', 'f#', 'groovy')
            THEN 'Programming Language'
        WHEN LOWER(tag_name) LIKE '%python%' OR LOWER(tag_name) LIKE '%java%' OR LOWER(tag_name) LIKE '%javascript%' OR LOWER(tag_name) LIKE '%typescript%' THEN 'Language Ecosystem'

        -- Web frameworks
        WHEN LOWER(tag_name) IN ('django', 'flask', 'fastapi', 'rails', 'ruby-on-rails', 'laravel', 'symfony', 'spring', 'spring-boot', 'express', 'nextjs', 'nuxt', 'gatsby', 'asp.net', 'asp.net-mvc', 'asp.net-core')
            THEN 'Web Framework'
        WHEN LOWER(tag_name) LIKE '%angular%' OR LOWER(tag_name) LIKE '%react%' OR LOWER(tag_name) LIKE '%vue%' THEN 'Frontend Framework'

        -- Databases
        WHEN LOWER(tag_name) IN ('sql', 'mysql', 'postgresql', 'mongodb', 'sqlite', 'oracle', 'sql-server', 'redis', 'elasticsearch', 'cassandra', 'dynamodb', 'firebase', 'neo4j', 'mariadb')
            THEN 'Database'
        WHEN LOWER(tag_name) LIKE '%sql%' OR LOWER(tag_name) LIKE '%database%' OR LOWER(tag_name) LIKE '%db%' THEN 'Database Related'

        -- Cloud & DevOps
        WHEN LOWER(tag_name) LIKE '%aws%' OR LOWER(tag_name) LIKE '%amazon%' OR LOWER(tag_name) LIKE '%azure%' OR LOWER(tag_name) LIKE '%gcp%' OR LOWER(tag_name) LIKE '%google-cloud%' THEN 'Cloud Platform'
        WHEN LOWER(tag_name) LIKE '%docker%' OR LOWER(tag_name) LIKE '%kubernetes%' OR LOWER(tag_name) LIKE '%k8s%' OR LOWER(tag_name) LIKE '%terraform%' OR LOWER(tag_name) LIKE '%ansible%' OR LOWER(tag_name) LIKE '%jenkins%' THEN 'DevOps'

        -- Mobile
        WHEN LOWER(tag_name) LIKE '%android%' OR LOWER(tag_name) LIKE '%ios%' OR LOWER(tag_name) LIKE '%iphone%' OR LOWER(tag_name) LIKE '%swift%' OR LOWER(tag_name) LIKE '%flutter%' OR LOWER(tag_name) LIKE '%react-native%' THEN 'Mobile Development'

        -- Data Science / ML
        WHEN LOWER(tag_name) LIKE '%pandas%' OR LOWER(tag_name) LIKE '%numpy%' OR LOWER(tag_name) LIKE '%tensorflow%' OR LOWER(tag_name) LIKE '%pytorch%' OR LOWER(tag_name) LIKE '%keras%' OR LOWER(tag_name) LIKE '%scikit%' OR LOWER(tag_name) LIKE '%machine-learning%' OR LOWER(tag_name) LIKE '%deep-learning%' THEN 'Data Science / ML'

        -- Version-specific tags
        WHEN REGEXP_CONTAINS(LOWER(tag_name), r'[0-9]+\.[0-9]+') THEN 'Version-Specific'

        ELSE 'Other'
    END AS technology_domain,
    COUNT(*) AS tag_count,
    SUM(count) AS total_questions,
    ROUND(AVG(count), 0) AS avg_questions_per_tag,
    MAX(count) AS max_questions_in_domain,
    SUM(CASE WHEN excerpt_post_id IS NOT NULL AND wiki_post_id IS NOT NULL THEN 1 ELSE 0 END) AS fully_documented_count,
    ROUND(100.0 * SUM(CASE WHEN excerpt_post_id IS NOT NULL AND wiki_post_id IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_documented
FROM `bigquery-public-data.stackoverflow.tags`
GROUP BY technology_domain
ORDER BY total_questions DESC
