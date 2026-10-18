// Run with the existing Playwright runtime. No test-only state mutation is used.
import assert from 'node:assert/strict';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const base = process.env.GAME_URL || 'http://127.0.0.1:8784/templates/phaser-radbro-dungeon-crawler/';
const out = new URL('../../../evidence/dungeon-crawler/browser/', import.meta.url);
mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1280, height: 1000 } });
const errors = [];
page.on('pageerror', error => errors.push(error.message));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
const get = async target => JSON.parse(await target.evaluate(() => window.render_game_to_text()));
const step = (target, ms) => target.evaluate(ms => window.advanceTime(ms), ms);
const reset = async () => { await page.goto(base); await page.waitForFunction(() => window.advanceTime); await step(page, 0); await page.locator('#start').click(); };
async function replay(target, route) {
  let held = new Set();
  const names = { up: 'ArrowUp', down: 'ArrowDown', left: 'ArrowLeft', right: 'ArrowRight', attack: 'Space' };
  for (const action of route) {
    const next = new Set(Object.keys(action.input).filter(k => action.input[k]).map(k => names[k]));
    for (const key of held) if (!next.has(key)) await page.keyboard.up(key);
    for (const key of next) if (!held.has(key)) await page.keyboard.down(key);
    held = next; await step(target, action.ms);
  }
  for (const key of held) await page.keyboard.up(key);
}
await reset();
await page.keyboard.down('ArrowRight'); await step(page, 200); await page.keyboard.up('ArrowRight');
assert.equal((await get(page)).player.x, 148);
await page.keyboard.press('p'); const paused = await get(page); await step(page, 2000); assert.deepEqual(await get(page), paused);
await page.keyboard.press('p'); await page.keyboard.down('Space'); await step(page, 100); await page.keyboard.up('Space'); assert.ok((await get(page)).knives.length > 0);
await page.screenshot({ path: new URL('gameplay.png', out).pathname });
await reset();
await replay(page, JSON.parse(readFileSync(new URL('./win-route.json', import.meta.url))));
const win = await get(page); assert.equal(win.mode, 'won', JSON.stringify(win)); assert.equal(win.chests.filter(c => c.opened).length, 3); assert.equal(win.enemies.length, 0);
await page.screenshot({ path: new URL('win.png', out).pathname });
await page.keyboard.press('r'); assert.equal((await get(page)).health, 3); assert.equal((await get(page)).mode, 'playing');
await reset(); await replay(page, JSON.parse(readFileSync(new URL('./loss-route.json', import.meta.url))));
const loss = await get(page); assert.equal(loss.mode, 'lost'); assert.equal(loss.health, 0);
await page.screenshot({ path: new URL('loss.png', out).pathname });
// Test the real Chromium touch event path, including two simultaneous contacts.
const mobile = await browser.newContext({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true, deviceScaleFactor: 1 });
const touchPage = await mobile.newPage(); touchPage.on('pageerror', e => errors.push(e.message));
await touchPage.goto(base); await touchPage.waitForFunction(() => window.advanceTime); await step(touchPage, 0); await touchPage.locator('#start').tap();
const cd = await mobile.newCDPSession(touchPage);
const right = await touchPage.locator('[data-input="right"]').boundingBox(), attack = await touchPage.locator('[data-input="attack"]').boundingBox();
const point = (b, id) => ({ x: b.x + b.width / 2, y: b.y + b.height / 2, id });
await cd.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [point(right, 1), point(attack, 2)] });
await step(touchPage, 300); const touched = await get(touchPage); assert.ok(touched.player.x > 150); assert.ok(touched.knives.length > 0);
await cd.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
const released = await get(touchPage); await step(touchPage, 100); assert.equal((await get(touchPage)).player.x, released.player.x);
await touchPage.screenshot({ path: new URL('touch.png', out).pathname });
await page.goto(new URL('tests/sandbox.html', base).href); const frame = page.frames().find(f => f.url().endsWith('/index.html'));
assert.ok(frame); await frame.waitForFunction(() => window.advanceTime); await step(frame, 0); await frame.locator('#start').click();
await page.keyboard.down('ArrowRight'); await step(frame, 200); await page.keyboard.up('ArrowRight'); assert.equal((await get(frame)).player.x, 148);
const messages = await page.evaluate(() => window.gameMessages); assert.ok(messages.some(m => m.type === 'radbro:game-ready'));
assert.equal(await frame.evaluate(() => { try { return parent.document.body === null; } catch { return 'blocked'; } }), 'blocked');
await page.screenshot({ path: new URL('sandbox.png', out).pathname });
assert.deepEqual(errors, []);
writeFileSync(new URL('report.json', out), JSON.stringify({ result: 'pass', engine: 'Chromium', realKeyboard: true, realTouch: true, simultaneousTouch: true, restrictedIframe: true, win, loss, consoleErrors: errors, limits: ['No physical device check.', 'No Safari or Firefox check.', 'No live host check.'] }, null, 2));
await browser.close(); console.log('Browser proof passed: keyboard, throw, pause, restart, win, loss, real simultaneous touch, and opaque iframe.');
