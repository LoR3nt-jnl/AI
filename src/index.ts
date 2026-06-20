import { loadConfig } from './config.js';
import { getTasksFromList } from './googleTasks.js';
import { ICloudRemindersClient } from './icloudReminders.js';
import { parseIosTask } from './parser.js';

async function main(): Promise<void> {
  const config = loadConfig();
  const googleTasks = await getTasksFromList(config.googleTaskListName, config.googleCredentialsPath, config.googleTokenPath);
  const iosTasks = googleTasks.flatMap((task) => {
    const parsed = parseIosTask(task, config.taskPrefix);
    return parsed ? [parsed] : [];
  });

  console.log(`Google Tasks list "${config.googleTaskListName}": ${googleTasks.length} active task(s), ${iosTasks.length} iOS task(s) to sync.`);

  const reminders = new ICloudRemindersClient(config.icloudUsername, config.icloudAppPassword);
  const lists = await reminders.getReminderLists();

  for (const task of iosTasks) {
    const list = reminders.resolveList(lists, task.requestedList, config.defaultReminderList, config.maxFuzzyDistance);
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

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
