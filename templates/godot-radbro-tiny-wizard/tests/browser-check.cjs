/* Use an existing Playwright installation. This project adds no npm dependency. */
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const base = process.env.GAME_URL || 'http://127.0.0.1:8782';
const evidence = process.env.EVIDENCE_DIR || 'evidence/tiny-wizard';
fs.mkdirSync(evidence, { recursive: true });

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({ viewport: { width: 1024, height: 800 }, hasTouch: true });
  const page = await context.newPage();
  const errors = [];
  page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
  page.on('pageerror', error => errors.push(error.message));
  const state = () => page.evaluate(() => window.radbroState);
  const record = {};
  await page.goto(base);
  await page.waitForFunction(() => window.radbroState?.targets?.length === 3);
  record.initial = await state();
  await page.screenshot({ path: `${evidence}/initial.png` });
  await page.keyboard.down('d');
  await page.waitForTimeout(350);
  await page.keyboard.up('d');
  record.moved = await state();
  assert(record.moved.position[0] > record.initial.position[0] + 50);
  await page.keyboard.press('p');
  await page.waitForFunction(() => window.radbroState.phase === 'paused');
  await page.screenshot({ path: `${evidence}/paused.png` });
  const pausedAt = (await state()).seconds;
  await page.waitForTimeout(200);
  assert.equal((await state()).seconds, pausedAt);
  await page.keyboard.press('p');
  await page.waitForFunction(() => window.radbroState.phase === 'playing');
  await page.keyboard.press('r');
  await page.waitForFunction(() => window.radbroState.seconds < 0.5 && window.radbroState.position[0] === 512);
  const cdp = await context.newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ id: 1, x: 240, y: 705 }, { id: 2, x: 850, y: 635 }] });
  await page.waitForTimeout(350);
  record.touchDuring = await state();
  assert.equal(record.touchDuring.touches, 2);
  assert(record.touchDuring.position[0] > 560);
  assert(record.touchDuring.fireRequests > 5);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await page.waitForTimeout(100);
  assert.equal((await state()).touches, 0);
  await page.screenshot({ path: `${evidence}/touch.png` });
  await page.keyboard.press('r');
  await page.waitForFunction(() => window.radbroState.seconds < 0.5 && window.radbroState.position[0] === 512);
  await page.mouse.move(550, 310);
  await page.mouse.down();
  for (let step = 0; step < 700; step++) {
    const current = await state();
    assert.equal(current.phase, 'playing', 'The aiming bot must survive this integration check.');
    if (current.key_spawned) break;
    const target = current.targets[0];
    const velocity = current.target_velocities[0];
    const distance = Math.hypot(target[0] - current.position[0], target[1] - current.position[1]);
    await page.mouse.move(target[0] + velocity[0] * distance / 900, target[1] + velocity[1] * distance / 900);
    await page.waitForTimeout(70);
  }
  await page.mouse.up();
  record.cleared = await state();
  assert.equal(record.cleared.wave, 2);
  assert.equal(record.cleared.enemies, 0);
  assert(record.cleared.key_spawned);
  await page.screenshot({ path: `${evidence}/cleared.png` });
  async function moveTo(x, y, until) {
    let held = '';
    for (let step = 0; step < 180; step++) {
      const current = await state();
      if (until(current)) break;
      const dx = x - current.position[0], dy = y - current.position[1];
      const key = Math.abs(dx) > 8 ? (dx > 0 ? 'd' : 'a') : (dy > 0 ? 's' : 'w');
      if (held !== key) {
        if (held) await page.keyboard.up(held);
        await page.keyboard.down(key);
        held = key;
      }
      await page.waitForTimeout(30);
    }
    if (held) await page.keyboard.up(held);
  }
  await moveTo(512, 365, s => s.key === 1);
  record.key = await state();
  assert.equal(record.key.key, 1);
  await moveTo(515, 165, s => s.phase === 'won');
  record.won = await state();
  assert.equal(record.won.phase, 'won');
  await page.screenshot({ path: `${evidence}/won.png` });
  await page.keyboard.press('r');
  await page.waitForFunction(() => window.radbroState.phase === 'playing' && window.radbroState.enemies === 3);
  record.restarted = await state();
  assert.equal(record.restarted.hp, 6);
  assert.equal(record.restarted.key, 0);
  await moveTo(810, 480, s => s.weapon.endsWith('violet_arrow.tscn'));
  record.upgraded = await state();
  assert(record.upgraded.weapon.endsWith('violet_arrow.tscn'));
  await page.screenshot({ path: `${evidence}/upgraded.png` });
  await page.mouse.click(510, 736);
  await page.waitForFunction(() => window.radbroState.phase === 'paused');
  await page.screenshot({ path: `${evidence}/credits.png` });
  await page.keyboard.press('p');
  await page.keyboard.press('r');
  await page.waitForFunction(() => window.radbroState.phase === 'playing' && window.radbroState.hp === 6);
  let held = '';
  for (let step = 0; step < 650; step++) {
    const current = await state();
    if (current.phase === 'lost') break;
    const target = current.targets[0];
    let dx = target[0] - current.position[0], dy = target[1] - current.position[1];
    // Leave contact briefly, then return. This uses normal movement and damage.
    if (step % 30 > 22) { dx = -dx; dy = -dy; }
    const key = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'd' : 'a') : (dy > 0 ? 's' : 'w');
    if (held !== key) {
      if (held) await page.keyboard.up(held);
      await page.keyboard.down(key);
      held = key;
    }
    await page.waitForTimeout(90);
  }
  if (held) await page.keyboard.up(held);
  record.lost = await state();
  assert.equal(record.lost.phase, 'lost');
  assert.equal(record.lost.hp, 0);
  await page.screenshot({ path: `${evidence}/lost.png` });
  await page.keyboard.press('r');
  await page.waitForFunction(() => window.radbroState.phase === 'playing' && window.radbroState.hp === 6);
  await page.route('**/sandbox-test', route => route.fulfill({ contentType: 'text/html', body: '<html><body style="margin:0"><iframe sandbox="allow-scripts allow-pointer-lock" style="border:0;width:1024px;height:800px" src="/"></iframe></body></html>' }));
  await page.goto(`${base}/sandbox-test`);
  const frame = page.frames()[1];
  await frame.waitForFunction(() => window.radbroState?.phase === 'playing');
  record.sandbox = await frame.evaluate(() => ({ origin: window.origin, state: window.radbroState }));
  assert.equal(record.sandbox.origin, 'null');
  await page.screenshot({ path: `${evidence}/sandbox.png` });
  record.errors = errors;
  fs.writeFileSync(`${evidence}/browser-proof.json`, JSON.stringify(record, null, 2));
  await browser.close();
  assert.deepEqual(errors, []);
  console.log('Browser checks passed: movement, pause, restart, two-finger touch, two waves, key, win, upgrade, credits, loss, opaque iframe.');
})().catch(error => { console.error(error); process.exit(1); });
