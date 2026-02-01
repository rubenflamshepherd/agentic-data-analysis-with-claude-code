import { chromium, Page, Download } from 'playwright';
import * as path from 'path';
import * as fs from 'fs';

interface ExportOptions {
  outputDir: string;
  chartIds?: string[];
  chartId?: string;        // Single chart ID filter
  tableName?: string;      // Table name filter (required with --chart-id)
  tableFilter?: string;    // Legacy filter (--table flag)
  baseUrl: string;
}

interface ChartExport {
  title: string;
  filename: string;
  chartId: string | null;
  tableName: string | null;
}

function parseArgs(): ExportOptions {
  const args = process.argv.slice(2);
  let outputDir = './screenshots';
  let chartIds: string[] | undefined;
  let chartId: string | undefined;
  let tableName: string | undefined;
  let tableFilter: string | undefined;
  let baseUrl = 'http://localhost:8000';

  for (const arg of args) {
    if (arg.startsWith('--output=')) {
      outputDir = arg.replace('--output=', '');
    } else if (arg.startsWith('--chart-ids=')) {
      chartIds = arg.replace('--chart-ids=', '').split(',');
    } else if (arg.startsWith('--chart-id=')) {
      chartId = arg.replace('--chart-id=', '');
    } else if (arg.startsWith('--table-name=')) {
      tableName = arg.replace('--table-name=', '');
    } else if (arg.startsWith('--table=')) {
      tableFilter = arg.replace('--table=', '');
    } else if (arg.startsWith('--base-url=')) {
      baseUrl = arg.replace('--base-url=', '');
    }
  }

  return { outputDir, chartIds, chartId, tableName, tableFilter, baseUrl };
}

async function waitForCharts(page: Page): Promise<void> {
  // Scroll through the page to trigger lazy loading
  await page.evaluate(`
    (async () => {
      const sleep = (ms) => new Promise(r => setTimeout(r, ms));
      const scrollHeight = document.body.scrollHeight;
      for (let y = 0; y < scrollHeight; y += 300) {
        window.scrollTo(0, y);
        await sleep(100);
      }
      window.scrollTo(0, 0);
    })()
  `);

  // Wait for any animations to complete
  await page.waitForTimeout(500);
}

async function exportChartsOnCurrentTab(
  page: Page,
  outputDir: string,
  options: ExportOptions,
  exports: Map<string, ChartExport>
): Promise<void> {
  await waitForCharts(page);

  // Find all VISIBLE download buttons on current tab
  const buttons = await page.locator('button[aria-label^="Download"][aria-label$="as image"]:visible').all();

  for (const button of buttons) {
    // Double-check visibility
    const isVisible = await button.isVisible().catch(() => false);
    if (!isVisible) continue;

    const ariaLabel = await button.getAttribute('aria-label');
    if (!ariaLabel) continue;

    // Extract chart title from aria-label: "Download {title} as image"
    const chartTitle = ariaLabel.replace('Download ', '').replace(' as image', '');
    const filename = sanitizeFilename(chartTitle);

    // Skip if already downloaded
    if (exports.has(chartTitle)) {
      continue;
    }

    // Get chart ID from parent element
    const card = button.locator('xpath=ancestor::div[@data-chart-id]').first();
    const chartId = await card.getAttribute('data-chart-id').catch(() => null);

    // Extract table name from chart ID (format: {table_name}-{query_id}-chart-{n})
    const tableName = chartId ? chartId.split('-').slice(0, -3).join('-').replace(/-/g, '_') : null;

    // Check single chart ID filter
    if (options.chartId && chartId !== options.chartId) {
      continue;
    }

    // Check multiple chart IDs filter
    if (options.chartIds && options.chartIds.length > 0) {
      if (chartId && !options.chartIds.includes(chartId)) {
        continue;
      }
    }

    try {
      // Scroll the card into view for screenshot
      await card.scrollIntoViewIfNeeded({ timeout: 5000 });
      await page.waitForTimeout(500); // Wait for chart animation to complete

      // Take screenshot of the chart card element directly
      const savePath = path.join(outputDir, `${filename}.png`);
      await card.screenshot({ path: savePath, type: 'png' });

      exports.set(chartTitle, {
        title: chartTitle,
        filename: `${filename}.png`,
        chartId,
        tableName
      });

      console.log(`Exported: ${savePath}`);
    } catch (error) {
      console.error(`Failed to export "${chartTitle}":`, (error as Error).message);
    }
  }
}

function sanitizeFilename(name: string): string {
  return name
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_-]/g, '')
    .slice(0, 100);
}

