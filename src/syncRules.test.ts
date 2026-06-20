import test from 'node:test';
import assert from 'node:assert/strict';
import { googleTaskToReminder, reminderToGoogleTask } from './syncRules.js';

test('Google domestic tasks sync to iCloud without requiring iOS prefix', () => {
  const task = googleTaskToReminder({ id: 'g-1', title: 'acheter du pain - Maison' }, 'Tâches domestiques', 'Laurent.janolin', 'iOS');
  assert.equal(task?.reminderTitle, 'acheter du pain');
  assert.equal(task?.requestedList, 'Maison');
});

test('Google personal tasks sync to iCloud only when prefixed with iOS', () => {
  assert.equal(googleTaskToReminder({ id: 'g-2', title: 'appeler' }, 'Laurent.janolin', 'Laurent.janolin', 'iOS'), null);
  assert.equal(
    googleTaskToReminder({ id: 'g-3', title: 'iOS appeler' }, 'Laurent.janolin', 'Laurent.janolin', 'iOS')?.reminderTitle,
    'appeler',
  );
});

test('iCloud Live Session reminders go to Laurent.janolin with iOS prefix', () => {
  const task = reminderToGoogleTask({ uid: 'r-1', url: 'https://example.test/r-1.ics', listTitle: 'Live Session', title: 'préparer réunion', completed: false }, 'Live Session', 'Laurent.janolin', 'Tâches domestiques', 'iOS');
  assert.equal(task?.targetGoogleList, 'Laurent.janolin');
  assert.equal(task?.title, 'iOS préparer réunion');
});

test('other iCloud reminders go to Tâches domestiques and keep their source list', () => {
  const task = reminderToGoogleTask({ uid: 'r-2', url: 'https://example.test/r-2.ics', listTitle: 'Maison', title: 'lessive', completed: false }, 'Live Session', 'Laurent.janolin', 'Tâches domestiques', 'iOS');
  assert.equal(task?.targetGoogleList, 'Tâches domestiques');
  assert.equal(task?.title, 'lessive - Maison');
});
