import { useRef, useState, useEffect, useCallback } from 'react';
import {
  Card,
  Text,
  Title,
  Accordion,
  AccordionHeader,
  AccordionBody,
  List,
  ListItem,
  Grid,
  AreaChart,
  BarChart,
  DonutChart,
  Table,
  TableHead,
  TableHeaderCell,
  TableBody,
  TableRow,
  TableCell,
  Badge,
  Button,
  Flex,
} from '@tremor/react';
import {
  ResponsiveContainer,
  ComposedChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from 'recharts';
import {
  RiDownloadLine,
  RiIndeterminateCircleLine,
  RiCheckboxCircleFill,
  RiCloseCircleLine,
  RiFirstAidKitLine,
  RiImage2Line,
  RiCloseLine,
} from '@remixicon/react';
import type { QuerySection as QuerySectionType, ChartConfig, ChartDataPoint, ChartQAStatus } from '../types';
import { parseCSV } from '../utils/csv';
import { downloadChartAsImage } from '../utils/downloadChart';

// QA Status icon configuration
const qaStatusConfig: Record<ChartQAStatus, { icon: React.ComponentType<{ className?: string }>; color: string; tooltip: string }> = {
  pending: {
    icon: RiIndeterminateCircleLine,
    color: 'text-gray-400',
    tooltip: 'This chart has not been checked for quality assurance by an agent',
  },
  passed: {
    icon: RiCheckboxCircleFill,
    color: 'text-green-500',
    tooltip: 'This chart has been verified by an agent',
  },
  failed: {
    icon: RiCloseCircleLine,
    color: 'text-red-500',
    tooltip: 'This chart failed quality assurance checks',
  },
  needs_repair: {
    icon: RiFirstAidKitLine,
    color: 'text-orange-500',
    tooltip: 'Repaired by agent. Click to view original',
  },
};

interface QAStatusIconProps {
  status?: ChartQAStatus;
  onClick?: () => void;
  hasOriginal?: boolean;
}

function QAStatusIcon({ status, onClick, hasOriginal }: QAStatusIconProps) {
  const config = qaStatusConfig[status || 'pending'];
  const Icon = config.icon;
  const isClickable = status === 'needs_repair' && hasOriginal && onClick;

  const iconElement = (
    <Icon className={`w-5 h-5 ${config.color} ${isClickable ? 'cursor-pointer' : 'cursor-help'}`} />
  );

  return (
    <span className="relative inline-flex items-center ml-1 group align-middle">
      {isClickable ? (
        <button
          onClick={onClick}
          className="p-0.5 hover:bg-orange-50 rounded transition-colors"
          aria-label="View original screenshot"
        >
          {iconElement}
        </button>
      ) : (
        iconElement
      )}
      <span className="absolute left-1/2 -translate-x-1/2 bottom-full mb-2 px-4 py-3 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg shadow-lg w-48 text-center opacity-0 group-hover:opacity-100 transition-opacity duration-150 pointer-events-none z-50">
        {config.tooltip}
        <span className="absolute left-1/2 -translate-x-1/2 top-full border-4 border-transparent border-t-white" />
      </span>
    </span>
  );
}

// Expandable panel to show original screenshot below current chart
interface ComparisonPanelProps {
  imagePath: string;
  title: string;
  qaIssue?: string;
  qaFix?: string;
  isFailed?: boolean;
  isOpen: boolean;
  onClose: () => void;
}

function ComparisonPanel({ imagePath, title, qaIssue, qaFix, isFailed, isOpen, onClose }: ComparisonPanelProps) {
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) onClose();
    };
    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const borderColor = isFailed ? 'border-red-200' : 'border-orange-200';
  const bgColor = isFailed ? 'bg-red-50/30' : 'bg-orange-50/30';
  const textColor = isFailed ? 'text-red-600' : 'text-orange-600';
  const hoverBg = isFailed ? 'hover:bg-red-100' : 'hover:bg-orange-100';
  const iconColor = isFailed ? 'text-red-500' : 'text-orange-500';
  const headerText = isFailed ? 'Original (Unfixed)' : 'Original (Before Repair)';

  return (
    <div className={`mt-4 pt-4 border-t ${borderColor} ${bgColor} -mx-4 px-4 pb-4 rounded-b-lg`}>
      <div className="flex justify-between items-center mb-3">
        <Text className={`text-sm font-medium ${textColor}`}>{headerText}</Text>
        <button
          onClick={onClose}
          className={`p-1 ${hoverBg} rounded-full transition-colors`}
          aria-label="Close comparison"
        >
          <RiCloseLine className={`w-4 h-4 ${iconColor}`} />
        </button>
      </div>
      {(qaIssue || qaFix) && (
        <div className={`mb-3 p-2 bg-white rounded border ${borderColor}`}>
          {qaIssue && (
            <Text className="text-xs text-gray-600">
              <span className={`font-medium ${textColor}`}>Issue:</span> {qaIssue}
            </Text>
          )}
          {qaFix && (
            <Text className="text-xs text-gray-600 mt-1">
              <span className="font-medium text-green-600">Fix applied:</span> {qaFix}
            </Text>
          )}
        </div>
      )}
      <div className="flex justify-center">
        <img
          src={imagePath}
          alt={`Original screenshot of ${title}`}
          className={`max-w-full h-auto rounded border ${borderColor}`}
        />
      </div>
    </div>
  );
}

