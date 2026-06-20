export function levenshtein(a: string, b: string): number {
  const left = a.toLocaleLowerCase();
  const right = b.toLocaleLowerCase();
  const costs = Array.from({ length: right.length + 1 }, (_, index) => index);
  for (let i = 1; i <= left.length; i += 1) {
    let previous = costs[0];
    costs[0] = i;
    for (let j = 1; j <= right.length; j += 1) {
      const temp = costs[j];
      costs[j] = left[i - 1] === right[j - 1]
        ? previous
        : Math.min(previous + 1, costs[j] + 1, costs[j - 1] + 1);
      previous = temp;
    }
  }
  return costs[right.length];
}

export function closestByTitle<T extends { title: string }>(items: T[], requested: string, maxDistance: number): T | undefined {
  let best: { item: T; distance: number } | undefined;
  for (const item of items) {
    const distance = levenshtein(item.title, requested);
    if (!best || distance < best.distance) best = { item, distance };
  }
  return best && best.distance <= maxDistance ? best.item : undefined;
}
