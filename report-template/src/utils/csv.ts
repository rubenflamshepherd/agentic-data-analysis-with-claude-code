/**
 * Parse a CSV line respecting quoted fields (handles commas inside quotes).
 */
function parseCSVLine(line: string): string[] {
  const values: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      // Check for escaped quote ("")
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++; // Skip the next quote
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      values.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }

  // Don't forget the last value
  values.push(current.trim());

  return values;
}

/**
 * Parse CSV text into an array of objects.
 * Each object represents a row with keys from the header row.
 * Handles quoted fields containing commas.
 */
export function parseCSV(csvText: string): Record<string, string | number>[] {
  const lines = csvText.trim().split('\n');

  if (lines.length < 2) {
    return [];
  }

  const headers = parseCSVLine(lines[0]);
  const rows: Record<string, string | number>[] = [];

  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;

    const values = parseCSVLine(line);
    const row: Record<string, string | number> = {};

    headers.forEach((header, index) => {
      const value = values[index]?.trim() ?? '';
      // Convert to number if it looks like one
      const num = Number(value);
      row[header] = !isNaN(num) && value !== '' ? num : value;
    });

    rows.push(row);
  }

  return rows;
}
