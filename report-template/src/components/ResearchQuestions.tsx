import {
  Card,
  Text,
  List,
  ListItem,
  Badge,
  Divider,
  Callout,
} from '@tremor/react';
import type { ResearchQuestion } from '../types';

interface ResearchQuestionsProps {
  questions: ResearchQuestion[];
}

export function ResearchQuestions({ questions }: ResearchQuestionsProps) {
  const getVerdictColor = (verdict?: string) => {
    switch (verdict) {
      case 'supported':
        return 'green';
      case 'inconclusive':
        return 'yellow';
      case 'not_supported':
        return 'red';
      default:
        return 'gray';
    }
  };

  const getVerdictLabel = (verdict?: string) => {
    switch (verdict) {
      case 'supported':
        return 'Evidence Supports';
      case 'inconclusive':
        return 'Inconclusive';
      case 'not_supported':
        return 'Not Supported';
      default:
        return 'Pending';
    }
  };

  return (
    <section className="space-y-6">
      <Text className="text-lg font-semibold text-gray-900">
        Research Questions
      </Text>

      {questions.map((q, index) => (
        <Card key={index}>
          <div className="flex items-start justify-between gap-4">
            <Text className="text-lg font-medium text-gray-900">
              {index + 1}. {q.question}
            </Text>
            <Badge color={getVerdictColor(q.verdict)} size="lg">
              {getVerdictLabel(q.verdict)}
            </Badge>
          </div>

          <Divider className="my-4" />

          <div className="space-y-4">
            <div>
              <Text className="font-medium text-gray-700 mb-2">
                Evidence Found
              </Text>
              <List>
                {q.findings.map((finding, i) => (
                  <ListItem key={i}>
                    <span className="text-gray-600">{finding}</span>
                  </ListItem>
                ))}
              </List>
            </div>

            {q.gaps.length > 0 && (
              <Callout title="Data Gaps" color="amber">
                <List>
                  {q.gaps.map((gap, i) => (
                    <ListItem key={i}>
                      <span className="text-amber-800">{gap}</span>
                    </ListItem>
                  ))}
                </List>
              </Callout>
            )}
          </div>
        </Card>
      ))}
    </section>
  );
}
