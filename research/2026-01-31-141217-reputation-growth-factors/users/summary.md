## Table Analysis Complete: users

### Summary

Analysis of the Stack Overflow `users` table reveals that reputation growth is driven by a combination of **account tenure** and **active community participation** (particularly voting behavior). The distribution of reputation is extremely concentrated: 76.5% of users have a reputation of exactly 1, while just 0.02% of users ("legends" with 50,000+ reputation) hold 20.6% of all reputation on the platform.

Key factors correlated with reputation growth:
1. **Time on platform**: Average reputation increases from 2.25 (4-year accounts) to 9,328 (18-year accounts)
2. **Voting activity**: Users who cast 1000+ votes have 4,765x higher median reputation than non-voters
3. **Profile engagement**: High-reputation users receive dramatically more profile views (13,177 vs 0.91 for newcomers)

The vast majority of users (90.1%) never cast a single upvote and remain at minimal reputation levels regardless of account age.

### Table Information
- **Size**: 3.37 GB
- **Total rows**: 18,712,212 users
- **Last modified**: 24 Nov 2024
- **Partitioning**: None (dimension table)

### Queries Generated and Executed

1. **Query 1: Reputation Distribution by Account Tenure**
   - Description: Examines how reputation varies by account age (years since creation), to understand the relationship between time on platform and reputation growth.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/users/1_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/users/1_result.csv`
   - Findings:
      - Average reputation increases exponentially with tenure: 2.25 (4-year accounts) to 9,328 (18-year accounts), a 4,100x increase
      - Median reputation remains at 1 for accounts 4-13 years old, indicating most users never gain meaningful reputation
      - Extreme long-tail distribution: max reputation (1.36M) is 893x higher than even the P99 (119,178) for 18-year accounts
      - Voting activity correlates with reputation: avg up_votes given increases from 0.08 to 437 across tenure cohorts

2. **Query 2: Reputation by Voting Activity Levels**
   - Description: Segments users by their voting activity (up_votes given) to understand if active community participation correlates with personal reputation growth.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/users/2_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/users/2_result.csv`
   - Findings:
      - 90.1% of users (16.86M) have never given an upvote; they average only 6.7 reputation
      - Heavy voters (1000+ votes) have median reputation of 4,765 vs 1 for non-voters (4,765x difference)
      - Top 0.18% of users (heavy voters) contribute 31% of total platform reputation
      - Profile views scale dramatically with voting: 1.75 views (non-voters) vs 2,092 (heavy voters)

3. **Query 3: User Reputation Tiers and Activity Patterns**
   - Description: Segments users by reputation level to understand the distribution of reputation and characteristics of each tier.
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/users/3_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/users/3_result.csv`
   - Findings:
      - 76.54% of users have reputation = 1 ("newcomers"), contributing only 0.78% of total reputation
      - Top 0.02% ("legends" with 50K+ reputation) are 3,215 users holding 20.6% of total reputation
      - Top 0.74% of users (expert tier and above) hold 69.7% of all reputation
      - Legends average 3,360 upvotes given vs 0.05 for newcomers (67,200x difference in engagement)

### Total Data Processed
2,210 MB (2.21 GB)
