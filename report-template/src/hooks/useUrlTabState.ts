import { useState, useCallback, useMemo } from 'react';

// URL slugs for primary tabs
const PRIMARY_TAB_SLUGS = [
  'overview',
  'research',
  'initial-analysis',
  'advanced-analysis',
  'next-steps',
] as const;

// When Advanced Analysis is absent, these are the slugs (no advanced-analysis)
const PRIMARY_TAB_SLUGS_NO_ADVANCED = [
  'overview',
  'research',
  'initial-analysis',
  'next-steps',
] as const;

type TabSlug = (typeof PRIMARY_TAB_SLUGS)[number];

interface TableLike {
  tableName: string;
}

interface UrlTabState {
  primaryTabIndex: number;
  initialTableIndex: number;
  advancedTableIndex: number;
  setPrimaryTab: (index: number) => void;
  setInitialTable: (index: number) => void;
  setAdvancedTable: (index: number) => void;
}

function toSlug(tableName: string): string {
  return tableName.toLowerCase().replace(/_/g, '-');
}

function findTableIndex(tables: TableLike[], slug: string | null): number {
  if (!slug || tables.length === 0) return 0;
  const index = tables.findIndex((t) => toSlug(t.tableName) === slug);
  return index === -1 ? 0 : index;
}

function getInitialState(
  tables: TableLike[],
  advancedTables: TableLike[],
  hasAdvanced: boolean
): { primary: number; initial: number; advanced: number } {
  const params = new URLSearchParams(window.location.search);
  const tabSlug = params.get('tab') as TabSlug | null;
  const tableSlug = params.get('table');

  // Determine primary tab index from slug
  const slugList = hasAdvanced ? PRIMARY_TAB_SLUGS : PRIMARY_TAB_SLUGS_NO_ADVANCED;
  let primaryIndex = tabSlug ? slugList.indexOf(tabSlug as any) : 0;
  if (primaryIndex === -1) primaryIndex = 0;

  // Determine table indices
  let initialIndex = 0;
  let advancedIndex = 0;

  // Map slug to appropriate tab index based on which tab we're on
  const actualSlug = slugList[primaryIndex];
  if (actualSlug === 'initial-analysis' && tableSlug) {
    initialIndex = findTableIndex(tables, tableSlug);
  } else if (actualSlug === 'advanced-analysis' && tableSlug) {
    advancedIndex = findTableIndex(advancedTables, tableSlug);
  }

  return { primary: primaryIndex, initial: initialIndex, advanced: advancedIndex };
}

function updateUrl(
  primaryIndex: number,
  tableIndex: number,
  tables: TableLike[],
  advancedTables: TableLike[],
  hasAdvanced: boolean
): void {
  const slugList = hasAdvanced ? PRIMARY_TAB_SLUGS : PRIMARY_TAB_SLUGS_NO_ADVANCED;
  const tabSlug = slugList[primaryIndex];

  const params = new URLSearchParams();

  // Only add tab param if not on overview (default)
  if (tabSlug !== 'overview') {
    params.set('tab', tabSlug);
  }

  // Add table param for initial-analysis or advanced-analysis
  if (tabSlug === 'initial-analysis' && tables.length > 0) {
    params.set('table', toSlug(tables[tableIndex].tableName));
  } else if (tabSlug === 'advanced-analysis' && advancedTables.length > 0) {
    params.set('table', toSlug(advancedTables[tableIndex].tableName));
  }

  const queryString = params.toString();
  const newUrl = queryString
    ? `${window.location.pathname}?${queryString}`
    : window.location.pathname;

  window.history.replaceState({}, '', newUrl);
}

export function useUrlTabState(
  tables: TableLike[],
  advancedTables: TableLike[]
): UrlTabState {
  const hasAdvanced = advancedTables.length > 0;

  // Compute initial state from URL (only on first render)
  const initialState = useMemo(
    () => getInitialState(tables, advancedTables, hasAdvanced),
    [] // Empty deps - only run once on mount
  );

  const [primaryTabIndex, setPrimaryTabIndexState] = useState(initialState.primary);
  const [initialTableIndex, setInitialTableIndexState] = useState(initialState.initial);
  const [advancedTableIndex, setAdvancedTableIndexState] = useState(initialState.advanced);

  const setPrimaryTab = useCallback(
    (index: number) => {
      setPrimaryTabIndexState(index);

      // Determine which table index to use based on tab
      const slugList = hasAdvanced ? PRIMARY_TAB_SLUGS : PRIMARY_TAB_SLUGS_NO_ADVANCED;
      const tabSlug = slugList[index];
      const isAdvanced = tabSlug === 'advanced-analysis';
      const tableIndex = isAdvanced ? advancedTableIndex : initialTableIndex;

      updateUrl(index, tableIndex, tables, advancedTables, hasAdvanced);
    },
    [tables, advancedTables, hasAdvanced, initialTableIndex, advancedTableIndex]
  );

  const setInitialTable = useCallback(
    (index: number) => {
      setInitialTableIndexState(index);
      updateUrl(primaryTabIndex, index, tables, advancedTables, hasAdvanced);
    },
    [primaryTabIndex, tables, advancedTables, hasAdvanced]
  );

  const setAdvancedTable = useCallback(
    (index: number) => {
      setAdvancedTableIndexState(index);
      updateUrl(primaryTabIndex, index, tables, advancedTables, hasAdvanced);
    },
    [primaryTabIndex, tables, advancedTables, hasAdvanced]
  );

  return {
    primaryTabIndex,
    initialTableIndex,
    advancedTableIndex,
    setPrimaryTab,
    setInitialTable,
    setAdvancedTable,
  };
}
