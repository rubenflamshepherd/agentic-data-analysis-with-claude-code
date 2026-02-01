import { Card, Text, List, ListItem } from '@tremor/react';

interface ExecutiveSummaryProps {
  findings: string[];
}

export function ExecutiveSummary({ findings }: ExecutiveSummaryProps) {
  // Parse markdown bold syntax
  const parseMarkdown = (text: string) => {
    const parts = text.split(/\*\*(.*?)\*\*/g);
    return parts.map((part, i) =>
      i % 2 === 1 ? (
        <strong key={i} className="font-semibold text-gray-900">
          {part}
        </strong>
      ) : (
        <span key={i}>{part}</span>
      )
    );
  };

  return (
    <section>
      <Text className="text-lg font-semibold text-gray-900 mb-4">
        Executive Summary
      </Text>
      <Card>
        <List>
          {findings.map((finding, index) => (
            <ListItem key={index}>
              <span className="text-gray-700">{parseMarkdown(finding)}</span>
            </ListItem>
          ))}
        </List>
      </Card>
    </section>
  );
}
