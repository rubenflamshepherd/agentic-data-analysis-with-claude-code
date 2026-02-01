# Guard-Railed Data Analysis

You are responsible for coordinating the initial discovery and research into a dataset for a given user's research question.

## Initial Setup:

When this command is invoked, respond with:

```
I'm ready to help you analyze data from your BigQuery dataset. Please provide your data analysis question, and I'll:
1. Find relevant tables using the table-finder subagent
2. Analyze each table using the table-reader subagent (schema inspection, query generation, validation, execution, statistical analysis)
3. Generate an Initial Analysis summary with key findings and recommended next steps
4. Generate an interactive executive report with visualizations (React + Tremor)

What would you like to analyze?
```

## Dataset Access Rules

**CRITICAL CONSTRAINTS:**
- **Only access tables in**: `$BQ_PROJECT.$BQ_DATASET` (set via environment variables)
- **Read-only enforcement**: ONLY SELECT queries allowed - no INSERT, UPDATE, DELETE, CREATE, DROP, TRUNCATE, or any DDL/DML

## Analysis Workflow

### Step 0: Verify Environment Variables

**Before starting, verify the required environment variables are set:**

```bash
echo "BQ_PROJECT=$BQ_PROJECT"
echo "BQ_DATASET=$BQ_DATASET"
```

If either variable is empty, use the AskUserQuestion tool to ask for the missing values:

```
I need to configure your BigQuery connection. Please provide:
- BQ_PROJECT: Your GCP project ID (e.g., "bigquery-public-data")
- BQ_DATASET: The dataset name to analyze (e.g., "stackoverflow")
```

After receiving the values, run the export commands yourself:
```bash
export BQ_PROJECT=<user-provided-project>
export BQ_DATASET=<user-provided-dataset>
```

**Once verified**, proceed to create the working directory.

### Step 1: Create Working Directory and Save Question

**Create a unique working directory for this analysis session:**

1. Extract 2-4 keywords from the user's question (nouns/topics like "sharing", "retention", "revenue", "users")
2. Sanitize keywords: lowercase, alphanumeric only, joined with hyphens
3. Create the folder with format: `YYYY-MM-DD-HHMMSS-keyword1-keyword2-keyword3`

```bash
# Example: If user asks about "sharing behavior and retention rates"
# Keywords might be: sharing, retention, rates
KEYWORDS="sharing-retention-rates"  # You determine these from the question
WORKING_DIR="./research/$(date +%Y-%m-%d-%H%M%S)-${KEYWORDS}"
mkdir -p "$WORKING_DIR"
echo "$WORKING_DIR"
```

**Store this path** - you will use it throughout this analysis and pass it to all subagents.

**Save the user's question:**
```bash
echo "USER_QUESTION_HERE" > "$WORKING_DIR/question.txt"
```

### Step 2: Find Relevant Tables

**Delegate to the `table-finder` subagent:**

Launch the `table-finder` subagent to identify relevant tables for the analysis:
```
Use the Task tool with:
- subagent_type: "table-finder"
- prompt: "Find relevant tables for this analysis question: <question>{user's complete question}</question>

Working directory: {WORKING_DIR}"
```

**After the subagent completes:**
- Review the output and note the tables recommended for analysis

### Step 3: Read each table

**Delegate to the `table-reader` subagent for each promising table:**

Launch a `table-reader` subagent for each of the 3-5 most promising tables identified by `table-finder`.

**Launch the subagent:**
```
Use the Task tool with:
- subagent_type: "table-reader"
- prompt: "Read table '{table_name}'. Make basic observations with the following question in mind: <question>{user's complete question}</question>. Use last 90 days of data.

Working directory: {WORKING_DIR}"
```

The table-reader subagent will read the table passed to it and report back to you.

**Important Notes:**
- Launch multiple table-reader subagents in parallel if analyzing multiple tables
- Each subagent runs independently and saves its results with unique prefixes
- Always pass the working directory to each subagent

### Step 4: Generate Initial Analysis Summary

After ALL table-reader subagents complete, synthesize the findings into a comprehensive Initial Analysis report. Each table-reader generates both manual observations and programmatic statistical analysis (`*_analysis.json` files).

**Save the report to:** `{WORKING_DIR}/initial-analysis.md`

**Report Structure:**

