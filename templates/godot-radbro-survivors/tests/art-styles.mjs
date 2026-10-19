// Optional real-input verification for the local Godot art comparison.
import { createRequire } from 'node:module';
import fs from 'node:fs/promises';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const url = process.env.GAME_URL || 'http://127.0.0.1:8780/godot-radbro-survivors/index.html';
const out = process.env.EVIDENCE_DIR || 'evidence/survivors-art-toggle';
await fs.mkdir(out, {recursive:true});
const browser = await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const context = await browser.newContext({viewport:{width:960,height:640},hasTouch:true});
const page = await context.newPage();
const errors = [], checks = [];
page.on('pageerror', e => errors.push(e.message));
page.on('console', m => {if(m.type()==='error') errors.push(m.text());});
function check(pass,label) {checks.push({label,pass:!!pass});if(!pass) throw Error(label);}
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
const waitState = value => page.waitForFunction(value=>JSON.parse(window.render_game_to_text()).state===value,value);
const waitStyle = (value, target=page) => target.waitForFunction(value=>JSON.parse(window.render_game_to_text()).art_style===value,value);
function gameplay(snapshot) {
  const copy = structuredClone(snapshot);
  delete copy.art_style;
  delete copy.player.paperdoll;
  for(const enemy of copy.enemies) delete enemy.art_style;
  return JSON.stringify(copy);
}
let outcome;
try {
  await page.goto(url);
  await page.waitForFunction(() => typeof window.render_game_to_text==='function',null,{timeout:60000});
  check(JSON.stringify((await state()).available_art_styles)===JSON.stringify(['native','illustrated']),'both real-game styles load');
  const ready=await state();
  await page.keyboard.press('t');
  await waitStyle('illustrated');
  const readyIllustrated=await state();
  check(readyIllustrated.art_style==='illustrated' && gameplay(ready)===gameplay(readyIllustrated),'ready toggle preserves gameplay');
  await page.keyboard.press('t');
  await waitStyle('native');
  await page.keyboard.press('Enter');
  await waitState('playing');
  for(const [key,facing] of [['ArrowLeft','left'],['ArrowUp','up'],['ArrowRight','right'],['ArrowDown','down']]) {
    const before=await state();
    await page.keyboard.down(key); await page.waitForTimeout(180); await page.keyboard.up(key);
    const after=await state();
    check(after.player.facing===facing && (after.player.x!==before.player.x || after.player.y!==before.player.y),`movement and ${facing} facing`);
  }
  await page.waitForTimeout(2200);
  await page.screenshot({path:`${out}/native-playing.png`});
  const running=await state();
  await page.mouse.click(820,100);
  await waitStyle('illustrated');
  const switched=await state();
  check(switched.state==='playing' && switched.art_style==='illustrated' && switched.player.node_id===running.player.node_id && switched.elapsed>=running.elapsed && switched.kills>=running.kills,'click changes art during the same live round');
  check(switched.enemies.every(e=>e.art_style==='illustrated'),'existing enemies switch together');
  await page.screenshot({path:`${out}/illustrated-playing.png`});
  await page.keyboard.press('p');
  await waitState('paused');
  const frozen=await state();
  await page.keyboard.press('t');
  await waitStyle('native');
  const frozenNative=await state();
  check(frozenNative.state==='paused' && frozenNative.art_style==='native' && gameplay(frozen)===gameplay(frozenNative),'paused toggle preserves all gameplay fields and node IDs');
  await page.waitForTimeout(250);
  check(gameplay(frozenNative)===gameplay(await state()),'toggle keeps pause active');
  const cdp=await context.newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:820,y:100,id:1}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await waitStyle('illustrated');
  check((await state()).art_style==='illustrated' && gameplay(frozenNative)===gameplay(await state()),'real touch changes style without changing the paused run');
  await page.keyboard.press('p');
  await waitState('playing');
  const touchStart=await state();
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:134,y:595,id:1},{x:286,y:595,id:2}]});
  await page.waitForTimeout(300);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  const touchEnd=await state();
  check(touchEnd.player.x>touchStart.player.x+20 && touchEnd.player.y<touchStart.player.y-20,'simultaneous touch movement works after art changes');

  // Complete a real round. Keep switching through combat and upgrade choices.
  await page.keyboard.press('r');
  await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).elapsed<1);
  const directions=['ArrowRight','ArrowDown','ArrowLeft','ArrowUp'];
  let nextTurn=0, direction=0, nextStyle=3, upgradeCount=0, toggleCount=0;
  const began=Date.now();
  await page.keyboard.down(directions[direction]);
  while(Date.now()-began<115000) {
    const s=await state(); outcome=s;
    if(['won','lost'].includes(s.state)) break;
    if(s.state==='upgrade') {
      await page.keyboard.up(directions[direction]);
      await page.keyboard.press('t'); toggleCount++;
      await waitStyle(s.art_style==='native'?'illustrated':'native');
      const upgradedStyle=await state();
      check(upgradedStyle.state==='upgrade' && gameplay(s)===gameplay(upgradedStyle),'upgrade-screen toggle preserves pending choice');
      await page.keyboard.press(String((upgradeCount%3)+1)); upgradeCount++;
      await page.keyboard.down(directions[direction]);
    }
    if(s.elapsed>=nextStyle) {
      await page.keyboard.press('t'); toggleCount++; nextStyle=s.elapsed+3;
    }
    if(s.elapsed>=nextTurn) {
      await page.keyboard.up(directions[direction]); direction=(direction+1)%4;
      await page.keyboard.down(directions[direction]); nextTurn=s.elapsed+1.7;
    }
    await page.waitForTimeout(200);
  }
  await page.keyboard.up(directions[direction]);
  check(['won','lost'].includes(outcome.state),'art comparison reaches a genuine game outcome');
  check(outcome.kills>0 && upgradeCount>0 && toggleCount>5,'combat XP and upgrades work through repeated style switches');
  const final=await state(); await page.keyboard.press('t');
  await waitStyle(final.art_style==='native'?'illustrated':'native');
  check(gameplay(final)===gameplay(await state()),'outcome toggle preserves the result');
  await page.screenshot({path:`${out}/outcome.png`});
  await fs.writeFile(`${out}/outcome.json`,JSON.stringify({outcome,upgradeCount,toggleCount},null,2));

  // Test an opaque origin without allow-same-origin.
  const host=new URL('__art_embed_host__',url).href;
  await page.route(host, route=>route.fulfill({contentType:'text/html',body:'<!doctype html><title>Art iframe check</title>'}));
  await page.goto(host);
  await page.setContent(`<iframe title="Survivors" sandbox="allow-scripts allow-pointer-lock" src="${url}" width="960" height="640"></iframe>`);
  const frame=await (await page.waitForSelector('iframe')).contentFrame();
  await frame.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:60000});
  const frameState=()=>frame.evaluate(()=>JSON.parse(window.render_game_to_text()));
  check((await frameState()).art_style==='native','opaque iframe loads review art');
  await frame.locator('canvas').click({position:{x:820,y:100}});
  await waitStyle('illustrated',frame);
  check((await frameState()).art_style==='illustrated','opaque iframe art button works');
  await page.keyboard.press('Enter'); await page.waitForTimeout(250);
  check((await frameState()).state==='playing','opaque iframe starts the same game');
  check(errors.length===0,'no browser errors');
} finally {
  await fs.writeFile(`${out}/checks.json`,JSON.stringify({checks,errors},null,2));
  console.log(JSON.stringify({checks,errors}));
  await browser.close();
}
