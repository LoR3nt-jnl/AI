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

export function parseIosTask(task: GoogleTask, prefix: string): ParsedTask | null {
  const title = task.title?.trim();
  if (!title || !task.id) return null;
  const prefixPattern = new RegExp(`^${escapeRegExp(prefix)}\\b`, 'i');
  if (!prefixPattern.test(title)) return null;

  const withoutPrefix = title.replace(prefixPattern, '').trim();
  const separator = withoutPrefix.lastIndexOf(' - ');
  const reminderTitle = (separator >= 0 ? withoutPrefix.slice(0, separator) : withoutPrefix).trim();
  const requestedList = separator >= 0 ? withoutPrefix.slice(separator + 3).trim() : undefined;
  if (!reminderTitle) return null;

  return {
    googleId: task.id,
    googleUrl: task.selfLink,
    originalTitle: title,
    reminderTitle,
    requestedList: requestedList || undefined,
    notes: task.notes,
    due: task.due,
  };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
