import test from 'node:test';
import assert from 'node:assert/strict';
import { parseIosTask } from './parser.js';

test('parses an iOS-prefixed Google task with target list', () => {
  const parsed = parseIosTask({ id: 'g-1', title: 'iOS prendre rdv chez le coiffeur - Maison' }, 'iOS');
  assert.equal(parsed?.reminderTitle, 'prendre rdv chez le coiffeur');
  assert.equal(parsed?.requestedList, 'Maison');
});

test('keeps only iOS-prefixed tasks and falls back to default list when none is provided', () => {
  assert.equal(parseIosTask({ id: 'g-2', title: 'Android ignorer' }, 'iOS'), null);
  const parsed = parseIosTask({ id: 'g-3', title: 'iOS appeler le médecin' }, 'iOS');
  assert.equal(parsed?.reminderTitle, 'appeler le médecin');
  assert.equal(parsed?.requestedList, undefined);
});
