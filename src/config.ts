export type SyncConfig = {
  googleTaskListName: string;
  taskPrefix: string;
  defaultReminderList: string;
  maxFuzzyDistance: number;
  dryRun: boolean;
  googleCredentialsPath: string;
  googleTokenPath: string;
  icloudUsername: string;
  icloudAppPassword: string;
};

function env(name: string, fallback?: string): string {
  const value = process.env[name];
  if (value === undefined || value.trim() === '') {
    if (fallback !== undefined) return fallback;
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function loadConfig(): SyncConfig {
  return {
    googleTaskListName: env('GOOGLE_TASK_LIST_NAME', 'live session'),
    taskPrefix: env('TASK_PREFIX', 'iOS'),
    defaultReminderList: env('ICLOUD_DEFAULT_REMINDER_LIST', 'Reminders'),
    maxFuzzyDistance: Number(env('FUZZY_LIST_MAX_DISTANCE', '3')),
    dryRun: env('DRY_RUN', 'false').toLowerCase() === 'true',
    googleCredentialsPath: env('GOOGLE_CREDENTIALS_PATH', 'credentials.json'),
    googleTokenPath: env('GOOGLE_TOKEN_PATH', 'token.json'),
    icloudUsername: env('ICLOUD_USERNAME'),
    icloudAppPassword: env('ICLOUD_APP_PASSWORD'),
  };
}
