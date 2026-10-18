import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { makeLevel, createGame, startGame, togglePause, advance, attack, isOpen, RULES } from '../game-model.mjs';
const map = JSON.parse(readFileSync(new URL('../upstream/art/tiles/dungeon-01.json', import.meta.url)));
const level = makeLevel(map);
const game = () => { const state = createGame(level); startGame(state); return state; };

test('uses original map objects and walls', () => {
  assert.equal(level.chests.length, 3); assert.equal(level.enemies.length, 4);
  assert.equal(isOpen(level, 128, 128), true); assert.equal(isOpen(level, 0, 0), false);
  const state = game(); advance(state, { left: true }, 3000);
  assert.ok(state.player.x >= 22 && state.player.x < 24); assert.equal(state.player.y, 128);
});
test('keeps cardinal movement and last aim direction', () => {
  const state = game(); advance(state, { right: true, up: true }, 500);
  assert.ok(Math.abs(state.player.x - 178) < .01); assert.equal(state.player.y, 128);
  assert.deepEqual(state.facing, { x: 1, y: 0 });
});
test('pause freezes all gameplay and preserves input for caller to clear', () => {
  const state = game(); togglePause(state); const before = JSON.stringify({ ...state, accumulator: 0 });
  advance(state, { right: true, attack: true }, 1000);
  assert.equal(JSON.stringify({ ...state, accumulator: 0 }), before); togglePause(state); assert.equal(state.mode, 'playing');
});
test('opens a nearby chest once and gives seeded coin reward', () => {
  const state = game(); state.player = { x: level.chests[0].x, y: level.chests[0].y + 20 };
  attack(state); assert.equal(state.chests[0].opened, true); assert.ok(state.coins >= 50 && state.coins <= 200);
  const coins = state.coins; advance(state, { attack: true }, 700); assert.equal(state.coins, coins);
});
test('knife pool is limited, kills enemies, and recycles at walls', () => {
  const state = game(); state.enemies.forEach(e => { e.alive = false; });
  state.enemies[0] = { id: 0, x: 180, y: 128, alive: true, direction: 3, turnIn: 2 };
  attack(state); advance(state, {}, 300); assert.equal(state.enemies[0].alive, false); assert.equal(state.knives.length, 0);
  state.facing = { x: -1, y: 0 }; advance(state, { attack: true }, 2000);
  assert.ok(state.knives.length <= RULES.maxKnives);
  advance(state, {}, 2000); assert.equal(state.knives.length, 0);
});
test('damage grants a grace period and three hits end the game', () => {
  const state = game(); state.enemies = [{ id: 0, x: 128, y: 128, alive: true, direction: 0, turnIn: 10 }];
  advance(state, {}, 10); assert.equal(state.health, 2);
  advance(state, {}, 50); assert.equal(state.health, 2);
  for (let i = 0; i < 2; i++) { state.immune = 0; state.knockback.time = 0; state.enemies[0].x = state.player.x; state.enemies[0].y = state.player.y; advance(state, {}, 10); }
  assert.equal(state.health, 0); assert.equal(state.mode, 'lost');
});
test('exit requires every chest and enemy then ends the round', () => {
  const state = game(); advance(state, {}, 20); assert.equal(state.mode, 'playing');
  state.chests.forEach(c => { c.opened = true; }); state.enemies.forEach(e => { e.alive = false; });
  advance(state, {}, 20); assert.equal(state.mode, 'won');
});
test('fixed simulation gives the same result for different frame sizes', () => {
  const a = game(), b = game(); advance(a, { right: true, attack: true }, 1000);
  for (let i = 0; i < 60; i++) advance(b, { right: true, attack: true }, 1000 / 60);
  for (const key of ['player', 'enemies', 'knives', 'health']) assert.deepEqual(a[key], b[key]);
});
