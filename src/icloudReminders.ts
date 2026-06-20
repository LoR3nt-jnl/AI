import { Base64 } from 'js-base64';
import { closestByTitle } from './fuzzy.js';
import type { ParsedTask } from './parser.js';

export type ReminderList = { title: string; url: string };

const ICLOUD_ROOT = 'https://caldav.icloud.com';
const MARKER_PREFIX = 'GOOGLE_TASK_ID:';

export class ICloudRemindersClient {
  constructor(private readonly username: string, private readonly appPassword: string) {}

  async getReminderLists(): Promise<ReminderList[]> {
    const principal = await this.currentUserPrincipal();
    const homeSet = await this.calendarHomeSet(principal);
    return this.listCalendars(homeSet);
  }

  resolveList(lists: ReminderList[], requested: string | undefined, defaultTitle: string, maxDistance: number): ReminderList {
    const fallback = lists.find((list) => equals(list.title, defaultTitle)) ?? lists[0];
    if (!fallback) throw new Error('No iCloud Reminders lists found');
    if (!requested) return fallback;
    return lists.find((list) => equals(list.title, requested))
      ?? closestByTitle(lists, requested, maxDistance)
      ?? fallback;
  }

  async reminderExists(list: ReminderList, googleTaskId: string): Promise<boolean> {
    const response = await this.request(list.url, 'REPORT', `<?xml version="1.0" encoding="utf-8" ?>
<C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
  <D:prop><D:getetag/><C:calendar-data/></D:prop>
  <C:filter><C:comp-filter name="VCALENDAR"><C:comp-filter name="VTODO"/></C:comp-filter></C:filter>
</C:calendar-query>`, { Depth: '1' });
    const body = await response.text();
    return body.includes(`${MARKER_PREFIX}${googleTaskId}`);
  }

  async createReminder(list: ReminderList, task: ParsedTask): Promise<void> {
    const id = crypto.randomUUID();
    const now = formatIcsDate(new Date());
    const dueLine = task.due ? `DUE;VALUE=DATE:${task.due.slice(0, 10).replaceAll('-', '')}\r\n` : '';
    const description = [task.notes, `${MARKER_PREFIX}${task.googleId}`, task.googleUrl].filter(Boolean).join('\n');
    const ics = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//AI//Google Tasks iCloud Reminders Sync//FR',
      'BEGIN:VTODO',
      `UID:${id}`,
      `DTSTAMP:${now}`,
      `CREATED:${now}`,
      `SUMMARY:${escapeIcs(task.reminderTitle)}`,
      dueLine.trimEnd(),
      `DESCRIPTION:${escapeIcs(description)}`,
      'STATUS:NEEDS-ACTION',
      'END:VTODO',
      'END:VCALENDAR',
      '',
    ].filter((line) => line !== '').join('\r\n');
    await this.request(new URL(`${id}.ics`, ensureSlash(list.url)).toString(), 'PUT', ics, { 'Content-Type': 'text/calendar; charset=utf-8' });
  }

  private async currentUserPrincipal(): Promise<string> {
    const xml = await this.propfind(`${ICLOUD_ROOT}/`, '<D:current-user-principal/>', '0');
    return absolute(readHref(xml));
  }

  private async calendarHomeSet(principal: string): Promise<string> {
    const xml = await this.propfind(principal, '<C:calendar-home-set/>', '0');
    return absolute(readHref(xml));
  }

  private async listCalendars(homeSet: string): Promise<ReminderList[]> {
    const xml = await this.propfind(homeSet, '<D:displayname/><D:resourcetype/>', '1');
    const responses = xml.split(/<[^:>]*:?response[\s>]/).slice(1);
    return responses.flatMap((response) => {
      if (!response.includes('VTODO')) return [];
      const href = readHref(response);
      const title = readTag(response, 'displayname');
      return href && title ? [{ title, url: absolute(href) }] : [];
    });
  }

  private async propfind(url: string, props: string, depth: string): Promise<string> {
    const response = await this.request(url, 'PROPFIND', `<?xml version="1.0" encoding="utf-8" ?><D:propfind xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav"><D:prop>${props}</D:prop></D:propfind>`, { Depth: depth });
    return response.text();
  }

  private async request(url: string, method: string, body?: string, headers: Record<string, string> = {}): Promise<Response> {
    const response = await fetch(url, {
      method,
      headers: { Authorization: `Basic ${Base64.encode(`${this.username}:${this.appPassword}`)}`, ...headers },
      body,
    });
    if (!response.ok && response.status !== 207 && response.status !== 201 && response.status !== 204) {
      throw new Error(`${method} ${url} failed: ${response.status} ${await response.text()}`);
    }
    return response;
  }
}

function readHref(xml: string): string {
  return readTag(xml, 'href');
}

function readTag(xml: string, localName: string): string {
  const match = xml.match(new RegExp(`<[^:>]*:?${localName}[^>]*>([^<]+)</[^>]+>`));
  return decodeXml(match?.[1]?.trim() ?? '');
}

function absolute(href: string): string {
  return href.startsWith('http') ? href : new URL(href, ICLOUD_ROOT).toString();
}

function ensureSlash(url: string): string {
  return url.endsWith('/') ? url : `${url}/`;
}

function equals(a: string, b: string): boolean {
  return a.toLocaleLowerCase() === b.toLocaleLowerCase();
}

function formatIcsDate(date: Date): string {
  return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
}

function escapeIcs(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n/g, '\\n');
}

function decodeXml(value: string): string {
  return value.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'");
}
