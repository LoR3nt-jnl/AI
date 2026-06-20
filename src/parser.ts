import type { GoogleTask } from './googleTasks.js';

export type ParsedTask = {
  googleId: string;
  googleUrl?: string | null;
  originalTitle: string;
  reminderTitle: string;
  requestedList?: string;
  notes?: string | null;
  due?: string | null;
};

export type ParsedTitle = {
  title: string;
  requestedList?: string;
};

export function parseTaskTitle(rawTitle: string, options: { prefix?: string } = {}): ParsedTitle | null {
  const title = rawTitle.trim();
  if (!title) return null;

  let withoutPrefix = title;
  if (options.prefix) {
    const prefixPattern = new RegExp(`^${escapeRegExp(options.prefix)}\\b`, 'i');
    if (!prefixPattern.test(title)) return null;
    withoutPrefix = title.replace(prefixPattern, '').trim();
  }

  const separator = withoutPrefix.lastIndexOf(' - ');
  const reminderTitle = (separator >= 0 ? withoutPrefix.slice(0, separator) : withoutPrefix).trim();
  const requestedList = separator >= 0 ? withoutPrefix.slice(separator + 3).trim() : undefined;
  if (!reminderTitle) return null;
  return { title: reminderTitle, requestedList: requestedList || undefined };
}

export function parseIosTask(task: GoogleTask, prefix: string): ParsedTask | null {
  const title = task.title?.trim();
  if (!title || !task.id) return null;
  const parsed = parseTaskTitle(title, { prefix });
  if (!parsed) return null;

  return {
    googleId: task.id,
    googleUrl: task.selfLink,
    originalTitle: title,
    reminderTitle: parsed.title,
    requestedList: parsed.requestedList,
    notes: task.notes,
    due: task.due,
  };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