```markdown
## Initial Analysis Complete

### Tables Analyzed

| Table | Status | Key Value |
|-------|--------|-----------|
| `{table_name}` | ✅ Complete / ⚠️ Stale / ❌ Failed | Brief description of what this table provides |

---

### Key Findings by Research Question

For each sub-question in the user's original research question, summarize:

#### {Sub-question 1}

**Evidence found:**
- Key metrics and findings from relevant tables
- Correlations or patterns discovered
- Data quality notes or gaps

**Critical gaps:** What data is missing to fully answer this question?

#### {Sub-question 2}
... (repeat for each sub-question)

---

### Files Generated

List all output files saved to `{WORKING_DIR}/`:
- `question.txt` - Original analysis question
- `table-finder.md` - Table discovery results
- `{table_name}/` - Queries, results, summaries, and statistical analysis for each table
  - `{N}_query.sql` - Generated SQL queries
  - `{N}_result.csv` - Query results
  - `{N}_analysis.json` - Programmatic statistical analysis
  - `summary.md` - Manual observations

---

### Recommended Next Steps

Based on the initial analysis, suggest 3-5 specific follow-up analyses that would deepen understanding. Format as:

1. **{Analysis title}** - Brief description of what this would investigate and why it matters

Example next steps might include:
- Cross-table joins to answer questions individual tables can't
- Cohort comparisons (e.g., users with behavior X vs without)
- Time-series or trend analysis
- Segmentation analysis
- Opportunity sizing or impact modeling

---

Would you like me to proceed with advanced analysis? Run `/advanced-analysis` to automatically execute the recommended next steps above.
```

**Guidelines for the summary:**
- Be specific with numbers and metrics from the initial-table-reader results
- Clearly distinguish between correlation and causation
- Highlight data quality issues or stale tables
- Make next steps actionable and specific to the user's question
- Keep the summary concise but comprehensive

**IMPORTANT:** Use the Write tool to save the complete report to `{WORKING_DIR}/initial-analysis.md`, then display the report to the user. Also inform the user of the working directory path so they can find all generated files.

### Step 5: Generate Interactive Executive Report

After generating the Initial Analysis summary, create a polished React-based report with visualizations using the modular agent architecture.

#### 4a: Clean tables directory

```bash
rm -rf ./report-template/src/data/tables
mkdir -p ./report-template/src/data/tables
```

#### 4b: Generate table files in parallel

For each table that was analyzed, spawn a `table-reporter` agent. **Launch ALL table agents in a single message with multiple Task tool calls** for parallel execution.

```
Use the Task tool with:
- subagent_type: "table-reporter"
- prompt: "Generate the table report file for '{table_name}'.

Working directory: {WORKING_DIR}
Research question: {user's complete question}

Read the table's summary.md and query files, then generate:
./report-template/src/data/tables/{table-kebab}.ts"
```

**Important:** Launch one `table-reporter` agent per table, all in parallel within a single message.

#### 4c: Assemble and serve the report

After ALL table agents complete, spawn the `report-orchestrator` agent to assemble the final report.

```
Use the Task tool with:
- subagent_type: "report-orchestrator"
- prompt: "Assemble the final executive report.

Working directory: {WORKING_DIR}
Research question: {user's complete question}
Tables analyzed (in order): {table_name_1}, {table_name_2}, {table_name_3}, ...

Generate index.ts, report-data.ts, and start the dev server."
```

The orchestrator will:
1. Create `tables/index.ts` re-exporting all table modules
2. Create `report-data.ts` with metadata, KPIs, executive summary, and recommendations
3. Start the dev server at http://localhost:8000

**After the orchestrator completes:**
- Confirm the report is accessible at the provided URL
- Proceed to chart QA

#### 4d: Run visual QA on all charts in parallel

After the dev server is running, spawn `chart-qa` agents in parallel for each table to validate and fix chart rendering issues.

**Launch ALL chart-qa agents in a single message with multiple Task tool calls:**

```
Use the Task tool with:
- subagent_type: "chart-qa"
- prompt: "QA charts for table '{table_name}'.

table_name: {table_name}
table_kebab: {table-kebab}
working_directory: {WORKING_DIR}
server_port: 8000

Read the TypeScript config, capture screenshots, analyze for issues, and fix any problems."
```

**Important:** Launch one `chart-qa` agent per table, all in parallel within a single message. Each agent will:
1. Read the table's TypeScript chart configurations
2. Capture screenshots of each chart
3. Analyze for visual issues (empty data, label problems, scale mismatch, etc.)
4. Fix issues by editing the TypeScript config
5. Set `qaStatus` on each chart (`passed`, `needs_repair`, or `failed`)

**After all chart-qa agents complete:**
- Summarize overall QA results (charts passed, fixed, failed)
- Inform the user how to stop the server when done (`Ctrl+C` or `pkill -f vite`)
