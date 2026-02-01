# Advanced Analysis

You are responsible for coordinating advanced, multi-table analysis tasks that build on initial discovery results from `/initial-analysis`.

## Dataset Access Rules

**CRITICAL CONSTRAINTS:**
- **Only access tables in**: `$BQ_PROJECT.$BQ_DATASET` (set via environment variables)
- **Read-only enforcement**: ONLY SELECT queries allowed - no INSERT, UPDATE, DELETE, CREATE, DROP, TRUNCATE, or any DDL/DML

## Analysis Workflow

### Step 0: Load Context from Initial Analysis

**Find the most recent analysis working directory:**

```bash
# Get the most recently created research folder
WORKING_DIR=$(ls -td ./research/*/ 2>/dev/null | head -1 | sed 's:/$::')
echo "Using working directory: $WORKING_DIR"
```

If no research folder exists, inform the user they need to run `/initial-analysis` first.

**Read the following files to understand the analysis context:**

1. **Original question:** `{WORKING_DIR}/question.txt`
2. **Initial analysis with recommended next steps:** `{WORKING_DIR}/initial-analysis.md`
3. **Table discovery results:** `{WORKING_DIR}/table-finder.md`

The `initial-analysis.md` file contains a "Recommended Next Steps" section with 3-5 specific follow-up analyses. These are the analyses you will execute.

**After reading the files, briefly acknowledge to the user:**
```
I've loaded the initial analysis context. Based on the recommended next steps, I'll now run {N} parallel advanced-analyzer agents:

1. {Analysis 1 title}
2. {Analysis 2 title}
...

Launching analyses now...
```

### Step 1: Define Analysis Tasks

Extract the recommended next steps from `initial-analysis.md` and convert each into a advanced-analyzer task.

For each recommended next step, determine:
- **Objective:** What question does this analysis answer?
- **Data sources:** Which tables from the initial analysis are needed?
- **Analysis pattern:** Which pattern below best fits?

**Common analysis patterns the advanced-analyzer agent supports:**

| Pattern | Use Case | Example |
|---------|----------|---------|
| **Cohort Comparison** | Compare metrics between two user groups | Users who did X vs didn't do X |
| **Propensity/Stratified Matching** | Control for selection bias | Match sharers to non-sharers by engagement level |
| **Time-to-Event Analysis** | Analyze timing effects | Does doing X early vs late matter? |
| **Opportunity Sizing** | Model business impact | What if we increased X by 10%? |
| **Segmentation Analysis** | Break down by dimensions | Which segments drive the most X? |
| **Cross-Table Joins** | Combine data from multiple tables | Link behavior to outcomes |
| **Funnel Analysis** | Analyze conversion through steps | Where do users drop off? |

### Step 2: Launch Parallel Deep-Analyzer Subagents

For each analysis task, launch a `advanced-analyzer` subagent. Each agent will conduct 3-4 research loops with schema lookups, query validation, and iterative refinement.

**Launch template:**
```
Use the Task tool with:
- subagent_type: "advanced-analyzer"
- description: "{Brief 3-5 word description}"
- prompt: (see template below)
```

**Standardized prompt template (matches advanced-analyzer Input Parameters):**
```
## Task: {Analysis Title}

**objective:** {Clear description of what to analyze and why}

**data_sources:**
- `$BQ_PROJECT.$BQ_DATASET.{table_1}` - {why this table is needed}
- `$BQ_PROJECT.$BQ_DATASET.{table_2}` - {why this table is needed}
- Previous analysis results: `{WORKING_DIR}/{folder}/` (if applicable)

**analysis_steps:**
1. {High-level step 1 - the agent will determine specific queries}
2. {High-level step 2}
3. {High-level step 3}

**working_directory:** {WORKING_DIR}
**output_directory:** `{WORKING_DIR}/analysis_{N}_{short_name}/`

Report back with: (1) headline metrics, (2) most important finding, (3) key caveats
```

**Important Notes:**
- Launch ALL advanced-analyzer subagents in parallel (single message with multiple Task tool calls)
- Each subagent runs 3-4 research loops independently
- Use numbered prefixes for output directories: `analysis_1_`, `analysis_2_`, etc.
- The advanced-analyzer will save: `summary.md`, `query_*.sql`, and `result_*.csv` files

