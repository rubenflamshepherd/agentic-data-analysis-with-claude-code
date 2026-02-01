import {
  Card,
  Grid,
  Metric,
  Text,
  Flex,
  BadgeDelta,
} from '@tremor/react';
import type { KPIMetric } from '../types';

interface KPIDashboardProps {
  kpis: KPIMetric[];
}

export function KPIDashboard({ kpis }: KPIDashboardProps) {
  const getDeltaType = (trend?: 'up' | 'down' | 'neutral') => {
    switch (trend) {
      case 'up':
        return 'increase';
      case 'down':
        return 'decrease';
      default:
        return 'unchanged';
    }
  };

  return (
    <section>
      <Text className="text-lg font-semibold text-gray-900 mb-4">
        Key Metrics
      </Text>
      <Grid numItemsSm={2} numItemsLg={3} className="gap-4">
        {kpis.map((kpi, index) => (
          <Card key={index} decoration="top" decorationColor="blue">
            <Flex justifyContent="between" alignItems="center">
              <Text className="text-gray-600">{kpi.label}</Text>
              {kpi.trend && kpi.change !== undefined && (
                <BadgeDelta deltaType={getDeltaType(kpi.trend)} size="sm">
                  {kpi.change > 0 ? '+' : ''}{kpi.change}%
                </BadgeDelta>
              )}
            </Flex>
            <Metric className="mt-2">{kpi.value}</Metric>
            {kpi.changeLabel && (
              <Text className="mt-1 text-sm text-gray-500">
                {kpi.changeLabel}
              </Text>
            )}
          </Card>
        ))}
      </Grid>
    </section>
  );
}
