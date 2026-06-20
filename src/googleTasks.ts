import { authenticate } from '@google-cloud/local-auth';
import { google, tasks_v1 } from 'googleapis';
import { readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';

const SCOPES = ['https://www.googleapis.com/auth/tasks'];
const MARKER_PREFIX = 'ICLOUD_REMINDER_UID:';

async function authorize(credentialsPath: string, tokenPath: string) {
  if (existsSync(tokenPath)) {
    const raw = JSON.parse(await readFile(tokenPath, 'utf8'));
    const auth = new google.auth.OAuth2(raw.client_id, raw.client_secret, raw.redirect_uri);
    auth.setCredentials(raw.credentials);
    return auth;
  }

  const auth = await authenticate({ scopes: SCOPES, keyfilePath: credentialsPath });
  const credentials = JSON.parse(await readFile(credentialsPath, 'utf8'));
  const installed = credentials.installed ?? credentials.web;
  await writeFile(
    tokenPath,
    JSON.stringify({
      client_id: installed.client_id,
      client_secret: installed.client_secret,
      redirect_uri: installed.redirect_uris?.[0] ?? 'http://localhost',
      credentials: auth.credentials,
    }, null, 2),
    { mode: 0o600 },
  );
  return auth;
}

export type GoogleTask = tasks_v1.Schema$Task;
export type GoogleTaskList = { id: string; title: string };
export type GoogleTaskCreateInput = { title: string; notes?: string; due?: string };

export class GoogleTasksClient {
  private service?: tasks_v1.Tasks;

  constructor(private readonly credentialsPath: string, private readonly tokenPath: string) {}

  async getTasksFromList(listName: string): Promise<GoogleTask[]> {
    const service = await this.getService();
    const list = await this.findList(listName);
    if (!list?.id) throw new Error(`Google Tasks list not found: ${listName}`);

    const tasks: GoogleTask[] = [];
    let pageToken: string | undefined;
    do {
      const response = await service.tasks.list({
        tasklist: list.id,
        showCompleted: false,
        showDeleted: false,
        showHidden: false,
        maxResults: 100,
        pageToken,
      });
      tasks.push(...(response.data.items ?? []));
      pageToken = response.data.nextPageToken ?? undefined;
    } while (pageToken);

    return tasks;
  }

  async taskExistsFromReminder(listName: string, reminderUid: string): Promise<boolean> {
    const tasks = await this.getTasksFromList(listName);
    return tasks.some((task) => task.notes?.includes(`${MARKER_PREFIX}${reminderUid}`));
  }

  async createTask(listName: string, input: GoogleTaskCreateInput & { reminderUid?: string; reminderUrl?: string }): Promise<void> {
    const service = await this.getService();
    const list = await this.findList(listName);
    if (!list?.id) throw new Error(`Google Tasks list not found: ${listName}`);
    const notes = [input.notes, input.reminderUid ? `${MARKER_PREFIX}${input.reminderUid}` : undefined, input.reminderUrl]
      .filter(Boolean)
      .join('\n');
    await service.tasks.insert({
      tasklist: list.id,
      requestBody: {
        title: input.title,
        notes: notes || undefined,
        due: input.due,
      },
    });
  }

  private async findList(listName: string): Promise<GoogleTaskList | undefined> {
    const service = await this.getService();
    const lists = await service.tasklists.list({ maxResults: 100 });
    const list = lists.data.items?.find((item) => item.title?.toLocaleLowerCase() === listName.toLocaleLowerCase());
    return list?.id && list.title ? { id: list.id, title: list.title } : undefined;
  }

  private async getService(): Promise<tasks_v1.Tasks> {
    if (!this.service) {
      const auth = await authorize(this.credentialsPath, this.tokenPath);
      this.service = google.tasks({ version: 'v1', auth });
    }
    return this.service;
  }
}

export async function getTasksFromList(listName: string, credentialsPath: string, tokenPath: string): Promise<GoogleTask[]> {
  return new GoogleTasksClient(credentialsPath, tokenPath).getTasksFromList(listName);
}