// Button to view original screenshot (for repaired and failed charts)
interface ViewOriginalButtonProps {
  chart: ChartConfig;
  onViewOriginal: () => void;
}

function ViewOriginalButton({ chart, onViewOriginal }: ViewOriginalButtonProps) {
  // Only render for failed status - needs_repair uses clickable QAStatusIcon instead
  const hasScreenshot = chart.qaStatus === 'failed' && chart.originalScreenshotPath;
  if (!hasScreenshot) {
    return null;
  }

  return (
    <span className="relative inline-flex items-center ml-1 group align-middle">
      <button
        onClick={onViewOriginal}
        className="p-0.5 hover:bg-red-50 rounded transition-colors"
        aria-label={`View original screenshot of ${chart.title}`}
      >
        <RiImage2Line className="w-4 h-4 text-red-400 hover:text-red-600 cursor-pointer" />
      </button>
      <span className="absolute left-1/2 -translate-x-1/2 bottom-full mb-2 px-4 py-3 text-sm text-gray-700 bg-white border border-gray-200 rounded-lg shadow-lg w-48 text-center opacity-0 group-hover:opacity-100 transition-opacity duration-150 pointer-events-none z-50">
        View issue details
        <span className="absolute left-1/2 -translate-x-1/2 top-full border-4 border-transparent border-t-white" />
      </span>
    </span>
  );
}

// Hook to detect when element is visible in viewport
function useInView(options?: IntersectionObserverInit) {
  const ref = useRef<HTMLDivElement>(null);
  const [isInView, setIsInView] = useState(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        // Once visible, stay visible (don't re-animate on scroll back)
        if (entry.isIntersecting) {
          setIsInView(true);
          observer.disconnect();
        }
      },
      { threshold: 0.1, ...options }
    );

    observer.observe(element);
    return () => observer.disconnect();
  }, [options]);

  return { ref, isInView };
}

// Wrapper component for lazy-rendered charts
function LazyChart({ children }: { children: React.ReactNode }) {
  const { ref, isInView } = useInView({ threshold: 0.3 });

  return (
    <div ref={ref} className="min-h-[294px]">
      {isInView ? children : (
        <div className="h-[294px] flex items-center justify-center text-gray-400">
          <span className="animate-pulse">Loading chart...</span>
        </div>
      )}
    </div>
  );
}

// Wrapper component for chart with download button
interface ChartWithDownloadProps {
  chart: ChartConfig;
  children: React.ReactNode;
}

