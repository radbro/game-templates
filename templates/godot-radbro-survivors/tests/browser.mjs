// Optional verification harness. Use an existing Playwright installation via NODE_PATH.
import { createRequire } from 'node:module';
import fs from 'node:fs/promises';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const url = process.env.GAME_URL || 'http://localhost:8781';
const out = process.env.EVIDENCE_DIR || 'evidence/survivors/browser';
await fs.mkdir(out, { recursive: true });
const browser = await chromium.launch({headless: true, args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader']});
const context = await browser.newContext({viewport:{width:960,height:640}, hasTouch:true});
const page = await context.newPage();
const errors = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', msg => {if(msg.type()==='error') errors.push(msg.text());});
const checks = [];
const check = (value, label) => {checks.push({label,pass:!!value}); if(!value) throw Error(label);};
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
try {
  await page.goto(url);
  await page.waitForFunction(() => typeof window.render_game_to_text === 'function', null, {timeout:60000});
  if (process.env.IFRAME_ONLY !== '1') {
  await page.screenshot({path:`${out}/ready.png`});
  await page.keyboard.press('Enter');
  await page.waitForTimeout(300);
  check((await state()).state==='playing','keyboard starts game');
  const start = await state();
  await page.keyboard.down('ArrowRight'); await page.waitForTimeout(400); await page.keyboard.up('ArrowRight');
  check((await state()).player.x > start.player.x + 35,'keyboard movement');
  await page.keyboard.press('p');
  const paused = await state(); await page.waitForTimeout(300);
  check((await state()).state==='paused' && (await state()).elapsed===paused.elapsed,'browser pause freezes');
  await page.keyboard.press('p');
  // Real CDP touch contacts. Hold Up and Right at the same time.
  const cdp=await context.newCDPSession(page);
  const beforeTouch=await state();
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:134,y:595,id:1},{x:286,y:595,id:2}]});
  await page.waitForTimeout(450);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  const afterTouch=await state();
  check(afterTouch.player.x > beforeTouch.player.x+20 && afterTouch.player.y < beforeTouch.player.y-20,'simultaneous browser touch movement');
  await page.keyboard.press('r');
  await page.waitForTimeout(150);
  check((await state()).kills===0 && (await state()).player.health===100,'browser restart');
  // A real-input autoplayer follows a broad circuit and chooses available upgrades.
  const directions=['ArrowRight','ArrowDown','ArrowLeft','ArrowUp'];
  let nextTurn=0; let direction=0; let upgradeCount=0; let finalState;
  const began=Date.now();
  await page.keyboard.down(directions[0]);
  while(Date.now()-began < 115000) {
    const s=await state(); finalState=s;
    if(s.state==='won'||s.state==='lost') break;
    if(s.state==='upgrade') {
      await page.keyboard.up(directions[direction]);
      await page.screenshot({path:`${out}/upgrade-${upgradeCount}.png`});
      // Fire speed, power, then healing are each exercised through input.
      await page.keyboard.press(String((upgradeCount%3)+1));
      upgradeCount++;
      await page.keyboard.down(directions[direction]);
    }
    if(s.elapsed>=nextTurn){
      await page.keyboard.up(directions[direction]);
      direction=(direction+1)%4;
      await page.keyboard.down(directions[direction]);
      nextTurn=s.elapsed+1.7;
    }
    if(Math.floor(s.elapsed)===20) await page.screenshot({path:`${out}/gameplay.png`});
    await page.waitForTimeout(200);
  }
  await page.keyboard.up(directions[direction]);
  await page.screenshot({path:`${out}/outcome.png`});
  check(finalState.state==='won'||finalState.state==='lost','browser reaches genuine outcome');
  check(finalState.kills>0 && finalState.shots>0,'browser combat kills');
  check(upgradeCount>0,'browser collects XP and chooses upgrade');
  await fs.writeFile(`${out}/outcome.json`,JSON.stringify(finalState,null,2));
  }
  // Opaque origin: no allow-same-origin. The patched engine must still start.
  await page.route('**/__radbro_embed_host__', route => route.fulfill({contentType:'text/html',body:'<!doctype html><title>Sandbox test host</title>'}));
  await page.goto(url.replace(/\/$/,'') + '/__radbro_embed_host__');
  await page.setContent(`<iframe title="Radbro Survivors" sandbox="allow-scripts allow-pointer-lock" src="${url}" width="960" height="640"></iframe>`);
  const frame=await page.waitForSelector('iframe');
  const gameFrame=await frame.contentFrame();
  await gameFrame.waitForFunction(() => typeof window.render_game_to_text==='function',null,{timeout:60000});
  const iframeReady=await gameFrame.evaluate(() => JSON.parse(window.render_game_to_text()));
  check(iframeReady.state==='ready' && iframeReady.player.paperdoll===false,'opaque iframe boots licensed default');
  await gameFrame.locator('canvas').click({position:{x:480,y:330}});
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);
  check((await gameFrame.evaluate(() => JSON.parse(window.render_game_to_text()))).state==='playing','opaque iframe starts');
  await page.screenshot({path:`${out}/iframe.png`});
  check(errors.length===0,'no browser console or page errors');
  await fs.writeFile(`${out}/results.json`,JSON.stringify({checks,errors},null,2));
  console.log(JSON.stringify({checks,errors}));
} finally {
  await fs.writeFile(`${out}/checks.json`,JSON.stringify({checks,errors},null,2));
  await browser.close();
}
