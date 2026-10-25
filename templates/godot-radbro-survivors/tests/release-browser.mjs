// Real browser audio output, controls and four-direction idle review.
import {createRequire} from 'node:module';
import fs from 'node:fs/promises';
import {configureAudioTestSink} from './browser-audio.mjs';
const {chromium}=createRequire(import.meta.url)('playwright');
const url=process.env.GAME_URL||'http://127.0.0.1:8787/godot-radbro-survivors/index.html';
const out=process.env.EVIDENCE_DIR||'evidence/survivors-release/audio-animation';
await fs.mkdir(out,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const context=await browser.newContext({viewport:{width:960,height:640},hasTouch:true});
const audioTest=await configureAudioTestSink(context);
const page=await context.newPage(),checks=[],errors=[],signals=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
function check(pass,label){checks.push({label,pass:!!pass});console.log(`${pass?'PASS':'FAIL'} ${label}`);if(!pass)throw Error(label);}
await page.addInitScript(()=>{
  window.__soundProbes=[];
  const connect=AudioNode.prototype.connect;
  AudioNode.prototype.connect=function(destination,...args){
    if(destination instanceof AudioDestinationNode){
      const probe=this.context.createAnalyser();probe.fftSize=2048;
      connect.call(this,probe,...args);connect.call(probe,destination);
      window.__soundProbes.push(probe);return destination;
    }
    return connect.call(this,destination,...args);
  };
});
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
const waitMode=value=>page.waitForFunction(v=>JSON.parse(window.render_game_to_text()).state===v,value);
const waitEnabled=value=>page.waitForFunction(v=>JSON.parse(window.render_game_to_text()).audio.enabled===v,value);
async function signal(label){
  let peak=0;const contexts=new Set();
  for(let i=0;i<12;i++){
    const sample=await page.evaluate(()=>window.__soundProbes.map(p=>{
      const data=new Float32Array(p.fftSize);p.getFloatTimeDomainData(data);
      let energy=0;for(const v of data)energy+=v*v;
      return {state:p.context.state,rms:p.context.state==='running'?Math.sqrt(energy/data.length):0};
    }));
    for(const p of sample){contexts.add(p.state);peak=Math.max(peak,p.rms);}
    await page.waitForTimeout(25);
  }
  signals.push({label,peakRms:peak,contexts:[...contexts]});return peak;
}
async function boot(){await page.goto(url);await page.waitForFunction(()=>typeof window.render_game_to_text==='function',null,{timeout:60000});}
try{
  await boot();
  check(!(await state()).audio.unlocked && (await state()).audio.active_voices===0,'no audio before Start');
  await page.keyboard.press('Enter');await waitMode('playing');await page.waitForTimeout(600);
  check((await signal('playing'))>0.00001,'Web Audio graph produces a real signal after Start');
  check((await state()).audio.driver!=='Dummy' && (await state()).audio.backing_playing,'browser uses a live audio driver and backing track');
  await page.keyboard.press('m');await waitEnabled(false);await page.waitForTimeout(350);
  check((await signal('muted'))<0.000001,'M mutes actual output');
  await page.keyboard.press('m');await waitEnabled(true);await page.waitForTimeout(150);
  check((await signal('unmuted'))>0.00001,'M restores actual output');
  await page.keyboard.press('p');await waitMode('paused');
  const paused=await state();await page.waitForTimeout(350);
  check((await signal('paused'))<0.000001 && (await state()).audio.backing_clock===paused.audio.backing_clock,'pause freezes backing and silences the mix');
  const cdp=await context.newCDPSession(page);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:577,y:42,id:1}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await waitEnabled(false);
  check((await state()).state==='paused' && (await state()).elapsed===paused.elapsed,'touch Sound control preserves the paused round');
  await page.keyboard.press('p');await waitMode('playing');await page.waitForTimeout(350);
  check((await signal('muted-resume'))<0.000001,'muted resume stays silent');
  await page.keyboard.press('r');await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).elapsed<1);
  check(!(await state()).audio.enabled,'restart retains the mute choice');
  await page.keyboard.press('m');await waitEnabled(true);
  await page.keyboard.press('t');await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).art_style==='illustrated');
  for(const [key,facing]of[['ArrowDown','down'],['ArrowRight','right'],['ArrowUp','up'],['ArrowLeft','left']]){
    await page.keyboard.down(key);await page.waitForTimeout(160);await page.keyboard.up(key);
    await page.waitForFunction(v=>{const a=JSON.parse(window.render_game_to_text()).animation;return a.clip==='idle' && a.facing===v && a.source==='generated-idle';},facing);
    await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).animation.frame===0);
    await page.screenshot({path:`${out}/idle-${facing}-neutral.png`});
    await page.waitForFunction(()=>JSON.parse(window.render_game_to_text()).animation.frame===2);
    await page.screenshot({path:`${out}/idle-${facing}-blink.png`});
    check((await state()).animation.source==='generated-idle',`dedicated idle and blink render facing ${facing}`);
  }
  const s=await state();check(s.audio.peak_voices<=s.audio.voice_limit && s.audio.requested.fire>0,'real combat uses bounded sound voices');
  // Fresh seeded round. No movement. Resolve upgrade menus with real input.
  await boot();await page.keyboard.press('Enter');await waitMode('playing');
  const began=Date.now();let upgrade=0,outcome;
  while(Date.now()-began<105000){
    outcome=await state();if(['won','lost'].includes(outcome.state))break;
    if(outcome.state==='upgrade')await page.keyboard.press(String((upgrade++%3)+1));
    await page.waitForTimeout(100);
  }
  check(outcome.state==='lost','idle play can lose the tuned round in the browser');
  check(outcome.audio.requested.hurt>0 && outcome.audio.requested.loss>0,'real damage and defeat request their cues');
  check((await signal('loss-cue'))>0.00001,'defeat cue produces real output after backing stops');
  await fs.writeFile(`${out}/idle-outcome.json`,JSON.stringify(outcome,null,2));
  check(errors.length===0,'no browser errors');
}finally{
  await fs.writeFile(`${out}/checks.json`,JSON.stringify({audioTest,checks,errors,signals},null,2));
  console.log(JSON.stringify({checks,errors,signals}));await browser.close();
}
