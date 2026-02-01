## Table Analysis Complete: votes

### Summary

The `votes` table contains 236 million records of all voting activity on Stack Overflow from 2008-2022. Analysis of the most recent 90 days of available data (June 27 - September 24, 2022) reveals key factors driving user reputation growth:

**Key Findings:**

1. **Upvotes are the Primary Reputation Driver**: Upvotes (vote_type_id=2) account for ~70% of all reputation-affecting votes. With 230K-240K upvotes per week, they generate the vast majority of reputation points on the platform.

2. **Strong Weekday/Weekend Pattern**: Voting activity drops 50% on weekends. Upvote/downvote ratios are also less favorable on weekends (4.86:1 on Saturday vs 6.9:1 on Tuesday). Content posted mid-week (Tuesday-Thursday) receives optimal exposure and more favorable voting.

3. **Stable 6.5:1 Upvote/Downvote Ratio**: For every downvote (-2 rep), there are 6-7 upvotes (+10 or +5 rep). The net effect heavily favors reputation growth, meaning consistent participation leads to reputation increase.

4. **Weekly Reputation Economy**: Approximately 2 million reputation points are distributed across all users each week. This represents the total "reputation pie" available through community voting.

5. **Accepted Answers Provide Bonus**: ~11,000 accepted answers per week each grant +15 reputation to the answerer, providing a significant bonus on top of upvotes.

**Data Freshness Note**: The votes table was last modified on November 24, 2024, with data ending on September 25, 2022. Analysis used the most recent 90 days of available data rather than current data.

### Table Information
- **Size**: 7.05 GB (uncompressed), 1.77 GB (physical)
- **Rows**: 236,452,885
- **Date range analyzed**: Last 90 days of available data (2022-06-27 to 2022-09-24)
- **Partitioning**: None (full table scans required)

### Queries Generated and Executed

1. **Query 1: Vote Type Distribution Over Time**
   - Description: Analyze which vote types are most common and how they trend over time to identify primary mechanisms for reputation growth
   - File: `/Users/ruben.flam-shepherd/projects/agentic-data-analysis-with-claude-code/research/2026-01-31-190441-reputation-growth-factors/votes/1_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/agentic-data-analysis-with-claude-code/research/2026-01-31-190441-reputation-growth-factors/votes/1_result.csv`
   - Findings:
      - Upvotes (type 2) dominate at ~38,000/day on weekdays, accounting for ~70% of all votes
      - Weekend voting drops by ~50% across all vote types
      - Upvote-to-downvote ratio is 6.7:1, heavily favoring reputation growth

2. **Query 2: Day-of-Week Patterns for Reputation-Affecting Votes**
   - Description: Analyze which days of the week generate the most reputation-affecting votes to understand optimal times for content contribution
   - File: `/Users/ruben.flam-shepherd/projects/agentic-data-analysis-with-claude-code/research/2026-01-31-190441-reputation-growth-factors/votes/2_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/agentic-data-analysis-with-claude-code/research/2026-01-31-190441-reputation-growth-factors/votes/2_result.csv`
   - Findings:
      - Wednesday is the peak day with 536,200 upvotes and 4.5M estimated reputation delta
      - Tuesday has the most favorable upvote/downvote ratio (6.9:1)
      - Saturday has the least favorable ratio (4.86:1) - 30% worse than Tuesday

3. **Query 3: Weekly Vote Volume Trends**
   - Description: Analyze weekly trends in reputation-affecting votes to identify any growth/decline patterns in the platform's reputation economy
   - File: `/Users/ruben.flam-shepherd/projects/agentic-data-analysis-with-claude-code/research/2026-01-31-190441-reputation-growth-factors/votes/3_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/agentic-data-analysis-with-claude-code/research/2026-01-31-190441-reputation-growth-factors/votes/3_result.csv`
   - Findings:
      - Weekly upvotes stable at 230K-240K per week
      - ~2 million reputation points distributed across all users each week
      - Upvote/downvote ratio stable within 6.05-6.49 range across all weeks

### Total Data Processed
10,550 MB (10.55 GB)
