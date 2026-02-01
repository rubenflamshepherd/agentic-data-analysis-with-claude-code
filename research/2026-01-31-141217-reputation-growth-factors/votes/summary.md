## Table Analysis Complete: votes

### Summary

The Stack Overflow votes table reveals key factors that drive user reputation growth. Upvotes (vote_type_id=2) dominate at 72.8% of all voting activity, making them the primary driver of reputation. The voting system exhibits strong temporal patterns with weekday activity roughly double that of weekends, and a peak on Tuesday-Wednesday. The distribution of votes across posts shows that most reputation comes incrementally from posts receiving 1-5 upvotes (76.8% of all upvotes), rather than from viral high-vote posts.

**Data Freshness Note**: The data ends at 2022-09-25 (approximately 3.3 years old at time of analysis). Findings should be validated against more recent data if available.

### Table Information
- **Size**: 7.57 GB (236.4 million rows)
- **Date range analyzed**: Last 90 days of available data (2022-06-28 to 2022-09-25)
- **Schema**: id, creation_date, post_id, vote_type_id
- **Partitioning**: None (full table scan required)

### Queries Generated and Executed

1. **Query 1: Vote Type Distribution**
   - Description: Analyze vote type distribution and daily volumes to understand what types of votes exist in Stack Overflow, their relative frequency, and daily voting patterns
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/votes/1_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/votes/1_result.csv`
   - Findings:
      - Upvotes (vote_type_id=2) represent 72.83% of all voting activity (2,989,399 votes in 90 days)
      - Downvotes (vote_type_id=3) at 11.5% are ~6x less common than upvotes, creating net positive bias in reputation
      - Accepted answers (vote_type_id=1) at 3.44% are rare but carry high reputation value (+15 rep)
      - Clear weekend dip: weekday upvotes ~38,000/day vs weekend ~19,000/day (50% lower)

2. **Query 2: Vote Concentration by Post**
   - Description: Analyze Pareto distribution of votes across posts to understand whether reputation comes from few highly-voted posts or is distributed across many posts
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/votes/2_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/votes/2_result.csv`
   - Findings:
      - 58.24% of voted posts received exactly 1 upvote, accounting for 42.79% of all upvotes
      - Posts with 2-5 upvotes (17.92% of posts) capture 34.01% of upvotes
      - High-vote posts (100+) represent only 0.01% of posts but capture 0.83% of upvotes
      - Posts with 0 upvotes (21.23%) received 386,477 downvotes (0.83 avg per post)

3. **Query 3: Weekly Voting Trends and Day-of-Week Patterns**
   - Description: Analyze weekly volume trends and day-of-week patterns to understand temporal factors affecting reputation growth
   - File: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/votes/3_query.sql`
   - Results: `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/votes/3_result.csv`
   - Findings:
      - Tuesday-Wednesday show peak upvote volumes (~42,000/day) vs Friday (~35,500/day)
      - Upvote/downvote ratio higher on weekdays (6.4-7.2) vs weekends (4.3-5.4)
      - Week-over-week totals stable at 310,000-330,000 total votes, indicating mature platform
      - Weekend activity is approximately 50% of weekday activity

### Total Data Processed
12.33 GB (3.52 GB + 5.29 GB + 3.52 GB)
