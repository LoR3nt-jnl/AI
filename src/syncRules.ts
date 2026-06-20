import type { GoogleTask } from './googleTasks.js';
import type { ReminderItem } from './icloudReminders.js';
import { parseTaskTitle } from './parser.js';

export type GoogleToIcloudTask = {
  googleId: string;
  googleUrl?: string | null;
  originalTitle: string;
  reminderTitle: string;
  requestedList?: string;
  notes?: string | null;
  due?: string | null;
  sourceGoogleList: string;
};

export type IcloudToGoogleTask = {
  reminderUid: string;
  reminderUrl: string;
  sourceReminderList: string;
  targetGoogleList: string;
  title: string;
  notes?: string;
  due?: string;
};

export function googleTaskToReminder(task: GoogleTask, sourceList: string, personalListName: string, prefix: string): GoogleToIcloudTask | null {
  if (!task.id || !task.title) return null;
  const mustHavePrefix = sourceList.toLocaleLowerCase() === personalListName.toLocaleLowerCase();
  const parsed = parseTaskTitle(task.title, { prefix: mustHavePrefix ? prefix : undefined });
  if (!parsed) return null;
  return {
    googleId: task.id,
    googleUrl: task.selfLink,
    originalTitle: task.title,
    reminderTitle: parsed.title,
    requestedList: parsed.requestedList,
    notes: task.notes,
    due: task.due,
    sourceGoogleList: sourceList,
  };
}

export function reminderToGoogleTask(reminder: ReminderItem, liveSessionListName: string, personalListName: string, domesticListName: string, prefix: string): IcloudToGoogleTask | null {
  if (reminder.completed) return null;
  const fromLiveSession = reminder.listTitle.toLocaleLowerCase() === liveSessionListName.toLocaleLowerCase();
  const targetGoogleList = fromLiveSession ? personalListName : domesticListName;
  const baseTitle = fromLiveSession ? `${prefix} ${reminder.title}` : `${reminder.title} - ${reminder.listTitle}`;
  return {
    reminderUid: reminder.uid,
    reminderUrl: reminder.url,
    sourceReminderList: reminder.listTitle,
    targetGoogleList,
    title: baseTitle,
    notes: reminder.notes,
    due: reminder.due,
  };
}
