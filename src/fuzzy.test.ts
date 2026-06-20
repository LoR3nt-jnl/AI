import test from 'node:test';
import assert from 'node:assert/strict';
import { closestByTitle } from './fuzzy.js';

const lists = [{ title: 'Maison' }, { title: 'Travail' }, { title: 'Courses' }];

test('returns the closest list when distance is within threshold', () => {
  assert.equal(closestByTitle(lists, 'Maisn', 2)?.title, 'Maison');
});

test('returns undefined when the closest list is too far', () => {
  assert.equal(closestByTitle(lists, 'Vacances', 2), undefined);
});
