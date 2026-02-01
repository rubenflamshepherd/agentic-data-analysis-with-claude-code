// Report data types

export interface ReportMetadata {
  title: string;
  subtitle: string;
  generatedAt: string;
  dataset: string;
  dateRange: string;
}

export interface KPIMetric {
  label: string;
  value: string | number;
  change?: number;
  changeLabel?: string;
  trend?: 'up' | 'down' | 'neutral';
}

// Flexible data point type for charts
export type ChartDataPoint = Record<string, string | number>;

// QA status for chart validation
export type ChartQAStatus = 'pending' | 'passed' | 'failed' | 'needs_repair';

export interface ChartConfig {
  id: string;
  title: string;
  description?: string; // What this chart visualizes and why - used by chart-qa for validation
  type: 'area' | 'bar' | 'line' | 'donut';
  xKey: string;
  yKey: string | string[];
  categoryKey?: string; // Column to use for grouping/stacking (e.g., 'device_type', 'general_type')
  colors?: string[];
  filter?: { field: string; value: string; exclude?: boolean } | { field: string; value: string; exclude?: boolean }[]; // Optional filter(s) to subset data before rendering. Set exclude: true to filter OUT rows matching the value.
  xKeyTransform?: 'prefix'; // Transform xKey values: 'prefix' extracts text before first ':'
  rotateLabelX?: { angle: number; xAxisHeight?: number }; // Rotate x-axis labels to fit more/longer labels
  aggregate?: boolean; // When true, sum yKey values for each unique xKey (useful when raw data has multiple rows per xKey)
  aggregateFunction?: 'sum' | 'avg'; // Aggregation function to use (default: 'sum'). Use 'avg' for percentage/rate fields.
  sortOrder?: string[]; // Explicit sort order for xKey values (useful for ordinal categories like "1 share", "2-5 shares", etc.)
  limit?: number; // Limit data to first N rows (useful for "Top 10" style charts where data has more rows)
  offset?: number; // Skip first N rows (useful for "Ranks 21-50" style charts that show a window of data)
  secondaryYAxis?: { // Enable dual y-axis for comparing metrics with different scales (e.g., volume vs percentage)
    yKey: string; // Which yKey to render on the right/secondary axis
    formatter?: 'percent' | 'number'; // How to format the secondary axis values
  };
  qaStatus?: ChartQAStatus; // QA validation status - set by chart-qa agent
  originalScreenshotPath?: string; // Path to pre-fix screenshot (relative to report-template)
  qaIssue?: string; // What was wrong with the chart (set for needs_repair and failed)
  qaFix?: string; // What was done to fix it (only set for needs_repair)
}

// Query section within a table tab
export interface QuerySection {
  id: string;
  title: string;
  sql: string;
  summary: string;
  observations: string[];
  charts: ChartConfig[];
  csvData: string;  // Raw CSV content (complete file)
  csvPath: string;  // Display path for header
}

// Table analysis tab
export interface TableAnalysis {
  tableName: string;
  description: string;
  status: 'complete' | 'stale' | 'failed';
  rowCount?: number;
  dateRange?: string;
  queries: QuerySection[];
}

export interface ResearchQuestion {
  question: string;
  findings: string[];
  gaps: string[];
  verdict?: 'supported' | 'inconclusive' | 'not_supported';
}

export interface Recommendation {
  title: string;
  description: string;
  impact?: string;
  priority: 'high' | 'medium' | 'low';
}

export interface ReportData {
  metadata: ReportMetadata;
  kpis: KPIMetric[];
  executiveSummary: string[];
  researchQuestions: ResearchQuestion[];
  tables: TableAnalysis[];
  advancedAnalyses?: TableAnalysis[];  // Optional: populated by /advanced-analysis
  recommendations: Recommendation[];
}
