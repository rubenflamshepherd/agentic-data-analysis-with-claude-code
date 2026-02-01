import { useEffect } from 'react';
import {
  Card,
  Text,
  Flex,
  Badge,
} from '@tremor/react';
import type { TableAnalysis } from '../types';
import { QuerySection } from './QuerySection';

interface TableTabProps {
  table: TableAnalysis;
}

const statusColors: Record<string, 'green' | 'yellow' | 'red'> = {
  complete: 'green',
  stale: 'yellow',
  failed: 'red',
};

export function TableTab({ table }: TableTabProps) {
  // Scroll to hash element after mount (handles deep links to query sections)
  useEffect(() => {
    const hash = window.location.hash;
    if (hash) {
      // Small delay to ensure DOM is fully rendered
      requestAnimationFrame(() => {
        const element = document.querySelector(hash);
        element?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
    }
  }, []);

  return (
    <div className="space-y-6">
      {/* Table Header */}
      <Card>
        <Flex justifyContent="between" alignItems="start">
          <div>
            <Text className="text-xl font-bold text-gray-900 font-mono">
              {table.tableName}
            </Text>
            <Text className="mt-1 text-gray-600">{table.description}</Text>
          </div>
          <Badge color={statusColors[table.status]} size="lg">
            {table.status}
          </Badge>
        </Flex>

        <Flex className="mt-4 gap-6" justifyContent="start">
          {table.rowCount && (
            <Text className="text-sm text-gray-500">
              <span className="font-medium">Rows:</span>{' '}
              {table.rowCount.toLocaleString()}
            </Text>
          )}
          {table.dateRange && (
            <Text className="text-sm text-gray-500">
              <span className="font-medium">Date Range:</span> {table.dateRange}
            </Text>
          )}
          <Text className="text-sm text-gray-500">
            <span className="font-medium">Queries:</span> {table.queries.length}
          </Text>
        </Flex>
      </Card>

      {/* Query Sections */}
      {table.queries.length > 0 ? (
        <div className="space-y-4">
          {table.queries.map((query) => (
            <QuerySection key={query.id} query={query} />
          ))}
        </div>
      ) : (
        <Card>
          <Text className="text-gray-500 text-center py-8">
            No queries have been run against this table yet.
          </Text>
        </Card>
      )}
    </div>
  );
}