### Step 3: Generate Consolidated Results Summary

After ALL subagents complete, synthesize findings into a comprehensive report.

**Save the report to:** `{WORKING_DIR}/advanced-analysis.md`

**Report Structure:**

```markdown
## Advanced Analysis - Complete Results

### Analyses Completed

| # | Analysis | Location | Status |
|---|----------|----------|--------|
| 1 | {Analysis 1 title} | `{WORKING_DIR}/analysis_1_{name}/` | ✅ |
| 2 | {Analysis 2 title} | `{WORKING_DIR}/analysis_2_{name}/` | ✅ |
...

---

### Analysis 1: {Title}
**Location:** `{output directory}`

{Headline metrics in a table or bullet points}

{Key insight or surprising finding}

---

### Analysis 2: {Title}
... (repeat for each analysis)

---

## Executive Summary

### Key Findings

{3-5 numbered findings that directly answer the original research question}

### Recommended Actions

| Priority | Action | Expected Impact |
|----------|--------|-----------------|
| **P0** | {Highest priority action} | {Quantified impact if possible} |
| P1 | {Next priority} | {Impact} |
...

### All Output Files

```
{WORKING_DIR}/
├── question.txt
├── table-finder.md
├── initial-analysis.md
├── {table_name}/ (folders from initial analysis)
├── analysis_1_{name}/
│   ├── summary.md
│   ├── query_1.sql, query_2.sql, ...
│   └── result_1.csv, result_2.csv, ...
├── analysis_2_{name}/
└── advanced-analysis.md
```

---
```

**Guidelines for the consolidated summary:**
- Lead with the most important/surprising findings
- Quantify impact wherever possible
- Be explicit about what is correlation vs causation
- Make recommendations actionable and prioritized
- Reference specific output files for users who want details

**IMPORTANT:** Use the Write tool to save the complete report to `{WORKING_DIR}/advanced-analysis.md`, then display the report to the user. Remind them of the working directory path.

### Step 4: Generate Interactive Executive Report

After generating the Advanced Analysis summary, create a polished React-based report with visualizations using the modular agent architecture. The advanced analysis visualizations are saved to a separate `data/analysis/` folder and appear under a new "Advanced Analysis" tab in the UI.

#### 4a: Prepare analysis directory

```bash
rm -rf ./report-template/src/data/analysis
mkdir -p ./report-template/src/data/analysis
```

**Note:** This does NOT remove the `data/tables/` folder. Initial analysis visualizations are preserved.

#### 4b: Generate analysis files in parallel

For each analysis that was completed, spawn an `advanced-table-report` agent. **Launch ALL analysis agents in a single message with multiple Task tool calls** for parallel execution.

```
Use the Task tool with:
- subagent_type: "advanced-table-report"
- prompt: "Generate the analysis report file for '{analysis_dir}'.

Working directory: {WORKING_DIR}
Research question: {user's complete question}

Read the analysis's summary.md and query files, then generate:
./report-template/src/data/analysis/{analysis-dir-kebab}.ts"
```

**Important:** Launch one `advanced-table-report` agent per analysis directory, all in parallel within a single message.

#### 4c: Assemble and serve the report

After ALL advanced-table-report agents complete, spawn the `advanced-report-orchestrator` agent to assemble the final report.

```
Use the Task tool with:
- subagent_type: "advanced-report-orchestrator"
- prompt: "Assemble the final executive report for advanced analysis.

Working directory: {WORKING_DIR}
Research question: {user's complete question}
Analyses completed (in order): {analysis_1_name}, {analysis_2_name}, {analysis_3_name}, ...

Generate analysis/index.ts, update report-data.ts with advancedAnalyses, and start the dev server."
```

The orchestrator will:
1. Create `analysis/index.ts` re-exporting all analysis modules
2. Update `report-data.ts` to add the `advancedAnalyses` array (preserving existing initial analysis data)
3. Start the dev server at http://localhost:8000

**After the orchestrator completes:**
- Confirm the report is accessible at the provided URL
- The new "Advanced Analysis" tab will appear in the UI alongside "Initial Analysis"
- Inform the user how to stop the server when done (`Ctrl+C` or `pkill -f vite`)
