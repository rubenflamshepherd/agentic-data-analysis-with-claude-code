import html2canvas from 'html2canvas';

/**
 * Captures an HTML element and downloads it as a PNG image.
 * @param element - The DOM element to capture
 * @param filename - The filename for the downloaded image (without extension)
 */
export async function downloadChartAsImage(
  element: HTMLElement,
  filename: string
): Promise<void> {
  // Configure html2canvas
  const canvas = await html2canvas(element, {
    backgroundColor: '#ffffff',
    scale: 2, // Higher resolution for better text rendering
    logging: false,
    useCORS: true,
    onclone: (_clonedDoc, clonedElement) => {
      // Fix legend text clipping in html2canvas export
      // AGGRESSIVE APPROACH: Set overflow visible on all elements and add padding

      // Set overflow visible on ALL elements within the chart
      const allElements = clonedElement.querySelectorAll('*');
      allElements.forEach((elem) => {
        const el = elem as HTMLElement;
        if (el.style) {
          el.style.overflow = 'visible';
        }
      });

      // Find legend items (li elements containing svg circles and p text)
      const liElements = clonedElement.querySelectorAll('li');
      liElements.forEach((li) => {
        const el = li as HTMLElement;
        const hasSvg = el.querySelector('svg');
        const hasText = el.querySelector('p');
        if (hasSvg && hasText) {
          // This is a legend item - add bottom padding to prevent clipping
          el.style.paddingBottom = '4px';
          el.style.marginBottom = '2px';

          // Force line-height on the text
          const pEl = hasText as HTMLElement;
          pEl.style.lineHeight = '1.4';
          pEl.style.paddingBottom = '2px';
        }
      });

      // Find legend container (ol element) and add padding
      const olElements = clonedElement.querySelectorAll('ol');
      olElements.forEach((ol) => {
        const el = ol as HTMLElement;
        el.style.paddingBottom = '10px';
        el.style.marginBottom = '4px';
      });
    },
  });

  // Convert canvas to blob and trigger download
  canvas.toBlob((blob) => {
    if (!blob) {
      console.error('Failed to create image blob');
      return;
    }

    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `${sanitizeFilename(filename)}.png`;

    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    URL.revokeObjectURL(url);
  }, 'image/png');
}

/**
 * Sanitizes a string for use as a filename.
 */
function sanitizeFilename(name: string): string {
  return name
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_-]/g, '')
    .slice(0, 100);
}