// Helper to normalize table names for comparison
function normalizeTableName(name: string): string {
  return name.toLowerCase().replace(/[_\s-]/g, '');
}

async function main() {
  const options = parseArgs();

  // Ensure output directory exists
  fs.mkdirSync(options.outputDir, { recursive: true });

  // Validate: --chart-id requires --table-name
  if (options.chartId && !options.tableName) {
    console.error('Error: --chart-id requires --table-name to be specified');
    console.error('Example: --table-name=fct_share_attempts --chart-id=fct_share_attempts-1-chart-1');
    process.exit(1);
  }

  // Use tableName as the effective table filter (falls back to legacy --table)
  const effectiveTableFilter = options.tableName || options.tableFilter;

  console.log(`Exporting charts to: ${options.outputDir}`);
  console.log(`Base URL: ${options.baseUrl}`);
  if (options.chartIds) {
    console.log(`Chart IDs filter: ${options.chartIds.join(', ')}`);
  }
  if (options.chartId) {
    console.log(`Chart ID filter: ${options.chartId}`);
  }
  if (options.tableName) {
    console.log(`Table name: ${options.tableName}`);
  } else if (options.tableFilter) {
    console.log(`Table filter: ${options.tableFilter}`);
  }

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    acceptDownloads: true,
    viewport: { width: 1920, height: 1080 }
  });
  const page = await context.newPage();

  const exports = new Map<string, ChartExport>();

  try {
    // Navigate to the report
    await page.goto(options.baseUrl, { waitUntil: 'networkidle' });
    console.log('Page loaded');

    // Get all main tabs
    const mainTabList = page.locator('[role="tablist"]').first();
    const mainTabs = await mainTabList.locator('[role="tab"]').all();

    for (let i = 0; i < mainTabs.length; i++) {
      const tab = mainTabs[i];
      const tabName = await tab.textContent();

      // Skip Overview, Research Questions, and Next Steps tabs (no charts)
      if (tabName === 'Overview' || tabName === 'Research Questions' || tabName === 'Next Steps') {
        continue;
      }

      console.log(`\nProcessing tab: ${tabName}`);
      await tab.click();
      await page.waitForTimeout(300);

      // Wait for tab content to load
      await page.waitForTimeout(500);

      // Check for nested tabs (Initial Analysis, Advanced Analysis)
      // Get visible nested tablists only
      const nestedTabList = page.locator('[role="tablist"]:visible').nth(1);
      const hasNestedTabs = await nestedTabList.isVisible().catch(() => false);

      if (hasNestedTabs) {
        // There are nested tabs - iterate through them
        const nestedTabCount = await nestedTabList.locator('[role="tab"]').count();

        for (let j = 0; j < nestedTabCount; j++) {
          // Re-locate the tab each iteration (DOM may change)
          const nestedTab = nestedTabList.locator('[role="tab"]').nth(j);
          const nestedTabName = await nestedTab.textContent();

          // Apply table filter if specified (skip silently if no match)
          if (effectiveTableFilter) {
            const normalizedFilter = normalizeTableName(effectiveTableFilter);
            const normalizedTabName = normalizeTableName(nestedTabName || '');
            if (!normalizedTabName.includes(normalizedFilter)) {
              continue;
            }
          }

          console.log(`  Processing sub-tab: ${nestedTabName}`);

          await nestedTab.click({ timeout: 5000 });
          await page.waitForTimeout(500);

          await exportChartsOnCurrentTab(page, options.outputDir, options, exports);

          // Early exit if we found the specific chart we're looking for
          if (options.chartId && exports.size > 0) {
            break;
          }
        }
      } else {
        // No nested tabs - export directly
        await exportChartsOnCurrentTab(page, options.outputDir, options, exports);
      }

      // Early exit from main tab loop if we found the specific chart
      if (options.chartId && exports.size > 0) {
        break;
      }
    }

    console.log(`\n✓ Exported ${exports.size} chart(s)`);

    // Print and save manifest
    if (exports.size > 0) {
      console.log('\nExported files:');
      const chartList: ChartExport[] = [];
      for (const [title, chartExport] of exports) {
        console.log(`  - ${title}: ${chartExport.filename} (${chartExport.chartId || 'no-id'})`);
        chartList.push(chartExport);
      }

      // Write manifest.json
      const manifest = {
        exportedAt: new Date().toISOString(),
        tableFilter: options.tableFilter || null,
        chartIdFilter: options.chartId || null,
        charts: chartList
      };
      const manifestPath = path.join(options.outputDir, 'manifest.json');
      fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
      console.log(`\nManifest saved to: ${manifestPath}`);
    }

  } catch (error) {
    console.error('Export failed:', error);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

main();
