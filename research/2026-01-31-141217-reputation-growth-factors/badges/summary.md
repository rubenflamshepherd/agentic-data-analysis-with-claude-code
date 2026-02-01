## Table Analysis Complete: badges

### Summary

Analysis of the Stack Overflow badges table reveals key factors that drive user reputation growth. The badge system rewards three primary behaviors: (1) asking questions that attract views, (2) providing high-quality answers, and (3) sustained platform engagement over time. Bronze badges dominate at 75% of all awards, indicating that early-stage achievements (profile completion, first upvote, first answer) are the most common. The steep pyramid from Bronze (8.6M users) to Silver (1.7M) to Gold (522K) shows that sustained contribution is rare. Historical trends show platform engagement peaked 2017-2021, with declining badges-per-user ratios suggesting a shift from power users to casual participants.

### Table Information
- **Size**: 2.1 GB
- **Total Rows**: 46,135,386
- **Date range analyzed**: Full table (2008-2022)
- **Last modified**: Nov 24, 2024

### Queries Generated and Executed

1. **Query 1: Badge Distribution by Class and Type**
   - Description: Analyzes the distribution of badges by class (Gold/Silver/Bronze) and type (tag-based vs general). This helps understand what activities drive badge acquisition, which correlates with reputation growth.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/badges/1_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/badges/1_result.csv`
   - Findings:
      - Bronze badges make up 75.23% of all badges (34.7M total), indicating early-stage achievements are most common
      - Tag-based badges represent only 0.49% of all badges, suggesting deep topic expertise is rare
      - User penetration shows 5:1 drop-off ratio at each tier: Bronze (8.6M) -> Silver (1.7M) -> Gold (522K)
      - Gold badges represent only 2.85% of total badges, marking elite contributor status

2. **Query 2: Top Badge Names by Award Count**
   - Description: Identifies the most frequently awarded badges to understand which specific behaviors drive user engagement and reputation.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/badges/2_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/badges/2_result.csv`
   - Findings:
      - Question quality drives most badges: "Popular Question" (6.7M), "Notable Question" (3.3M), "Famous Question" (960K)
      - Onboarding funnel shows 36% drop-off from Student (2.98M) to Teacher (1.91M) - question-askers who never become answerers
      - Answer quality follows Pareto distribution: Nice (1.6M) -> Good (572K) -> Great (109K) shows steep quality pyramid
      - "Yearling" badge (741K users with 3M awards, avg 4.06 per user) indicates engaged users stay for multiple years

3. **Query 3: Badge Acquisition Trends by Year**
   - Description: Examines how badge awards have changed over time to understand platform growth patterns and whether the community is maturing or attracting new users.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/badges/3_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/badges/3_result.csv`
   - Findings:
      - Platform activity peaked 2016-2021 with ~3.2-3.4M bronze badges annually, dropping 26% to 2.4M in 2022
      - Badges-per-user ratio declined 72%: from 5.17 (2008) to 1.45 (2022), indicating shift from power users to casual participants
      - Gold badge unique recipients peaked at 112K in 2021, down to 83K in 2022
      - Silver badge growth (3.6K users in 2008 to 656K in 2019) shows sustained engaged middle-tier growth

### Total Data Processed
3.74 GB (1.27 GB + 1.36 GB + 1.11 GB)
