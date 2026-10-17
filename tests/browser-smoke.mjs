// Supply PLAYWRIGHT_MODULE with an installed Playwright index.mjs path.
// This keeps browser tools outside the template runtime dependencies.
import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const base = (process.env.SAMPLE_BASE_URL || 'http://127.0.0.1:8096/dist/site/').replace(/\/?$/, '/');
const evidence = process.env.EVIDENCE_DIR || 'evidence/browser';
await mkdir(evidence, { recursive: true });
const browser = await chromium.launch({ headless: true, ...(process.env.BROWSER_CHANNEL ? { channel: process.env.BROWSER_CHANNEL } : {}) });
const results = [];
const errors = [];
function monitor(page) {
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  page.on('response', response => { if (response.status() >= 400) errors.push(`${response.status()} ${response.url()}`); });
}
async function state(page) { return page.evaluate(() => JSON.parse(window.render_game_to_text())); }
async function ready(page, path) {
  monitor(page);
  await page.addInitScript(() => {
    window.__sampleMessages = [];
    window.addEventListener('message', event => {
      if (event.data?.type?.startsWith('radbro:')) window.__sampleMessages.push(event.data);
    });
  });
  await page.goto(base + path, { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function', null, { timeout: 90000 });
  await page.waitForFunction(() => window.__sampleMessages.some(m => m.type === 'radbro:game-ready'));
}
async function pressFor(page, key, ms, fixed = false) {
  await page.keyboard.down(key);
  if (fixed) await page.evaluate(ms => window.advanceTime(ms), ms);
  else await page.waitForTimeout(ms);
  await page.keyboard.up(key);
}
async function touchHold(page, selector, ms, fixed, secondSelector) {
  const client = await page.context().newCDPSession(page);
  const point = async (selector, id) => {
    const box = await page.locator(selector).boundingBox();
    assert(box, `Missing touch control ${selector}`);
    return { x: box.x + box.width / 2, y: box.y + box.height / 2, id };
  };
  const points = [await point(selector, 1)];
  await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: points });
  if (secondSelector) {
    points.push(await point(secondSelector, 2));
    await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: points });
  }
  if (fixed) await page.evaluate(ms => window.advanceTime(ms), ms);
  else await page.waitForTimeout(ms);
  await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await client.detach();
}
async function phaser() {
  const context = await browser.newContext({ viewport: { width: 1100, height: 900 } });
  const page = await context.newPage();
  await ready(page, 'phaser-radcat-courier/');
  assert.equal((await state(page)).mode, 'ready');
  await page.keyboard.press('KeyF');
  await page.waitForFunction(() => document.fullscreenElement !== null);
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => document.fullscreenElement === null);
  await page.locator('#start').click();
  await page.evaluate(() => window.advanceTime(0));
  async function move(x, y, hop = false) {
    if (hop) await page.keyboard.down('Space');
    for (const [axis, target, plus, minus] of [['x', x, 'ArrowRight', 'ArrowLeft'], ['y', y, 'ArrowDown', 'ArrowUp']]) {
      const before = await state(page);
      const distance = target - before.player[axis];
      if (Math.abs(distance) > 2) await pressFor(page, distance > 0 ? plus : minus, Math.round(Math.abs(distance) / 230 * 60) * 1000 / 60, true);
      const after = await state(page);
      if (after.mode === 'won') return;
      assert(Math.abs(after.player[axis] - target) < 7, `Route blocked at ${axis}=${target}: ${JSON.stringify(after.player)}`);
    }
    if (hop) await page.keyboard.up('Space');
  }
  await move(208, 166);
  assert.equal((await state(page)).collected, 1);
  await page.locator('#pause').click();
  const paused = await state(page);
  await pressFor(page, 'ArrowRight', 1000, true);
  assert.deepEqual(await state(page), paused);
  await page.locator('#pause').click();
  await move(440, 146);
  await move(510, 180);
  await move(510, 390, true);
  await move(464, 440);
  await move(660, 390);
  await move(660, 170, true);
  await move(766, 170);
  await move(880, 170);
  await move(880, 354);
  await move(826, 354, true);
  assert.equal((await state(page)).collected, 5);
  await page.screenshot({ path: `${evidence}/phaser-collected.png` });
  await move(880, 354);
  await move(880, 550);
  await move(440, 550);
  await move(208, 550);
  await move(120, 476);
  assert.equal((await state(page)).mode, 'won');
  const won = await state(page);
  await page.waitForFunction(() => window.__sampleMessages.some(m => m.status === 'clear'));
  await pressFor(page, 'ArrowRight', 1000, true);
  assert.deepEqual(await state(page), won);
  assert.equal(await page.evaluate(() => window.__sampleMessages.filter(m => m.type === 'radbro:game-result').length), 1);
  await page.screenshot({ path: `${evidence}/phaser-won.png` });
  await page.locator('#restart').click();
  assert.equal((await state(page)).collected, 0);
  await page.evaluate(() => window.advanceTime(91000));
  assert.equal((await state(page)).mode, 'lost');
  await page.waitForFunction(() => window.__sampleMessages.some(m => m.status === 'gameover'));
  assert.equal(await page.evaluate(() => window.__sampleMessages.filter(m => m.type === 'radbro:game-result').length), 2);
  await page.screenshot({ path: `${evidence}/phaser-lost.png` });
  results.push('Phaser: complete keyboard route, pickups, win, frozen terminal state, pause, restart, timeout.');
  await context.close();

  const mobile = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true, deviceScaleFactor: 1 });
  const touch = await mobile.newPage();
  await ready(touch, 'phaser-radcat-courier/');
  await touch.locator('#start').tap();
  await touch.evaluate(() => window.advanceTime(0));
  const start = await state(touch);
  await touchHold(touch, '[data-input="right"]', 250, true, '[data-input="hop"]');
  const moved = await state(touch);
  assert(moved.player.x > start.player.x + 20);
  assert(moved.player.hop > 0);
  await touch.screenshot({ path: `${evidence}/phaser-touch.png` });
  await touch.locator('#pause').tap();
  assert.equal((await state(touch)).mode, 'paused');
  results.push('Phaser: real touchscreen start/pause; simultaneous touch movement and hop at 390px.');
  await mobile.close();
}
async function sandbox(engine) {
  const page = await browser.newPage({ viewport: { width: 1000, height: 800 } });
  monitor(page);
  await page.goto(base, { waitUntil: 'networkidle' });
  await page.setContent(`<script>window.__embedMessages = []; window.addEventListener("message", e => { if (e.data?.type === "radbro:game-ready") window.__embedMessages.push(e.data); });</script><iframe title="sample" sandbox="allow-scripts allow-pointer-lock" src="${base}${engine}/" style="width:960px;height:740px;border:0"></iframe>`);
  const frame = await (await page.$('iframe')).contentFrame();
  await frame.waitForFunction(() => typeof window.render_game_to_text === 'function', null, { timeout: 90000 });
  assert.equal(await frame.evaluate(() => window.origin), 'null');
  await page.waitForFunction(() => window.__embedMessages.length > 0);
  const count = await page.evaluate(() => window.__embedMessages.length);
  await page.evaluate(() => document.querySelector('iframe').contentWindow.postMessage({ type: 'radbro:game-ready-request' }, '*'));
  await page.waitForFunction(count => window.__embedMessages.length > count, count);
  const s = await state(frame);
  assert(['ready', 'playing'].includes(s.mode || s.state));
  await page.screenshot({ path: `${evidence}/${engine}-sandbox.png` });
  results.push(`${engine}: loaded inside allow-scripts allow-pointer-lock sandbox with opaque origin.`);
  await page.close();
}
async function godot() {
  const context = await browser.newContext({ viewport: { width: 960, height: 720 } });
  const page = await context.newPage();
  await ready(page, 'godot-radcat-relay/');
  await page.screenshot({ path: `${evidence}/godot-ready.png` });
  assert.equal((await state(page)).state, 'ready');
  // The editor HUD uses a 960x600 viewport with stretch to fit.
  await page.mouse.click(80, 158);
  await page.waitForTimeout(200);
  assert.equal((await state(page)).state, 'playing');
  async function move(x, z) {
    for (const [axis, target, plus, minus] of [['x', x, 'ArrowRight', 'ArrowLeft'], ['z', z, 'ArrowDown', 'ArrowUp']]) {
      for (let step = 0; step < 80; step++) {
        const s = await state(page);
        assert.equal(s.state, 'playing', JSON.stringify(s));
        const distance = target - s.player[axis];
        if (Math.abs(distance) < 0.28) break;
        await pressFor(page, distance > 0 ? plus : minus, Math.max(25, Math.min(350, Math.abs(distance) / 5.5 * 1000)));
        if (step === 79) assert.fail(`Godot route blocked at ${axis}=${target}`);
      }
    }
  }
  await move(-5, 8);
  await move(-5, 5);
  assert.equal((await state(page)).collected, 1);
  await pressFor(page, 'KeyP', 80);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).state === 'paused');
  const paused = await state(page);
  await pressFor(page, 'ArrowRight', 300);
  const after = await state(page);
  assert.equal(after.state, 'paused'); assert.equal(after.time_left, paused.time_left); assert.equal(after.player.x, paused.player.x);
  await pressFor(page, 'KeyP', 80);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).state === 'playing');
  await move(-7, 5);
  await move(-7, -6);
  await move(-4, -6);
  await move(-4, -9.5);
  await move(4, -9.5);
  await move(4, -8);
  await move(6, -8);
  await move(6, 0);
  await move(5, 0);
  assert.equal((await state(page)).collected, 4);
  await page.screenshot({ path: `${evidence}/godot-collected.png` });
  await page.keyboard.press('Space');
  await page.waitForTimeout(80);
  assert.equal((await state(page)).player.hopping, true);
  await move(6, 0);
  await move(6, 8);
  // Stop when the visible gate contact ends the run.
  await pressFor(page, 'ArrowLeft', 1150);
  assert.equal((await state(page)).state, 'won');
  await page.waitForFunction(() => window.__sampleMessages.some(m => m.status === 'clear'));
  const won = await state(page);
  await pressFor(page, 'ArrowRight', 200);
  assert.equal((await state(page)).player.x, won.player.x);
  await page.screenshot({ path: `${evidence}/godot-won.png` });
  await pressFor(page, 'KeyR', 80);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).state === 'playing' && JSON.parse(window.render_game_to_text()).collected === 0);
  assert.equal((await state(page)).collected, 0);
  await move(-5, 8);
  await move(-5, 0);
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).state === 'lost', null, { timeout: 30000 });
  await page.waitForFunction(() => window.__sampleMessages.some(m => m.status === 'gameover'));
  assert.equal(await page.evaluate(() => window.__sampleMessages.filter(m => m.type === 'radbro:game-result').length), 2);
  await page.screenshot({ path: `${evidence}/godot-lost.png` });
  results.push('Godot: complete keyboard route, four pickups, pause, hop, gate win, frozen terminal movement, restart, hazard loss, result messages.');
  await context.close();
  const mobile = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  const touch = await mobile.newPage();
  await ready(touch, 'godot-radcat-relay/');
  await touch.touchscreen.tap(80, 155);
  await touch.waitForFunction(() => JSON.parse(window.render_game_to_text()).state === 'playing');
  const before = await state(touch);
  const client = await mobile.newCDPSession(touch);
  await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 282, y: 784, id: 1 }] });
  await touch.waitForTimeout(200);
  await client.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 282, y: 784, id: 1 }, { x: 280, y: 714, id: 2 }] });
  await touch.waitForTimeout(100);
  const afterTouch = await state(touch);
  assert(afterTouch.player.x > before.player.x + 0.5);
  assert(afterTouch.player.hopping);
  await client.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await touch.screenshot({ path: `${evidence}/godot-touch.png` });
  await touch.touchscreen.tap(78, 155);
  await touch.waitForFunction(() => JSON.parse(window.render_game_to_text()).state === 'paused');
  results.push('Godot: portrait HUD, real touch start/pause, simultaneous native touch movement and hop at 390px.');
  await mobile.close();
}
try {
  const engines = (process.env.ENGINES || 'phaser,godot').split(',');
  if (engines.includes('phaser')) { await phaser(); await sandbox('phaser-radcat-courier'); }
  if (engines.includes('godot')) { await godot(); await sandbox('godot-radcat-relay'); }
  assert.deepEqual(errors, [], 'Browser errors');
  console.log(results.join('\n'));
  await writeFile(`${evidence}/results.json`, JSON.stringify({ base, results, errors }, null, 2));
} finally { await browser.close(); }
