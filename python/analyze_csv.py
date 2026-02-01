#!/usr/bin/env python3
"""
CSV Statistical Analysis Utility

Provides programmatic statistical analysis of CSV files for the initial-analysis workflow.
Used by the csv-analyzer agent to generate objective data insights.

Usage:
    python analyze_csv.py <csv_path> [output_path]

Output:
    JSON file with structured statistics and detected patterns
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path
import sys
import json


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class ColumnStats:
    """Statistical summary for a single column."""
    column_name: str
    dtype: str
    non_null_count: int
    null_count: int
    null_rate: float
    unique_count: int
    # Numeric-only fields (None for non-numeric)
    mean: Optional[float] = None
    median: Optional[float] = None
    std: Optional[float] = None
    min_val: Optional[float] = None
    max_val: Optional[float] = None
    p25: Optional[float] = None
    p75: Optional[float] = None
    p90: Optional[float] = None
    p95: Optional[float] = None
    p99: Optional[float] = None
    # Categorical-only fields
    top_values: Optional[List[Dict[str, Any]]] = None  # [{"value": x, "count": n}, ...]


@dataclass
class DatasetStats:
    """Overall dataset statistics."""
    row_count: int
    column_count: int
    column_stats: List[ColumnStats]
    date_columns: List[str]
    numeric_columns: List[str]
    categorical_columns: List[str]


@dataclass
class PatternInsight:
    """A detected pattern or anomaly."""
    pattern_type: str  # e.g., "outlier", "concentration", "trend", "correlation"
    description: str
    severity: str  # "info", "notable", "significant"
    details: Dict[str, Any]


@dataclass
class AnalysisResult:
    """Complete analysis result for a CSV file."""
    csv_path: str
    dataset_stats: DatasetStats
    patterns: List[PatternInsight]
    recommendations: List[str]


# ============================================================================
# STATISTICAL ANALYSIS FUNCTIONS
# ============================================================================

def analyze_column(series: pd.Series, column_name: str) -> ColumnStats:
    """Compute statistics for a single column."""
    stats = ColumnStats(
        column_name=column_name,
        dtype=str(series.dtype),
        non_null_count=int(series.count()),
        null_count=int(series.isna().sum()),
        null_rate=round(float(series.isna().sum()) / len(series), 4) if len(series) > 0 else 0.0,
        unique_count=int(series.nunique()),
    )

    # Numeric column analysis
    if pd.api.types.is_numeric_dtype(series):
        clean = series.dropna()
        if len(clean) > 0:
            stats.mean = round(float(clean.mean()), 4)
            stats.median = round(float(clean.median()), 4)
            stats.std = round(float(clean.std()), 4) if len(clean) > 1 else 0.0
            stats.min_val = float(clean.min())
            stats.max_val = float(clean.max())
            # Percentiles
            percentiles = clean.quantile([0.25, 0.75, 0.90, 0.95, 0.99]).to_dict()
            stats.p25 = round(float(percentiles.get(0.25, 0)), 4)
            stats.p75 = round(float(percentiles.get(0.75, 0)), 4)
            stats.p90 = round(float(percentiles.get(0.90, 0)), 4)
            stats.p95 = round(float(percentiles.get(0.95, 0)), 4)
            stats.p99 = round(float(percentiles.get(0.99, 0)), 4)
    else:
        # Categorical column analysis - top 10 values
        value_counts = series.value_counts().head(10)
        stats.top_values = [{"value": str(k), "count": int(v)} for k, v in value_counts.items()]

    return stats


def compute_dataset_stats(df: pd.DataFrame) -> DatasetStats:
    """Compute overall dataset statistics."""
    column_stats = [analyze_column(df[col], col) for col in df.columns]

    # Identify column types
    date_cols = [col for col in df.columns if 'date' in col.lower() or 'week' in col.lower() or 'month' in col.lower()]
    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    categorical_cols = [col for col in df.columns if col not in numeric_cols]

    return DatasetStats(
        row_count=len(df),
        column_count=len(df.columns),
        column_stats=column_stats,
        date_columns=date_cols,
        numeric_columns=numeric_cols,
        categorical_columns=categorical_cols,
    )


# ============================================================================
# PATTERN DETECTION FUNCTIONS
# ============================================================================

def detect_outliers(df: pd.DataFrame, numeric_cols: List[str]) -> List[PatternInsight]:
    """Detect outliers using IQR method for numeric columns."""
    patterns = []
    for col in numeric_cols:
        series = df[col].dropna()
        if len(series) < 4:
            continue

        q1, q3 = series.quantile([0.25, 0.75])
        iqr = q3 - q1
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr

        outliers = series[(series < lower_bound) | (series > upper_bound)]
        outlier_pct = len(outliers) / len(series) * 100

        if len(outliers) > 0 and outlier_pct > 1:  # More than 1% outliers
            severity = "significant" if outlier_pct > 5 else "notable"
            patterns.append(PatternInsight(
                pattern_type="outlier",
                description=f"Column '{col}' has {len(outliers)} outliers ({outlier_pct:.1f}% of values)",
                severity=severity,
                details={
                    "column": col,
                    "outlier_count": int(len(outliers)),
                    "outlier_pct": round(outlier_pct, 2),
                    "lower_bound": round(float(lower_bound), 2),
                    "upper_bound": round(float(upper_bound), 2),
                    "min_outlier": round(float(outliers.min()), 2),
                    "max_outlier": round(float(outliers.max()), 2),
                }
            ))
    return patterns


def detect_concentration(df: pd.DataFrame, numeric_cols: List[str], categorical_cols: List[str]) -> List[PatternInsight]:
    """Detect Pareto-like concentration patterns."""
    patterns = []

    # For categorical columns: check if top N values dominate
    for col in categorical_cols:
        if col in df.columns:
            value_counts = df[col].value_counts()
            if len(value_counts) >= 3:
                top_3_pct = value_counts.head(3).sum() / len(df) * 100
                if top_3_pct > 70:  # Top 3 values represent >70% of data
                    patterns.append(PatternInsight(
                        pattern_type="concentration",
                        description=f"Column '{col}' is highly concentrated: top 3 values represent {top_3_pct:.1f}% of records",
                        severity="notable",
                        details={
                            "column": col,
                            "top_3_values": [{"value": str(k), "count": int(v)} for k, v in value_counts.head(3).items()],
                            "top_3_pct": round(top_3_pct, 1),
                            "total_unique": int(len(value_counts)),
                        }
                    ))

    # For numeric columns: check Pareto distribution
    for num_col in numeric_cols:
        series = df[num_col].dropna()
        if len(series) >= 5:
            sorted_vals = series.sort_values(ascending=False)
            top_20_pct_idx = max(1, int(len(sorted_vals) * 0.2))
            top_20_pct_sum = sorted_vals.head(top_20_pct_idx).sum()
            total_sum = sorted_vals.sum()

            if total_sum > 0:
                pareto_ratio = top_20_pct_sum / total_sum * 100
                if pareto_ratio > 65:  # Top 20% accounts for >65% of total
                    patterns.append(PatternInsight(
                        pattern_type="pareto",
                        description=f"Column '{num_col}' shows Pareto pattern: top 20% of values account for {pareto_ratio:.1f}% of total",
                        severity="info",
                        details={
                            "column": num_col,
                            "top_20_pct_of_total": round(pareto_ratio, 1),
                        }
                    ))

    return patterns


def detect_time_trends(df: pd.DataFrame, date_cols: List[str], numeric_cols: List[str]) -> List[PatternInsight]:
    """Detect trends over time."""
    patterns = []

    for date_col in date_cols:
        if date_col not in df.columns:
            continue

        try:
            # Try to parse as date
            df_sorted = df.copy()
            df_sorted[date_col] = pd.to_datetime(df_sorted[date_col], errors='coerce')
            df_sorted = df_sorted.dropna(subset=[date_col]).sort_values(date_col)

            if len(df_sorted) < 5:
                continue

            for num_col in numeric_cols:
                if num_col not in df_sorted.columns:
                    continue

                series = df_sorted[num_col].dropna()
                if len(series) < 5:
                    continue

                # Simple linear trend detection using first/last halves
                first_half_mean = series.head(len(series)//2).mean()
                second_half_mean = series.tail(len(series)//2).mean()

                if first_half_mean > 0:
                    pct_change = (second_half_mean - first_half_mean) / first_half_mean * 100

                    if abs(pct_change) > 20:  # >20% change between halves
                        trend_dir = "increasing" if pct_change > 0 else "decreasing"
                        patterns.append(PatternInsight(
                            pattern_type="time_trend",
                            description=f"Column '{num_col}' shows {trend_dir} trend over time ({pct_change:+.1f}% change)",
                            severity="notable" if abs(pct_change) > 50 else "info",
                            details={
                                "column": num_col,
                                "date_column": date_col,
                                "pct_change": round(pct_change, 1),
                                "first_half_mean": round(float(first_half_mean), 2),
                                "second_half_mean": round(float(second_half_mean), 2),
                            }
                        ))
        except Exception:
            continue  # Skip if date parsing fails

    return patterns


def detect_correlations(df: pd.DataFrame, numeric_cols: List[str]) -> List[PatternInsight]:
    """Detect strong correlations between numeric columns."""
    patterns = []

    if len(numeric_cols) < 2:
        return patterns

    numeric_df = df[numeric_cols].dropna()
    if len(numeric_df) < 10:
        return patterns

    try:
        corr_matrix = numeric_df.corr()

        # Find strong correlations (>0.7 or <-0.7), excluding self-correlations
        for i, col1 in enumerate(numeric_cols):
            for col2 in numeric_cols[i+1:]:
                if col1 in corr_matrix.columns and col2 in corr_matrix.columns:
                    corr_val = corr_matrix.loc[col1, col2]
                    if abs(corr_val) > 0.7:
                        corr_type = "positive" if corr_val > 0 else "negative"
                        patterns.append(PatternInsight(
                            pattern_type="correlation",
                            description=f"Strong {corr_type} correlation ({corr_val:.2f}) between '{col1}' and '{col2}'",
                            severity="notable",
                            details={
                                "column_1": col1,
                                "column_2": col2,
                                "correlation": round(float(corr_val), 3),
                            }
                        ))
    except Exception:
        pass

    return patterns


def detect_data_quality_issues(df: pd.DataFrame, column_stats: List[ColumnStats]) -> List[PatternInsight]:
    """Detect data quality issues."""
    patterns = []

    for stats in column_stats:
        # High null rate
        if stats.null_rate > 0.1:  # >10% nulls
            severity = "significant" if stats.null_rate > 0.3 else "notable"
            patterns.append(PatternInsight(
                pattern_type="data_quality",
                description=f"Column '{stats.column_name}' has high null rate ({stats.null_rate*100:.1f}%)",
                severity=severity,
                details={
                    "column": stats.column_name,
                    "null_rate": round(stats.null_rate * 100, 1),
                    "null_count": stats.null_count,
                }
            ))

        # Single value dominance (low cardinality)
        if stats.unique_count == 1 and stats.non_null_count > 0:
            patterns.append(PatternInsight(
                pattern_type="data_quality",
                description=f"Column '{stats.column_name}' has only one unique value",
                severity="info",
                details={
                    "column": stats.column_name,
                    "unique_count": stats.unique_count,
                }
            ))

    return patterns


# ============================================================================
# MAIN ANALYSIS FUNCTION
# ============================================================================

def analyze_csv(csv_path: str) -> AnalysisResult:
    """
    Perform comprehensive analysis on a CSV file.

    Args:
        csv_path: Path to the CSV file

    Returns:
        AnalysisResult with statistics, patterns, and recommendations
    """
    # Load data
    df = pd.read_csv(csv_path)

    # Compute basic statistics
    dataset_stats = compute_dataset_stats(df)

    # Detect patterns
    patterns = []
    patterns.extend(detect_outliers(df, dataset_stats.numeric_columns))
    patterns.extend(detect_concentration(df, dataset_stats.numeric_columns, dataset_stats.categorical_columns))
    patterns.extend(detect_time_trends(df, dataset_stats.date_columns, dataset_stats.numeric_columns))
    patterns.extend(detect_correlations(df, dataset_stats.numeric_columns))
    patterns.extend(detect_data_quality_issues(df, dataset_stats.column_stats))

    # Sort patterns by severity
    severity_order = {"significant": 0, "notable": 1, "info": 2}
    patterns.sort(key=lambda p: severity_order.get(p.severity, 3))

    # Generate recommendations
    recommendations = generate_recommendations(patterns)

    return AnalysisResult(
        csv_path=csv_path,
        dataset_stats=dataset_stats,
        patterns=patterns,
        recommendations=recommendations,
    )


def generate_recommendations(patterns: List[PatternInsight]) -> List[str]:
    """Generate actionable recommendations based on detected patterns."""
    recommendations = []

    pattern_types = {p.pattern_type for p in patterns}

    if "outlier" in pattern_types:
        recommendations.append("Investigate outliers to determine if they represent data quality issues or genuine extreme values")

    if "pareto" in pattern_types or "concentration" in pattern_types:
        recommendations.append("Consider segmenting analysis by high-concentration dimensions to understand behavior differences")

    if "time_trend" in pattern_types:
        recommendations.append("Time-based trends detected; consider analyzing what external factors may be driving changes")

    if "correlation" in pattern_types:
        recommendations.append("Strong correlations found; verify if relationships are causal or coincidental before drawing conclusions")

    if "data_quality" in pattern_types:
        recommendations.append("Address data quality issues (nulls, single values) before relying on affected columns for analysis")

    return recommendations


# ============================================================================
# JSON OUTPUT
# ============================================================================

def result_to_dict(result: AnalysisResult) -> Dict[str, Any]:
    """Convert AnalysisResult to a JSON-serializable dictionary."""
    return {
        "csv_path": result.csv_path,
        "dataset_stats": {
            "row_count": result.dataset_stats.row_count,
            "column_count": result.dataset_stats.column_count,
            "date_columns": result.dataset_stats.date_columns,
            "numeric_columns": result.dataset_stats.numeric_columns,
            "categorical_columns": result.dataset_stats.categorical_columns,
            "column_stats": [asdict(cs) for cs in result.dataset_stats.column_stats],
        },
        "patterns": [asdict(p) for p in result.patterns],
        "recommendations": result.recommendations,
    }


def format_as_json(result: AnalysisResult) -> str:
    """Format analysis result as JSON string."""
    return json.dumps(result_to_dict(result), indent=2)


# ============================================================================
# CLI INTERFACE
# ============================================================================

def main():
    """Command-line interface for CSV analysis."""
    if len(sys.argv) < 2:
        print("Usage: python analyze_csv.py <csv_path> [output_path]", file=sys.stderr)
        print("  csv_path: Path to CSV file to analyze", file=sys.stderr)
        print("  output_path: Optional path for JSON output (default: same dir as CSV)", file=sys.stderr)
        sys.exit(1)

    csv_path = sys.argv[1]

    if not Path(csv_path).exists():
        print(f"Error: File not found: {csv_path}", file=sys.stderr)
        sys.exit(1)

    # Determine output path
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        # Default: replace _result.csv with _analysis.json
        output_path = csv_path.replace("_result.csv", "_analysis.json")

    # Run analysis
    print(f"Analyzing: {csv_path}", file=sys.stderr)
    result = analyze_csv(csv_path)

    # Format and output
    json_output = format_as_json(result)

    with open(output_path, 'w') as f:
        f.write(json_output)

    print(f"Analysis saved to: {output_path}", file=sys.stderr)

    # Print summary to stdout
    print(f"\nSummary: {result.dataset_stats.row_count} rows, {len(result.patterns)} patterns detected")


if __name__ == "__main__":
    main()
