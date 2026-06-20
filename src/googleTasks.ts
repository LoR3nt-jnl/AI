import { authenticate } from '@google-cloud/local-auth';
import { google, tasks_v1 } from 'googleapis';
import { readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';

const SCOPES = ['https://www.googleapis.com/auth/tasks.readonly'];

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

export async function getTasksFromList(listName: string, credentialsPath: string, tokenPath: string): Promise<GoogleTask[]> {
  const auth = await authorize(credentialsPath, tokenPath);
  const service = google.tasks({ version: 'v1', auth });
  const lists = await service.tasklists.list({ maxResults: 100 });
  const list = lists.data.items?.find((item) => item.title?.toLocaleLowerCase() === listName.toLocaleLowerCase());
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
