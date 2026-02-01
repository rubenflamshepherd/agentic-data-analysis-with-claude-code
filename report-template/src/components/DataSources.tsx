import {
  Card,
  Text,
  Table,
  TableHead,
  TableRow,
  TableHeaderCell,
  TableBody,
  TableCell,
  Badge,
} from '@tremor/react';
import type { TableAnalysis } from '../types';

interface DataSourcesProps {
  sources: TableAnalysis[];
}

export function DataSources({ sources }: DataSourcesProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'complete':
        return 'green';
      case 'stale':
        return 'yellow';
      case 'failed':
        return 'red';
      default:
        return 'gray';
    }
  };

  const formatNumber = (num?: number) => {
    if (!num) return '-';
    return num.toLocaleString();
  };

  return (
    <section className="space-y-4">
      <Text className="text-lg font-semibold text-gray-900">
        Data Sources
      </Text>

      <Card>
        <Table>
          <TableHead>
            <TableRow>
              <TableHeaderCell>Table</TableHeaderCell>
              <TableHeaderCell>Status</TableHeaderCell>
              <TableHeaderCell>Description</TableHeaderCell>
              <TableHeaderCell className="text-right">Rows</TableHeaderCell>
              <TableHeaderCell>Date Range</TableHeaderCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {sources.map((source) => (
              <TableRow key={source.tableName}>
                <TableCell>
                  <Text className="font-mono text-sm">{source.tableName}</Text>
                </TableCell>
                <TableCell>
                  <Badge color={getStatusColor(source.status)} size="sm">
                    {source.status}
                  </Badge>
                </TableCell>
                <TableCell>
                  <Text className="text-gray-600">{source.description}</Text>
                </TableCell>
                <TableCell className="text-right">
                  <Text>{formatNumber(source.rowCount)}</Text>
                </TableCell>
                <TableCell>
                  <Text>{source.dateRange || '-'}</Text>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>
    </section>
  );
}
