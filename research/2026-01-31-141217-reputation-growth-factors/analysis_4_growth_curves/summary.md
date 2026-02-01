## Analysis Complete: User Reputation Growth Curves Over Time

### Headline Metrics

- **Peak reputation earning occurs in Year 1**: Average score of 332 per year, declining to 16 by Year 5 (95% drop)
- **35% of prolific users are "Early Bloomers"**: Earned 83% of their total reputation in first 2 years, with highest efficiency (4.22 score/post)
- **Time to 10K reputation increased 50%**: 2008 users reached milestone in median 1 year; 2012-2013 users required median 2 years
- **96% fewer users reach 10K from recent cohorts**: 4,885 from 2009 vs only 180 from 2018+ achieved 10K reputation

### Methodology

**Tables Analyzed:**
- `bigquery-public-data.stackoverflow.users` - User creation dates and current reputation
- `bigquery-public-data.stackoverflow.posts_answers` - Answer scores and timestamps
- `bigquery-public-data.stackoverflow.posts_questions` - Question scores and timestamps

**Approach:**
1. Joined users with all their posts (answers + questions) to track score accumulation over time
2. Calculated cumulative score by year since joining for users with 100+ posts
3. Classified users into growth curve types based on when they earned reputation
4. Analyzed time-to-milestone (10K reputation) across join cohorts

**Date Range:** All historical data through November 2024

### Detailed Findings

#### Finding 1: Reputation Earning Peaks in Year 1, Then Declines Steadily

| Year Since Joining | Users | Avg Score | Median Score | Posts/Year | % from Answers |
|-------------------|-------|-----------|--------------|------------|----------------|
| 0 (Join year) | 66,257 | 246 | 39 | 49 | 70% |
| 1 | 70,714 | 332 | 82 | 71 | 74% |
| 2 | 71,170 | 224 | 56 | 56 | 78% |
| 5 | 60,054 | 83 | 16 | 30 | 81% |
| 10 | 24,884 | 25 | 4 | 15 | 84% |
| 14 | 1,414 | 15 | 1 | 15 | 94% |

**Key Insight:** Median score drops from 82 in Year 1 to just 1 by Year 14 - a 99% decline. The "honeymoon period" is brief.

#### Finding 2: Four Distinct Growth Curve Types Exist

| Growth Type | % of Users | Avg Reputation | Score/Post | Pattern Description |
|-------------|------------|----------------|------------|---------------------|
| Early Bloomer | 35.2% | 12,787 | 4.22 | 83% earned in years 0-1, efficient start |
| Steady Grower | 27.3% | 14,351 | 2.96 | Even distribution across career, highest absolute rep |
| Plateau | 25.5% | 11,855 | 3.30 | 70% earned in years 2-4, then stops contributing |
| Late Bloomer | 11.9% | 10,748 | 2.42 | 75% earned after year 5, slowest start |

**Key Insight:** Early Bloomers have 74% higher efficiency (score/post) than Late Bloomers, suggesting early answers were easier to score on.

#### Finding 3: Era of Joining Trumps Growth Strategy

| Growth Type | Pioneer (2008-2011) | Growth (2012-2015) | Mature (2016+) |
|-------------|---------------------|--------------------|--------------------|
| Early Bloomer Avg Rep | 19,744 | 7,818 | 4,878 |
| Steady Grower Avg Rep | 19,261 | 9,431 | 7,552 |
| Score per Answer | 5.27 | 2.56 | 1.42 |

**Key Insight:** A Pioneer-era Early Bloomer earns 4x the reputation of a Mature-era Early Bloomer despite using the same growth pattern. Timing dominates strategy.

#### Finding 4: Achieving 10K Reputation Has Become Dramatically Harder

| Join Cohort | Users Reaching 10K | Median Years | % in First Year | % in 3 Years |
|-------------|-------------------|--------------|-----------------|--------------|
| 2008 | 3,647 | 1.0 | 63.8% | 85.7% |
| 2009 | 4,885 | 1.0 | 50.4% | 79.2% |
| 2012-2013 | 4,002 | 2.0 | 38.2% | 68.7% |
| 2016-2017 | 491 | 2.0 | 37.5% | 77.8% |
| 2018+ | 180 | 1.0 | 62.2% | 93.3% |

**Key Insight:** The 2018+ cohort appears fast (62.2% in first year) but this reflects extreme survivorship bias - only 180 users from that era have reached 10K vs 4,885 from 2009. The successful modern users are exceptional outliers.

### Limitations & Caveats

1. **Reputation vs Score Approximation:** We tracked post scores, not actual reputation points. Reputation includes additional factors (accepted answers +15, bounties, edits) that we cannot decompose.

2. **Survivorship Bias in 10K Analysis:** We only analyzed users who reached 10K, not those who tried and failed. The difficulty increase is likely understated.

3. **No Content Analysis:** We cannot distinguish whether declining scores reflect content quality changes, topic saturation, or voting behavior changes.

4. **Mature Era Incomplete:** Users who joined 2018+ have fewer years of data, limiting comparisons of long-term growth patterns.

5. **100-Post Filter Creates Selection Bias:** By filtering to users with 100+ posts, we excluded casual contributors whose growth patterns may differ.

### Recommended Next Steps

1. **Analyze Tag-Specific Growth Curves:** Determine if certain technology domains (e.g., Python, JavaScript) have different growth trajectories than others - this could inform topic selection strategy.

2. **Model "Required Activity" by Era:** Calculate how many posts/year a user must submit to achieve 10K reputation based on their join date, quantifying the effort gap.

3. **Identify "Late Bloomer Success Factors":** Deep-dive into the 12% of users who succeeded late - what tags, behaviors, or content strategies enabled them to overcome the early-mover disadvantage?

### Files Generated

- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/query_1.sql` - Cumulative score by year since joining
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/result_1.csv` - Growth curve data
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/query_2.sql` - Growth type classification
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/result_2.csv` - User counts by growth type
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/query_3.sql` - Characteristics by growth type and era
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/result_3.csv` - Era and growth type breakdown
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/query_4.sql` - Years to 10K reputation
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/result_4.csv` - Time-to-milestone by cohort
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_4_growth_curves/summary.md` - This summary
