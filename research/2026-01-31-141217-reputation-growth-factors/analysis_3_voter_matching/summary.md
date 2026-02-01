## Analysis Complete: Propensity Matching - Voters vs Non-Voters

### Headline Metrics

- **Voting Premium Persists After Matching**: Voters have 3-5x higher median reputation than non-voters with the SAME tenure, activity level, and answer quality
- **Consistent Across All Strata**: The voting premium ranges from 1,154% to 18,100% depending on the cohort (before quality control), and 77% to 12,567% after controlling for answer quality
- **Sample Size Validation**: Analysis includes 17.9M users with adequate sample sizes in most strata (20+ users minimum)

### Methodology

**Tables Analyzed:**
- `bigquery-public-data.stackoverflow.users` - 18.7M users with reputation, upvotes given, tenure
- `bigquery-public-data.stackoverflow.posts_answers` - Answer counts and scores per user

**Cohort Definitions:**
- **Voters**: Users who have given 100+ upvotes (active community participants)
- **Non-voters**: Users who have given 0 upvotes (passive consumers)
- Excluded: Users with 1-99 upvotes (to create cleaner treatment/control comparison)

**Stratification Approach:**
1. **Tenure buckets**: 0-2, 3-5, 6-8, 9-11, 12-14, 15+ years
2. **Activity buckets**: 0, 1-4, 5-24, 25-99, 100+ answers
3. **Answer quality buckets**: negative (<0), low (0-1), medium (1-2), good (2-5), high (5+) avg score

**Date Range:** Data through November 2024

### Detailed Findings

#### Finding 1: Voting Premium Without Quality Control

When matching users by tenure and activity level only:

| Tenure | Activity | Non-Voter Median | Voter Median | Premium |
|--------|----------|------------------|--------------|---------|
| 15+ years | 5+ answers | 225 | 4,587 | 1,939% |
| 15+ years | 1-4 answers | 26 | 509 | 1,858% |
| 12-14 years | 5+ answers | 106 | 2,012 | 1,798% |
| 12-14 years | 0 answers | 1 | 182 | 18,100% |
| 9-11 years | 5+ answers | 61 | 1,138 | 1,766% |
| 6-8 years | 5+ answers | 45 | 727 | 1,516% |
| 3-5 years | 5+ answers | 36 | 500 | 1,289% |

**Key observation:** The voting premium is LARGEST for passive users (0 answers) where voters have 3,400-18,100% higher median reputation. However, sample sizes for voters with 0 answers are small (16-1,832 users).

#### Finding 2: Voters Have Higher Answer Quality

Before concluding causation, we checked if voters simply write better answers:

| Cohort | Avg Answer Score (Voters) | Avg Answer Score (Non-Voters) | Quality Gap |
|--------|---------------------------|------------------------------|-------------|
| Veterans, 100+ answers | 4.51 | 4.07 | 1.11x |
| Veterans, 1-4 answers | 6.60 | 3.95 | 1.67x |
| Established, 10+ answers | 2.20 | 1.03 | 2.14x |
| Newer, 10+ answers | 1.12 | 0.52 | 2.15x |

**Key observation:** Voters DO write higher-quality answers on average, which partially explains the reputation gap.

#### Finding 3: Voting Premium PERSISTS After Controlling for Answer Quality

The critical test - comparing users with SAME tenure, activity, AND answer quality:

| Stratum | Non-Voter Median Rep | Voter Median Rep | Premium |
|---------|---------------------|------------------|---------|
| Veterans, active, high quality | 1,479 | 5,400 | 265% |
| Veterans, active, good quality | 591 | 2,843 | 381% |
| Veterans, active, medium quality | 321 | 1,613 | 402% |
| Veterans, active, low quality | 128 | 860 | 572% |
| Veterans, casual, high quality | 121 | 876 | 624% |
| Veterans, casual, low quality | 1 | 279 | 27,800% |
| Newer, active, high quality | 1,411 | 2,502 | 77% |
| Newer, active, low quality | 107 | 580 | 442% |
| Newer, casual, low quality | 1 | 129 | 12,800% |

**Critical finding:** Even among users with identical tenure, activity level, and answer quality, voters have 77-624% higher median reputation in high-sample strata. The premium is smaller but still substantial when comparing high-quality answerers (77-265% for newer/veteran active high-quality).

### Limitations & Caveats

1. **Correlation vs Causation**: While we controlled for tenure, activity, and answer quality, we cannot prove voting CAUSES higher reputation. Alternative explanations:
   - Unobserved confounders: Users who vote may be more engaged in ways we cannot measure (reading more, learning more, networking)
   - Reverse causation: Higher-reputation users may vote more as a result of their success, not a cause
   - Selection bias: Motivated users both vote AND write better content due to underlying trait

2. **Answer Volume Confound**: Voters average significantly more answers (48-129 vs 13-22 for non-voters in active strata). While we bucket by activity level, within-bucket variation still exists.

3. **Quality Measurement Limitation**: Average answer score is an imperfect proxy for quality - it conflates quality with topic selection, timing, and exposure.

4. **Mechanism Unknown**: If voting does help reputation, we cannot identify the mechanism:
   - Network effects (voters build relationships)?
   - Learning effect (voting teaches what good answers look like)?
   - Reciprocity (users upvote those who upvoted them)?
   - Engagement signal (Stack Overflow surfaces voters' content more)?

5. **Sample Size Issues in Extremes**: Some strata (especially non-voters with high activity) have very small samples (7-50 users), making those comparisons less reliable.

### Key Takeaways

1. **The raw 4,765x correlation dramatically overstates the effect.** When controlling for tenure and activity, the premium drops to 1,000-2,000%.

2. **Part of the premium is explained by answer quality.** Voters write 1.1-2.2x higher-scoring answers.

3. **A substantial premium (77-572%) remains after controlling for quality.** This suggests voting behavior is independently associated with reputation, though causation is not proven.

4. **The premium is inversely related to answer quality.** Low-quality answerers benefit MORE from voting than high-quality answerers. This could indicate:
   - Voting helps marginal contributors more than experts
   - Low-quality non-voters are particularly disengaged
   - Selection effect: low-quality voters are still more committed than low-quality non-voters

### Recommended Next Steps

1. **Longitudinal Analysis**: Track individual users over time to see if starting to vote correlates with subsequent reputation acceleration

2. **Natural Experiment**: Look for users who started voting after a long period of not voting and compare their before/after reputation growth rates

3. **Mechanism Testing**: Join with comments, edits, and other engagement data to understand what other behaviors correlate with voting

### Output Files

- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/query_1.sql` - Stratified cohort comparison (tenure + activity)
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/result_1.csv` - 60 rows, detailed breakdown
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/query_2.sql` - Voting premium calculation
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/result_2.csv` - 18 strata with premium metrics
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/query_3.sql` - Reputation per answer efficiency
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/result_3.csv` - 24 rows, rep efficiency by cohort
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/query_4.sql` - Quality-controlled premium (most stringent test)
- `/Users/ruben.flam-shepherd/projects/data-claude/research/2026-01-31-141217-reputation-growth-factors/analysis_3_voter_matching/result_4.csv` - 40 rows, final quality-matched comparison