function ChartWithDownload({ chart, children }: ChartWithDownloadProps) {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const buttonRef = useRef<HTMLButtonElement>(null);
  const [isDownloading, setIsDownloading] = useState(false);
  const [showComparison, setShowComparison] = useState(false);

  const handleDownload = useCallback(async () => {
    if (!chartContainerRef.current) return;

    setIsDownloading(true);
    try {
      // Hide button before capture
      if (buttonRef.current) {
        buttonRef.current.style.display = 'none';
      }
      await downloadChartAsImage(chartContainerRef.current, chart.title);
    } catch (error) {
      console.error('Download failed:', error);
    } finally {
      // Restore button visibility
      if (buttonRef.current) {
        buttonRef.current.style.display = '';
      }
      setIsDownloading(false);
    }
  }, [chart.title]);

  const hasOriginalScreenshot = (chart.qaStatus === 'needs_repair' || chart.qaStatus === 'failed') && chart.originalScreenshotPath;

  return (
    <>
      <div ref={chartContainerRef}>
        <Flex justifyContent="between" alignItems="start" className="mb-3">
          <Text className="font-medium text-gray-700">
            {chart.title}
            <QAStatusIcon
              status={chart.qaStatus}
              hasOriginal={!!chart.originalScreenshotPath}
              onClick={() => setShowComparison(!showComparison)}
            />
            <ViewOriginalButton
              chart={chart}
              onViewOriginal={() => setShowComparison(!showComparison)}
            />
          </Text>
          <Button
            ref={buttonRef}
            variant="light"
            size="xs"
            icon={RiDownloadLine}
            onClick={handleDownload}
            loading={isDownloading}
            className="no-print"
            aria-label={`Download ${chart.title} as image`}
          />
        </Flex>
        {children}
      </div>
      {hasOriginalScreenshot && (
        <ComparisonPanel
          imagePath={chart.originalScreenshotPath!}
          title={chart.title}
          qaIssue={chart.qaIssue}
          qaFix={chart.qaFix}
          isFailed={chart.qaStatus === 'failed'}
          isOpen={showComparison}
          onClose={() => setShowComparison(false)}
        />
      )}
    </>
  );
}

interface QuerySectionProps {
  query: QuerySectionType;
}

