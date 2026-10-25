// Optional real-input verification for the local Godot art comparison.
import { createRequire } from 'node:module';
import fs from 'node:fs/promises';
import {configureAudioTestSink} from './browser-audio.mjs';
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const url = process.env.GAME_URL || 'http://127.0.0.1:8780/godot-radbro-survivors/index.html';
const out = process.env.EVIDENCE_DIR || 'evidence/survivors-art-toggle';
await fs.mkdir(out, {recursive:true});
const browser = await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const context = await browser.newContext({viewport:{width:960,height:640},hasTouch:true});
const audioTest = await configureAudioTestSink(context);
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
  delete copy.visual_style;
  delete copy.active_fx;
  delete copy.audio;
  delete copy.animation;
  delete copy.player.paperdoll;
  for(const enemy of copy.enemies) delete enemy.art_style;
  for(const projectile of copy.projectiles) delete projectile.art_style;
  return JSON.stringify(copy);
}
let outcome;
try {
  await page.goto(url);
  await page.waitForFunction(() => typeof window.render_game_to_text==='function',null,{timeout:60000});
  check(JSON.stringify((await state()).available_art_styles)===JSON.stringify(['native','illustrated']),'both real-game styles load');
  check((await state()).visual_style.ground_texture_loaded,'native ground texture loads');
  const ready=await state();
  await page.keyboard.press('t');
  await waitStyle('illustrated');
  const readyIllustrated=await state();
  check(readyIllustrated.art_style==='illustrated' && gameplay(ready)===gameplay(readyIllustrated),'ready toggle preserves gameplay');
  check(readyIllustrated.animation.source==='generated-idle','illustrated style has a dedicated idle clip');
  const idleFrames=new Set();
  for(let i=0;i<9;i++){idleFrames.add((await state()).animation.frame);await page.waitForTimeout(200);}
  check(idleFrames.size>1,'illustrated idle advances without movement');
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
  await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).active_fx.kinds.defeat>0);
  await page.screenshot({path:`${out}/native-playing.png`});
  const running=await state();
  await page.mouse.click(820,100);
  await waitStyle('illustrated');
  const switched=await state();
  check(switched.state==='playing' && switched.art_style==='illustrated' && switched.player.node_id===running.player.node_id && switched.elapsed>=running.elapsed && switched.kills>=running.kills,'click changes art during the same live round');
  check(switched.enemies.every(e=>e.art_style==='illustrated'),'existing enemies switch together');
  check(switched.visual_style.floor==='illustrated' && switched.visual_style.ground_texture_loaded && switched.visual_style.gun==='illustrated','illustrated ground and weapon load together');
  check(switched.projectiles.every(p=>p.art_style==='illustrated') && switched.active_fx.style==='illustrated','in-flight shots and effects use the selected style');
  await page.screenshot({path:`${out}/illustrated-playing.png`});
  await page.waitForFunction(()=>{const s=JSON.parse(window.render_game_to_text());return s.active_fx.events.some(e=>e.age<0.05) && s.projectiles.length>0;});
  await page.keyboard.press('p');
  await waitState('paused');
  const frozen=await state();
  check(frozen.active_fx.events.length>0 && frozen.projectiles.length>0,'paused comparison contains live effects and in-flight shots');
  await page.keyboard.press('t');
  await waitStyle('native');
  const frozenNative=await state();
  check(frozenNative.state==='paused' && frozenNative.art_style==='native' && gameplay(frozen)===gameplay(frozenNative),'paused toggle preserves all gameplay fields and node IDs');
  check(frozenNative.visual_style.floor==='native' && frozenNative.visual_style.gun==='native' && frozenNative.projectiles.every(p=>p.art_style==='native') && frozenNative.active_fx.style==='native','paused toggle restyles the complete scene');
  check(JSON.stringify(frozen.active_fx.events)===JSON.stringify(frozenNative.active_fx.events),'active effect IDs and ages survive the toggle');
  await page.waitForTimeout(250);
  check(gameplay(frozenNative)===gameplay(await state()),'toggle keeps pause active');
  check(JSON.stringify(frozenNative.active_fx)===JSON.stringify((await state()).active_fx),'pause freezes all effect clocks and lifetimes');
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
  const route=[{x:100,y:190},{x:860,y:190},{x:860,y:490},{x:100,y:490}];
  const held=new Set();
  const setKeys=async keys=>{for(const key of [...held])if(!keys.includes(key)){await page.keyboard.up(key);held.delete(key);}for(const key of keys)if(!held.has(key)){await page.keyboard.down(key);held.add(key);}};
  let waypoint=0, nextStyle=3, upgradeCount=0, toggleCount=0;
  const began=Date.now();
  while(Date.now()-began<115000) {
    const s=await state(); outcome=s;
    if(['won','lost'].includes(s.state)) break;
    if(s.state==='upgrade') {
      await setKeys([]);
      await page.keyboard.press('t'); toggleCount++;
      await waitStyle(s.art_style==='native'?'illustrated':'native');
      const upgradedStyle=await state();
      check(upgradedStyle.state==='upgrade' && gameplay(s)===gameplay(upgradedStyle),'upgrade-screen toggle preserves pending choice');
      await page.keyboard.press(String((upgradeCount%3)+1)); upgradeCount++;
    }
    if(s.elapsed>=nextStyle) {
      await page.keyboard.press('t'); toggleCount++; nextStyle=s.elapsed+3;
    }
    if(Math.hypot(route[waypoint].x-s.player.x,route[waypoint].y-s.player.y)<40)waypoint=(waypoint+1)%route.length;
    const dx=route[waypoint].x-s.player.x,dy=route[waypoint].y-s.player.y, keys=[];
    if(Math.abs(dx)>12)keys.push(dx>0?'ArrowRight':'ArrowLeft');
    if(Math.abs(dy)>12)keys.push(dy>0?'ArrowDown':'ArrowUp');
    await setKeys(keys);
    await page.waitForTimeout(200);
  }
  await setKeys([]);
  check(['won','lost'].includes(outcome.state),'art comparison reaches a genuine game outcome');
  check(outcome.kills>0 && upgradeCount>0 && toggleCount>5,'combat XP and upgrades work through repeated style switches');
  check(outcome.state==='won','moving circuit can win the tuned three-wave round');
  check(['muzzle','hit','defeat','pickup','upgrade'].every(kind=>outcome.active_fx.emitted[kind]>0),'all five feedback effects occur through real gameplay');
  check(outcome.active_fx.count<=outcome.active_fx.limit,'live effects stay within their fixed budget');
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
  await fs.writeFile(`${out}/checks.json`,JSON.stringify({audioTest,checks,errors},null,2));
  console.log(JSON.stringify({checks,errors}));
  await browser.close();
}
