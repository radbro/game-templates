import test from 'node:test';
import assert from 'node:assert/strict';
import { LEVEL, STEP, createGame, startGame, togglePause, advance, snapshot } from '../game-model.mjs';

function running(level = LEVEL) { const game = createGame(level); startGame(game); return game; }
const clearLevel = { ...LEVEL, walls: [], hazards: [] };

test('start and pause protect the timer and player state', () => {
  const game = createGame();
  advance(game, { right: true }, 1000);
  assert.equal(game.player.x, LEVEL.spawn.x);
  startGame(game); advance(game, { right: true }, 1000);
  assert.ok(game.player.x > LEVEL.spawn.x);
  togglePause(game);
  const before = snapshot(game);
  advance(game, { up: true }, 120000);
  assert.deepEqual(snapshot(game), before);
  togglePause(game); advance(game, {}, 1000);
  assert.equal(game.mode, 'playing');
  assert.ok(game.remaining < before.remaining);
});

test('a long frame and short frames produce the same simulation', () => {
  const one = running(clearLevel); const many = running(clearLevel);
  advance(one, { right: true, up: true }, 1000, clearLevel);
  for (let i = 0; i < 60; i++) advance(many, { right: true, up: true }, 1000 / 60, clearLevel);
  assert.deepEqual(snapshot(one, clearLevel), snapshot(many, clearLevel));
  assert.ok(Math.abs(Math.hypot(one.player.x - LEVEL.spawn.x, one.player.y - LEVEL.spawn.y) - LEVEL.speed) < 1e-6);
});

test('walls stop motion without preventing movement along their edge', () => {
  const game = running();
  advance(game, { right: true }, 2000);
  assert.ok(game.player.x <= 302 - LEVEL.radius);
  assert.ok(game.player.x > 275);
  const x = game.player.x;
  advance(game, { down: true }, 200);
  assert.equal(game.player.x, x);
  assert.ok(game.player.y > LEVEL.spawn.y);
});

test('the level boundary stops long movement', () => {
  const game = running(clearLevel);
  advance(game, { left: true }, 10000, clearLevel);
  assert.ok(game.player.x >= LEVEL.radius + 32);
  assert.ok(game.player.x < 53);
});

test('a cell can be collected only once; return to the gate wins', () => {
  const level = { ...clearLevel, cells: [{ x: 220, y: 476 }] };
  const game = running(level);
  advance(game, { right: true }, 500, level);
  assert.equal(game.cells.filter(c => c.collected).length, 1);
  assert.equal(game.mode, 'playing');
  advance(game, { left: true }, 500, level);
  assert.equal(game.mode, 'won');
  const before = snapshot(game, level);
  advance(game, { right: true }, 1000, level);
  assert.deepEqual(snapshot(game, level), before);
});

test('a hazard removes one life and resets position with temporary immunity', () => {
  const level = { ...clearLevel, hazards: [{ x: 120, y: 476, travel: 0, speed: 0 }] };
  const game = running(level);
  advance(game, {}, STEP * 1000, level);
  assert.equal(game.lives, 2);
  assert.deepEqual(game.player, level.spawn);
  advance(game, {}, 1000, level);
  assert.equal(game.lives, 2);
  advance(game, {}, 2500, level);
  assert.equal(game.mode, 'lost');
  assert.equal(game.lives, 0);
});

test('hop protects against hazards; holding hop does not repeat it', () => {
  const level = { ...clearLevel, hazards: [{ x: 120, y: 476, travel: 0, speed: 0 }] };
  const game = running(level);
  advance(game, { hop: true }, 900, level);
  assert.equal(game.lives, 3);
  assert.ok(game.hop > 0);
  advance(game, { hop: true }, 200, level);
  assert.equal(game.lives, 2);
  advance(game, { hop: true }, 300, level);
  assert.equal(game.hop, 0);
  advance(game, {}, 20, level);
  advance(game, { hop: true }, 20, level);
  assert.ok(game.hop > 0);
});

test('timer loss freezes the run and a new game clears all old state', () => {
  const game = running(clearLevel);
  advance(game, {}, 91000, clearLevel);
  assert.equal(game.mode, 'lost');
  assert.equal(game.remaining, 0);
  const before = snapshot(game, clearLevel);
  advance(game, { right: true }, 2000, clearLevel);
  assert.deepEqual(snapshot(game, clearLevel), before);
  const fresh = createGame(clearLevel);
  assert.equal(fresh.mode, 'ready'); assert.equal(fresh.lives, 3);
  assert.equal(fresh.remaining, clearLevel.timeLimit);
  assert.ok(fresh.cells.every(c => !c.collected));
});

test('reject invalid time values', () => {
  for (const value of [-1, Infinity, NaN]) assert.throws(() => advance(running(), {}, value), RangeError);
});