export function QuerySection({ query }: QuerySectionProps) {
  // Parse CSV data once for charts and raw data display
  const parsedData = parseCSV(query.csvData);

  // Format large numbers compactly (e.g., 1.5M, 250K)
  const formatYAxisValue = (value: number): string => {
    if (value >= 1_000_000) {
      return `${(value / 1_000_000).toFixed(1)}M`;
    }
    if (value >= 1_000) {
      return `${(value / 1_000).toFixed(0)}K`;
    }
    return value.toString();
  };

  // Apply xKey transformation if specified
  const applyXKeyTransform = (value: string, transform?: 'prefix'): string => {
    if (!transform) return value;
    if (transform === 'prefix') {
      // Extract text before first ':' (e.g., "Screenshot: Other" → "Screenshot")
      const colonIndex = value.indexOf(':');
      return colonIndex > 0 ? value.substring(0, colonIndex).trim() : value || '(empty)';
    }
    return value;
  };

  // Helper to detect pure numeric strings (for sorting numeric values stored as strings)
  const isNumericString = (val: unknown): boolean => {
    return typeof val === 'string' && /^-?\d+(\.\d+)?$/.test(val);
  };

  // Pivot data when categoryKey is specified
  // Transforms rows with categoryKey values into columns
  // Aggregates (sums) values when multiple rows exist for the same xKey + categoryKey
  const pivotData = (
    data: ChartDataPoint[],
    xKey: string,
    yKey: string,
    categoryKey: string,
    xKeyTransform?: 'prefix',
    sortOrder?: string[]
  ): { pivotedData: ChartDataPoint[]; categories: string[] } => {
    // Get unique category values
    const categorySet = new Set<string>();
    data.forEach(row => {
      if (row[categoryKey] !== undefined && row[categoryKey] !== null) {
        categorySet.add(String(row[categoryKey]));
      }
    });
    const categories = Array.from(categorySet).sort();

    // Group by transformed xKey and pivot, summing values for each category
    const grouped = new Map<string, ChartDataPoint>();
    data.forEach(row => {
      const rawXValue = String(row[xKey] ?? '');
      const xValue = applyXKeyTransform(rawXValue, xKeyTransform);
      const category = String(row[categoryKey]);
      const yValue = typeof row[yKey] === 'number' ? row[yKey] : Number(row[yKey]) || 0;

      if (!grouped.has(xValue)) {
        grouped.set(xValue, { [xKey]: xValue });
      }
      const point = grouped.get(xValue)!;
      // Sum values when multiple rows exist for the same xKey + categoryKey
      point[category] = ((point[category] as number) || 0) + yValue;
    });

    // Sort by xKey (use sortOrder if provided, otherwise numeric then lexicographic)
    const pivotedData = Array.from(grouped.values()).sort((a, b) => {
      const aVal = a[xKey];
      const bVal = b[xKey];

      // Use explicit sortOrder if provided
      if (sortOrder && sortOrder.length > 0) {
        const aIndex = sortOrder.indexOf(String(aVal));
        const bIndex = sortOrder.indexOf(String(bVal));
        // Items not in sortOrder go to the end
        const aPos = aIndex === -1 ? sortOrder.length : aIndex;
        const bPos = bIndex === -1 ? sortOrder.length : bIndex;
        return aPos - bPos;
      }

      // Sort numerically if both are numbers or pure numeric strings
      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return aVal - bVal;
      }
      if (isNumericString(aVal) && isNumericString(bVal)) {
        return parseFloat(aVal as string) - parseFloat(bVal as string);
      }
      return String(aVal).localeCompare(String(bVal));
    });

    return { pivotedData, categories };
  };

  // Sort data by xKey for time series (date-based) charts
  const sortByXKey = (data: ChartDataPoint[], xKey: string, sortOrder?: string[]): ChartDataPoint[] => {
    if (data.length === 0) return data;

    // Use explicit sortOrder if provided
    if (sortOrder && sortOrder.length > 0) {
      return [...data].sort((a, b) => {
        const aIndex = sortOrder.indexOf(String(a[xKey]));
        const bIndex = sortOrder.indexOf(String(b[xKey]));
        const aPos = aIndex === -1 ? sortOrder.length : aIndex;
        const bPos = bIndex === -1 ? sortOrder.length : bIndex;
        return aPos - bPos;
      });
    }

    // Check if xKey appears to be a date field
    const isDateField = xKey.toLowerCase().includes('date') ||
                        xKey.toLowerCase().includes('week') ||
                        xKey.toLowerCase().includes('month') ||
                        xKey.toLowerCase().includes('day');

    if (!isDateField) return data;

    return [...data].sort((a, b) => {
      const aVal = a[xKey];
      const bVal = b[xKey];
      // Sort numerically if both are numbers or pure numeric strings
      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return aVal - bVal;
      }
      if (isNumericString(aVal) && isNumericString(bVal)) {
        return parseFloat(aVal as string) - parseFloat(bVal as string);
      }
      return String(aVal).localeCompare(String(bVal));
    });
  };

  // Aggregate data by xKey, summing or averaging yKey values for each unique xKey
  const aggregateData = (
    data: ChartDataPoint[],
    xKey: string,
    yKey: string | string[],
    aggFunc: 'sum' | 'avg' = 'sum'
  ): ChartDataPoint[] => {
    const yKeys = Array.isArray(yKey) ? yKey : [yKey];
    const grouped = new Map<string, ChartDataPoint>();
    const counts = new Map<string, number>();

    data.forEach(row => {
      const xValue = String(row[xKey] ?? '');

      if (!grouped.has(xValue)) {
        const newPoint: ChartDataPoint = { [xKey]: xValue };
        yKeys.forEach(key => { newPoint[key] = 0; });
        grouped.set(xValue, newPoint);
        counts.set(xValue, 0);
      }

      const point = grouped.get(xValue)!;
      counts.set(xValue, (counts.get(xValue) || 0) + 1);
      yKeys.forEach(key => {
        const yValue = typeof row[key] === 'number' ? row[key] : Number(row[key]) || 0;
        point[key] = ((point[key] as number) || 0) + yValue;
      });
    });

    // If averaging, divide by count
    if (aggFunc === 'avg') {
      grouped.forEach((point, xValue) => {
        const count = counts.get(xValue) || 1;
        yKeys.forEach(key => {
          point[key] = Math.round(((point[key] as number) / count) * 100) / 100;
        });
      });
    }

    // Sort by yKey descending (largest first) for better visualization
    const primaryYKey = yKeys[0];
    return Array.from(grouped.values()).sort((a, b) => {
      return (b[primaryYKey] as number) - (a[primaryYKey] as number);
    });
  };

  const renderChart = (chart: ChartConfig, data: ChartDataPoint[]) => {
    const colors = chart.colors || ['blue', 'cyan', 'indigo', 'violet', 'fuchsia'];

    // Apply filter(s) if specified
    let filteredData = data;
    if (chart.filter) {
      const filters = Array.isArray(chart.filter) ? chart.filter : [chart.filter];
      filteredData = data.filter(row =>
        filters.every(f => {
          const matches = String(row[f.field]) === f.value;
          return f.exclude ? !matches : matches;
        })
      );
    }

    // Handle categoryKey - pivot data and determine categories
    let chartData = filteredData;
    let chartCategories: string[];

    if (chart.categoryKey && typeof chart.yKey === 'string') {
      const pivotResult = pivotData(filteredData, chart.xKey, chart.yKey, chart.categoryKey, chart.xKeyTransform, chart.sortOrder);
      chartData = pivotResult.pivotedData;
      chartCategories = pivotResult.categories;
    } else if (chart.aggregate) {
      // Aggregate data by xKey, summing yKey values for each unique xKey
      chartCategories = Array.isArray(chart.yKey) ? chart.yKey : [chart.yKey];
      chartData = aggregateData(filteredData, chart.xKey, chart.yKey, chart.aggregateFunction || 'sum');
    } else {
      chartCategories = Array.isArray(chart.yKey) ? chart.yKey : [chart.yKey];
      // Sort by xKey for time series without categoryKey (pivotData already sorts)
      chartData = sortByXKey(filteredData, chart.xKey, chart.sortOrder);
    }

    // Apply offset if specified (e.g., "Ranks 21-50" charts that skip first N rows)
    if (chart.offset && chart.offset > 0) {
      chartData = chartData.slice(chart.offset);
    }

    // Apply limit if specified (e.g., "Top 10" charts)
    if (chart.limit && chart.limit > 0 && chartData.length > chart.limit) {
      chartData = chartData.slice(0, chart.limit);
    }

    switch (chart.type) {
      case 'area':
        return (
          <AreaChart
            className="h-[294px]"
            data={chartData}
            index={chart.xKey}
            categories={chartCategories}
            colors={colors}
            showAnimation
            curveType="monotone"
            yAxisWidth={56}
            valueFormatter={formatYAxisValue}
            enableLegendSlider={true}
          />
        );

      case 'line':
        // Handle dual y-axis for comparing metrics with different scales
        if (chart.secondaryYAxis && Array.isArray(chart.yKey) && chart.yKey.length === 2) {
          const primaryYKey = chart.yKey.find(k => k !== chart.secondaryYAxis!.yKey) || chart.yKey[0];
          const secondaryYKey = chart.secondaryYAxis.yKey;
          const secondaryFormatter = chart.secondaryYAxis.formatter === 'percent'
            ? (value: number) => `${value.toFixed(1)}%`
            : formatYAxisValue;

          // Tremor color palette mapping
          const colorMap: Record<string, string> = {
            blue: '#3b82f6',
            cyan: '#06b6d4',
            indigo: '#6366f1',
            violet: '#8b5cf6',
            fuchsia: '#d946ef',
            emerald: '#10b981',
            green: '#22c55e',
            orange: '#f97316',
            red: '#ef4444',
          };

          const primaryColor = colorMap[colors[0]] || '#3b82f6';
          const secondaryColor = colorMap[colors[1] || 'emerald'] || '#10b981';

          return (
            <ResponsiveContainer width="100%" height={294}>
              <ComposedChart data={chartData} margin={{ top: 30, right: 60, left: 10, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" vertical={false} />
                <XAxis
                  dataKey={chart.xKey}
                  tick={{ fontSize: 12, fill: '#6b7280', fontWeight: 400 }}
                  tickLine={false}
                  axisLine={{ stroke: '#e5e7eb' }}
                />
                <YAxis
                  yAxisId="left"
                  tick={{ fontSize: 12, fill: '#6b7280', fontWeight: 400 }}
                  tickLine={false}
                  axisLine={false}
                  tickFormatter={formatYAxisValue}
                  width={56}
                />
                <YAxis
                  yAxisId="right"
                  orientation="right"
                  tick={{ fontSize: 12, fill: '#6b7280', fontWeight: 400 }}
                  tickLine={false}
                  axisLine={false}
                  tickFormatter={secondaryFormatter}
                  width={56}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '8px',
                    fontSize: '12px',
                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                  }}
                  formatter={(value: number, name: string) => {
                    const formatted = name === secondaryYKey ? secondaryFormatter(value) : formatYAxisValue(value);
                    return [formatted, name];
                  }}
                />
                <Legend
                  wrapperStyle={{ fontSize: '12px', paddingBottom: '10px' }}
                  iconType="circle"
                  verticalAlign="top"
                />
                <Line
                  yAxisId="left"
                  type="monotone"
                  dataKey={primaryYKey}
                  stroke={primaryColor}
                  strokeWidth={2}
                  dot={false}
                  name={primaryYKey}
                />
                <Line
                  yAxisId="right"
                  type="monotone"
                  dataKey={secondaryYKey}
                  stroke={secondaryColor}
                  strokeWidth={2}
                  dot={false}
                  name={secondaryYKey}
                />
              </ComposedChart>
            </ResponsiveContainer>
          );
        }

        return (
          <AreaChart
            className="h-[294px]"
            data={chartData}
            index={chart.xKey}
            categories={chartCategories}
            colors={colors}
            showAnimation
            curveType="monotone"
            connectNulls
            yAxisWidth={56}
            valueFormatter={formatYAxisValue}
            enableLegendSlider={true}
          />
        );

      case 'bar':
        return (
          <BarChart
            className="h-[294px]"
            data={chartData}
            index={chart.xKey}
            categories={chartCategories}
            colors={colors}
            showAnimation
            yAxisWidth={56}
            valueFormatter={formatYAxisValue}
            rotateLabelX={chart.rotateLabelX}
          />
        );

      case 'donut':
        // Use aggregated data for donut charts when aggregate flag is set
        const donutData = chart.aggregate
          ? aggregateData(filteredData, chart.xKey, chart.yKey, chart.aggregateFunction || 'sum')
          : filteredData;
        return (
          <DonutChart
            className="h-[294px]"
            data={donutData}
            category={chart.yKey as string}
            index={chart.xKey}
            colors={colors}
            showAnimation
            variant="pie"
            valueFormatter={formatYAxisValue}
          />
        );

      default:
        return <Text>Unsupported chart type: {chart.type}</Text>;
    }
  };

  return (
    <Card id={query.id} className="mb-6 scroll-mt-4">
      <Title className="text-lg font-semibold text-gray-800 mb-2">
        {query.title}
      </Title>

      <Text className="text-gray-600 mb-4">{query.summary}</Text>

      {/* Observations */}
      {query.observations.length > 0 && (
        <div className="mb-4">
          <Text className="font-medium text-gray-700 mb-2">Key Observations:</Text>
          <List>
            {query.observations.map((obs, idx) => (
              <ListItem key={idx}>
                <Text className="text-gray-600">{obs}</Text>
              </ListItem>
            ))}
          </List>
        </div>
      )}

      {/* Charts */}
      {query.charts.length > 0 && (
        <Grid numItemsSm={1} numItemsLg={query.charts.length > 1 ? 2 : 1} className="gap-4 mb-4">
          {query.charts.map((chart) => (
            <Card key={chart.id} className="p-4" data-chart-id={chart.id}>
              <ChartWithDownload chart={chart}>
                <LazyChart>
                  {renderChart(chart, parsedData)}
                </LazyChart>
              </ChartWithDownload>
            </Card>
          ))}
        </Grid>
      )}

      {/* SQL Query Accordion */}
      <Accordion className="mt-4">
        <AccordionHeader className="text-sm font-medium text-gray-600">
          View SQL Query
        </AccordionHeader>
        <AccordionBody>
          <pre className="bg-gray-900 text-gray-100 p-4 rounded-lg text-xs overflow-x-auto whitespace-pre-wrap">
            {query.sql}
          </pre>
        </AccordionBody>
      </Accordion>

      {/* Raw Data Accordion */}
      <Accordion className="mt-2">
        <AccordionHeader className="text-sm font-medium text-gray-600">
          <span className="flex items-center gap-2">
            View Raw Data
            <Badge size="sm" color="gray">
              {parsedData.length} rows
            </Badge>
          </span>
        </AccordionHeader>
        <AccordionBody>
          <Text className="text-xs text-gray-500 mb-3 font-mono">{query.csvPath}</Text>
          {parsedData.length === 0 ? (
            <Text className="text-gray-500">No data available</Text>
          ) : (
            <Table className="text-xs">
              <TableHead>
                <TableRow>
                  {Object.keys(parsedData[0]).map((key) => (
                    <TableHeaderCell key={key}>{key}</TableHeaderCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {parsedData.map((row, rowIdx) => (
                  <TableRow key={rowIdx}>
                    {Object.values(row).map((value, colIdx) => (
                      <TableCell key={colIdx}>
                        {typeof value === 'number'
                          ? value.toLocaleString()
                          : String(value)}
                      </TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </AccordionBody>
      </Accordion>
    </Card>
  );
}
