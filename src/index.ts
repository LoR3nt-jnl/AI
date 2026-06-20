import { loadConfig } from './config.js';
import { GoogleTasksClient } from './googleTasks.js';
import { ICloudRemindersClient } from './icloudReminders.js';
import { googleTaskToReminder, reminderToGoogleTask } from './syncRules.js';

async function main(): Promise<void> {
  const config = loadConfig();
  const google = new GoogleTasksClient(config.googleCredentialsPath, config.googleTokenPath);
  const reminders = new ICloudRemindersClient(config.icloudUsername, config.icloudAppPassword);

  const reminderLists = await reminders.getReminderLists();
  await syncGoogleToIcloud(config, google, reminders, reminderLists);
  await syncIcloudToGoogle(config, google, reminders);
}

async function syncGoogleToIcloud(
  config: ReturnType<typeof loadConfig>,
  google: GoogleTasksClient,
  reminders: ICloudRemindersClient,
  reminderLists: Awaited<ReturnType<ICloudRemindersClient['getReminderLists']>>,
): Promise<void> {
  const domesticTasks = await google.getTasksFromList(config.domesticGoogleListName);
  const personalTasks = await google.getTasksFromList(config.personalGoogleListName);
  const tasksToUpload = [
    ...domesticTasks.flatMap((task) => googleTaskToReminder(task, config.domesticGoogleListName, config.personalGoogleListName, config.taskPrefix) ?? []),
    ...personalTasks.flatMap((task) => googleTaskToReminder(task, config.personalGoogleListName, config.personalGoogleListName, config.taskPrefix) ?? []),
  ];

  console.log(`Google → iCloud: ${tasksToUpload.length} eligible task(s).`);
  for (const task of tasksToUpload) {
    const list = reminders.resolveList(reminderLists, task.requestedList, config.defaultReminderList, config.maxFuzzyDistance);
    if (await reminders.reminderExists(list, task.googleId)) {
      console.log(`Skip existing reminder: "${task.reminderTitle}" in "${list.title}"`);
      continue;
    }
    if (config.dryRun) {
      console.log(`[dry-run] Would create reminder: "${task.reminderTitle}" in "${list.title}"`);
      continue;
    }
    await reminders.createReminder(list, task);
    console.log(`Created reminder: "${task.reminderTitle}" in "${list.title}"`);
  }
}

async function syncIcloudToGoogle(
  config: ReturnType<typeof loadConfig>,
  google: GoogleTasksClient,
  reminders: ICloudRemindersClient,
): Promise<void> {
  const reminderTasks = await reminders.getAllReminders();
  const tasksToUpload = reminderTasks.flatMap((reminder) => reminderToGoogleTask(
    reminder,
    config.liveSessionListName,
    config.personalGoogleListName,
    config.domesticGoogleListName,
    config.taskPrefix,
  ) ?? []);

  console.log(`iCloud → Google: ${tasksToUpload.length} eligible reminder(s).`);
  for (const task of tasksToUpload) {
    if (await google.taskExistsFromReminder(task.targetGoogleList, task.reminderUid)) {
      console.log(`Skip existing Google task: "${task.title}" in "${task.targetGoogleList}"`);
      continue;
    }
    if (config.dryRun) {
      console.log(`[dry-run] Would create Google task: "${task.title}" in "${task.targetGoogleList}"`);
      continue;
    }
    await google.createTask(task.targetGoogleList, {
      title: task.title,
      notes: task.notes,
      due: task.due,
      reminderUid: task.reminderUid,
      reminderUrl: task.reminderUrl,
    });
    console.log(`Created Google task: "${task.title}" in "${task.targetGoogleList}"`);
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
