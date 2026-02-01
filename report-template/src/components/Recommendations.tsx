import {
  Card,
  Text,
  Badge,
  Flex,
} from '@tremor/react';
import type { Recommendation } from '../types';

interface RecommendationsProps {
  recommendations: Recommendation[];
}

export function Recommendations({ recommendations }: RecommendationsProps) {
  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high':
        return 'red';
      case 'medium':
        return 'yellow';
      case 'low':
        return 'gray';
      default:
        return 'gray';
    }
  };

  return (
    <section className="space-y-4">
      <Text className="text-lg font-semibold text-gray-900">
        Recommended Next Steps
      </Text>

      <div className="space-y-4">
        {recommendations.map((rec, index) => (
          <Card key={index} decoration="left" decorationColor={getPriorityColor(rec.priority)}>
            <Flex justifyContent="between" alignItems="start">
              <div className="flex gap-4">
                <div className="flex-shrink-0 w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center font-semibold text-sm">
                  {index + 1}
                </div>
                <div>
                  <Text className="font-semibold text-gray-900">
                    {rec.title}
                  </Text>
                  <Text className="mt-1 text-gray-600">
                    {rec.description}
                  </Text>
                  {rec.impact && (
                    <Text className="mt-2 text-sm text-gray-500">
                      Impact: {rec.impact}
                    </Text>
                  )}
                </div>
              </div>
              <Badge color={getPriorityColor(rec.priority)} size="sm">
                {rec.priority} priority
              </Badge>
            </Flex>
          </Card>
        ))}
      </div>
    </section>
  );
}
