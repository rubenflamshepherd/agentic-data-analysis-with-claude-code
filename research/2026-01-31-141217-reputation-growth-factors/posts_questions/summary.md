## Table Analysis Complete: posts_questions

### Summary

This analysis examined the `bigquery-public-data.stackoverflow.posts_questions` table to understand factors that drive user reputation growth through question asking on Stack Overflow. The table contains 23 million questions and provides insights into how question volume, quality, engagement, and topic selection affect reputation accumulation.

Key findings:
- **Question quality trumps quantity**: Users who ask fewer questions earn dramatically more reputation per question (186.99 avg score for users with 5-10 questions vs 4.55 for users with 1000+ questions)
- **Most questions earn zero reputation**: 45.65% of questions have a score of zero, and only 3.38% of questions achieve a score of 10 or higher
- **Extreme Pareto concentration**: The top 0.02% of questions (score 500+) contribute 10.97% of all positive reputation from questions
- **Topic selection matters enormously**: Git questions average 12.7 score vs Excel questions at 0.59 - a 21x difference
- **Engagement metrics strongly correlate with score**: High-scoring questions have more views (901K vs 589), more answers (21 vs 1.2), and higher accepted answer rates (91% vs 43%)

### Table Information
- **Size**: 39.9 GB (13.4 GB physical)
- **Rows**: 23,020,127 questions
- **Last Modified**: November 24, 2024
- **Partitioning**: None (full table scan required)

### Queries Generated and Executed

1. **Query 1: User Question Performance Distribution**
   - Description: Analyzes how question scores (which directly contribute to reputation via upvotes) distribute across users. Examines the relationship between question volume, engagement metrics (answers, views, favorites), and score accumulation.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/posts_questions/1_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/posts_questions/1_result.csv`
   - Findings:
      - Among top 10,000 users by question score, mean total score is 1,533 with a max of 39,109
      - Strong inverse relationship between question volume and average score per question: users with 5-10 questions average 186.99 score/question vs 4.55 for users with 1000+ questions
      - Average accepted answer rate among high-scoring users is 72.6%
      - Top 1% of these users (100 users) account for 8.6% of total score; top 10% account for 33.3%

2. **Query 2: Question Score Distribution and Success Factors**
   - Description: Analyzes the distribution of question scores to understand what percentage of questions achieve various score thresholds. Examines the relationship between engagement metrics (views, answers, accepted answers) and score.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/posts_questions/2_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/posts_questions/2_result.csv`
   - Findings:
      - 45.65% of questions have score=0; 7.02% have negative scores; only 0.23% score 100+
      - Questions with 500+ score (top 0.02%) contribute 10.97% of total reputation from questions
      - Views scale 1,500x from zero-score (589 avg) to 500+ score (901,551 avg)
      - Accepted answer rate rises from 43.42% (zero-score) to 90.97% (500+ score)

3. **Query 3: Tag Popularity and Reputation Potential by Topic Area**
   - Description: Analyzes which technology tags are associated with higher average question scores to identify topic areas offering better reputation growth opportunities for question askers.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/posts_questions/3_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/posts_questions/3_result.csv`
   - Findings:
      - Git is an exceptional outlier: 12.7 avg score (5x higher than #2), 9.85% high-score rate
      - Developer tool questions (git, visual-studio, bash, docker) significantly outperform programming language questions
      - Haskell achieves highest high-score rate at 9.64% despite being a niche language
      - Low-reputation tags: Excel (0.59), VB.NET (0.62), WordPress (0.61), VBA (0.74)

### Total Data Processed
2.63 GB (0.827 GB + 0.827 GB + 1.40 GB across three queries)
