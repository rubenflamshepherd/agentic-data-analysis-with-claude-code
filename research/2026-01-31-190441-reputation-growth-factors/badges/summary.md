## Table Analysis Complete: badges

### Summary

The `badges` table contains 46 million records of badge awards on Stack Overflow from 2008 to September 2022. Analysis of the last 90 days of available data reveals that **question visibility** is the dominant driver of badge acquisition (31% of badges from Popular/Notable/Famous Question badges), while **answer-related badges** account for only 4% of awards. The badge system follows a consistent pyramid structure with Bronze badges comprising 74% of awards, and new user onboarding badges (Autobiographer, Informed, Editor) representing 26% of total activity. Weekly trends show steady growth with a 15.6% increase in badge volume over the period analyzed.

**Data Freshness Note**: This table was last modified on November 24, 2024 and contains data through September 25, 2022. The analysis covers June 27 - September 25, 2022.

### Table Information
- **Size**: 2.1 GB
- **Total Rows**: 46,135,386
- **Date range analyzed**: Last 90 days of available data (June 27 - September 25, 2022)
- **Partitioning**: None (full table scan required)

### Queries Generated and Executed

1. **Query 1: Badge Distribution by Class and Tag-Based Status**
   - Description: Examines the types of badges earned in the last 90 days of available data to understand which badge categories (Gold/Silver/Bronze) and whether tag-based vs general badges are more commonly earned.
   - File: `./research/2026-01-31-190441-reputation-growth-factors/badges/1_query.sql`
   - Results: `./research/2026-01-31-190441-reputation-growth-factors/badges/1_result.csv`
   - Findings:
      - Bronze non-tag-based badges account for 73.53% of all badges earned (742,134 badges)
      - Tag-based badges are rare at only 0.33% of total, indicating specialized expertise recognition is uncommon
      - Steep pyramid: 560,285 users earned Bronze vs 29,471 earning Gold (19:1 ratio)

2. **Query 2: Top 30 Most Frequently Earned Badges**
   - Description: Identifies which specific badges are most commonly awarded, revealing primary activities and achievements that drive user engagement.
   - File: `./research/2026-01-31-190441-reputation-growth-factors/badges/2_query.sql`
   - Results: `./research/2026-01-31-190441-reputation-growth-factors/badges/2_result.csv`
   - Findings:
      - Question visibility badges (Popular/Notable/Famous Question) account for 31.06% of all badges
      - Onboarding badges (Autobiographer, Informed, Editor) represent 26.33% of awards
      - Answer badges (Nice/Good/Great Answer) total only 4.02% - a 7.7x gap vs question badges

3. **Query 3: Weekly Badge Award Trends**
   - Description: Analyzes weekly patterns in badge awarding to understand temporal trends in user activity, segmented by badge class.
   - File: `./research/2026-01-31-190441-reputation-growth-factors/badges/3_query.sql`
   - Results: `./research/2026-01-31-190441-reputation-growth-factors/badges/3_result.csv`
   - Findings:
      - Bronze badges increased 15.6% over the 13-week period (53,000 to 61,262 weekly)
      - Consistent Gold:Silver:Bronze ratio of approximately 1:7:23 across all weeks
      - September 11 week showed 13% spike in Silver badges (20,291 vs typical 17,000-18,000)

### Total Data Processed
4.79 GB (1.61 GB + 1.61 GB + 1.57 GB)
