import path from 'node:path';
import fs from 'node:fs';
import assert from 'node:assert/strict';
const {chromium}=await import(process.env.PLAYWRIGHT_MODULE || 'playwright');
const URL=process.env.GAME_URL || 'http://127.0.0.1:8783';
const OUT=path.resolve(process.env.EVIDENCE_DIR || 'evidence/platformer');
fs.mkdirSync(OUT,{recursive:true});
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1280,height:720}});
page.on('console',m=>{if(m.type()==='error')console.log('CONSOLE',m.text());});
page.setDefaultTimeout(60000);
await page.goto(URL);
await page.waitForFunction(()=>typeof render_game_to_text==='function',{timeout:60000});
const state=()=>page.evaluate(()=>JSON.parse(render_game_to_text()));
await page.locator('canvas').click({position:{x:450,y:350}});await page.keyboard.press('Enter');
await page.waitForTimeout(150);
console.log('START',await state());
await page.keyboard.down('w');await page.waitForTimeout(320);await page.keyboard.up('w');
console.log('FIRST COIN',await state());
for(let i=1;i<6;i++){
 await page.keyboard.down('w');
 while((await state()).player.z>-(i-1)*6-1.0){if((await state()).state!=='playing')throw Error('Lost before jump');await page.waitForTimeout(20);}
 await page.keyboard.press('Space');
 await page.waitForTimeout(500);
 await page.keyboard.press('Space');
 while((await state()).player.z>-i*6+0.7){let s=await state();if(s.state!=='playing')break;await page.waitForTimeout(20);}
 await page.keyboard.up('w');
 await page.waitForFunction(()=>{let s=JSON.parse(render_game_to_text());return s.player.grounded||s.state!=='playing';}, {timeout:3000});
 let landed=await state();
 if(landed.coins<i+1){
   let key=landed.player.z < -i*6 ? 's':'w';
   await page.keyboard.down(key);
   while(Math.abs((await state()).player.z+i*6)>0.35){if((await state()).state!=='playing')throw Error('Lost collecting coin');await page.waitForTimeout(15);}
   await page.keyboard.up(key);await page.waitForTimeout(160);
 }
 console.log('ISLAND',i,await state());
}
await page.keyboard.down('w');await page.waitForTimeout(140);await page.keyboard.up('w');assert.equal((await state()).state,'won');assert.equal((await state()).coins,6);fs.writeFileSync(path.join(OUT,'route-final.json'),JSON.stringify(await state(),null,2));console.log('PASS: keyboard double-jump course, six coins and finish.');
await page.screenshot({path:path.join(OUT,'course.png')});
await browser.close();
