import { makeLevel, createGame, startGame, togglePause, advance, snapshot, nearChest } from './game-model.mjs';
const keys = new Set(), touches = new Map();
const bindings = { ArrowLeft: 'left', a: 'left', ArrowRight: 'right', d: 'right', ArrowUp: 'up', w: 'up', ArrowDown: 'down', s: 'down', ' ': 'attack' };
const ui = Object.fromEntries(['start', 'pause', 'restart', 'status', 'loading', 'health', 'loot', 'enemies'].map(id => [id, document.getElementById(id)]));
let state, scene, manual = false, loadFailed = false, resultSent = false;
const ready = { type: 'radbro:game-ready', game: 'phaser-radbro-dungeon-crawler', title: 'Radbro Dungeon Crawler', objective: 'Open three chests. Defeat four lizards. Return to the lime portal.', controls: ['WASD/arrows move', 'Space throws or opens a nearby chest', 'P pause', 'R restart', 'Touch direction and Throw / Open'], viewport: { width: 960, height: 600 } };
function reportReady() { if (state && !loadFailed) window.parent.postMessage(ready, '*'); }
window.addEventListener('message', event => { if (event.source === window.parent && event.data?.type === 'radbro:game-ready-request') reportReady(); });
const input = () => Object.fromEntries(['left', 'right', 'up', 'down', 'attack'].map(action => [action, keys.has(action) || [...touches.values()].includes(action)]));
function clearInput() { keys.clear(); touches.clear(); document.querySelectorAll('.held').forEach(button => button.classList.remove('held')); }
function restart() { if (!state) return; clearInput(); state = createGame(state.level); startGame(state); resultSent = false; scene.paint(); }
function pause() { if (!state) return; togglePause(state); clearInput(); scene.paint(); }
ui.start.onclick = () => { if (state) { startGame(state); scene.paint(); } };
ui.pause.onclick = pause; ui.restart.onclick = restart;
window.addEventListener('keydown', event => {
  const key = event.key.length === 1 ? event.key.toLowerCase() : event.key;
  if (bindings[key]) { event.preventDefault(); keys.add(bindings[key]); }
  if (event.repeat) return;
  if (key === 'Enter' && state) startGame(state);
  if (key === 'p') pause();
  if (key === 'r') restart();
  if (key === 'f') { if (document.fullscreenElement) document.exitFullscreen?.(); else document.querySelector('.game-shell').requestFullscreen?.().catch(() => {}); }
});
window.addEventListener('keyup', event => keys.delete(bindings[event.key.toLowerCase()] || bindings[event.key]));
window.addEventListener('blur', () => { clearInput(); if (state?.mode === 'playing') pause(); });
document.querySelectorAll('[data-input]').forEach(button => {
  button.addEventListener('pointerdown', event => { event.preventDefault(); button.setPointerCapture(event.pointerId); touches.set(event.pointerId, button.dataset.input); button.classList.add('held'); });
  const release = event => { touches.delete(event.pointerId); button.classList.remove('held'); };
  for (const event of ['pointerup', 'pointercancel', 'lostpointercapture']) button.addEventListener(event, release);
});

class Dungeon extends Phaser.Scene {
  preload() {
    const art = 'upstream/art/';
    this.load.image('tiles', `${art}tiles/dungeon_tiles_extruded.png`);
    this.load.tilemapTiledJSON('dungeon', `${art}tiles/dungeon-01.json`);
    for (const [key, path] of [['lizard', 'enemies/lizard'], ['treasure', 'items/treasure']]) this.load.atlas(key, `${art}${path}.png`, `${art}${path}.json`);
    this.load.image('knife', `${art}weapons/weapon_knife.png`);
    for (const clip of ['idle', 'walk']) this.load.atlas(clip, `assets/radcat-motion-v2/sprites/${clip}-sheet.png`, `assets/radcat-motion-v2/sprites/${clip}-sheet.json`);
    this.load.on('loaderror', file => { loadFailed = true; ui.loading.textContent = `Could not load ${file.key}. Run python3 prepare.py in this template.`; });
  }
  create() {
    scene = this;
    if (loadFailed) return;
    const raw = this.cache.tilemap.get('dungeon').data;
    state = createGame(makeLevel(raw));
    const map = this.make.tilemap({ key: 'dungeon' });
    const tiles = map.addTilesetImage('dungeon', 'tiles', 16, 16, 1, 2);
    map.createLayer('Ground', tiles);
    map.createLayer('Walls', tiles).setDepth(1);
    this.cameras.main.setBackgroundColor('#171c22').setZoom(2).setBounds(0, 0, state.level.width, state.level.height);
    this.portal = this.add.ellipse(128, 128, 30, 18, 0x98d867, .4).setStrokeStyle(1, 0xc5ef90).setDepth(2);
    this.add.text(128, 151, 'RETURN', { fontFamily: 'Arial', fontSize: '7px', color: '#c5ef90' }).setOrigin(.5).setDepth(3);
    this.chests = state.chests.map(chest => this.add.sprite(chest.x, chest.y, 'treasure', 'chest_empty_open_anim_f0.png').setDepth(chest.y));
    this.lizards = state.enemies.map(enemy => this.add.sprite(enemy.x, enemy.y - 7, 'lizard', 'lizard_m_idle_anim_f0.png'));
    this.shadow = this.add.ellipse(state.player.x, state.player.y + 1, 17, 6, 0x080e14, .6);
    this.cat = this.add.sprite(state.player.x, state.player.y - 10, 'idle', 'idle-00').setDisplaySize(40, 40);
    this.aim = this.add.triangle(0, 0, 0, 0, -3, 5, 3, 5, 0xd5ef97).setOrigin(.5).setAlpha(.7);
    this.knives = Array.from({ length: 3 }, () => this.add.image(0, 0, 'knife').setVisible(false).setDepth(500));
    this.ring = this.add.ellipse(0, 0, 33, 21).setStrokeStyle(1, 0xf1cf76).setVisible(false);
    const shell = document.querySelector('.game-shell');
    this.overlay = document.createElement('div'); this.overlay.className = 'overlay'; shell.appendChild(this.overlay);
    ui.loading.hidden = true; ui.start.disabled = false; ui.restart.disabled = false;
    window.render_game_to_text = () => JSON.stringify(snapshot(state));
    window.advanceTime = milliseconds => { manual = true; advance(state, input(), milliseconds); this.paint(); };
    this.paint(); reportReady();
  }
  update(_time, delta) { if (!state) return; if (!manual) advance(state, input(), Math.min(delta, 100)); this.paint(); }
  paint() {
    const p = state.player, playing = state.mode === 'playing';
    this.cameras.main.centerOn(p.x, p.y);
    const clip = state.moving && playing ? 'walk' : 'idle';
    const frame = Math.floor(state.elapsed * 1000 / (clip === 'walk' ? 120 : 300)) % 6;
    this.cat.setTexture(clip, `${clip}-${String(frame).padStart(2, '0')}`).setPosition(p.x, p.y - 10).setFlipX(state.visualFacing < 0).setDepth(p.y + 1)
      .setAlpha(state.immune > 0 && Math.floor(state.elapsed * 14) % 2 ? .4 : 1);
    this.shadow.setPosition(p.x, p.y + 1).setDepth(p.y);
    this.aim.setPosition(p.x + state.facing.x * 17, p.y + state.facing.y * 17).setRotation(Math.atan2(state.facing.y, state.facing.x) + Math.PI / 2).setDepth(p.y + 2);
    this.chests.forEach((image, i) => image.setFrame(`chest_empty_open_anim_f${state.chests[i].opened ? 2 : 0}.png`));
    this.lizards.forEach((image, i) => { const enemy = state.enemies[i]; image.setVisible(enemy.alive).setPosition(enemy.x, enemy.y - 7).setDepth(enemy.y).setFlipX(enemy.direction === 2).setFrame(`lizard_m_run_anim_f${Math.floor(state.elapsed * 10) % 4}.png`); });
    this.knives.forEach((image, i) => { const knife = state.knives[i]; image.setVisible(Boolean(knife)); if (knife) image.setPosition(knife.x, knife.y).setRotation(Math.atan2(knife.vy, knife.vx)); });
    const chest = nearChest(state); this.ring.setVisible(Boolean(chest) && playing); if (chest) this.ring.setPosition(chest.x, chest.y).setDepth(chest.y - 1);
    const opened = state.chests.filter(c => c.opened).length, enemies = state.enemies.filter(e => e.alive).length;
    ui.health.textContent = `${'♥ '.repeat(state.health)}${'♡ '.repeat(3 - state.health)}`;
    ui.loot.textContent = `${opened} / 3 CHESTS · ${state.coins} GOLD`; ui.enemies.textContent = `${enemies} LIZARDS`;
    const unlocked = opened === 3 && enemies === 0;
    this.portal.setFillStyle(unlocked ? 0xc7fa8d : 0x619549, unlocked ? .9 : .4);
    const overlays = {
      ready: '<strong>Enter the dungeon.</strong><p>Open three chests. Defeat four lizards.<br>Return to the lime portal.</p><small>Space throws in your last movement direction.<br>Near a chest, Space opens it.</small>',
      paused: '<strong>Dungeon paused.</strong><p>Your loot and health are saved.</p><small>Select Resume or press P.</small>',
      won: '<strong>Dungeon cleared!</strong><p>You found all three chests<br>and defeated every lizard.</p><small>Select Restart or press R to play again.</small>',
      lost: '<strong>The dungeon won.</strong><p>Your three hearts are gone.</p><small>Select Restart or press R to try again.</small>',
    };
    this.overlay.hidden = playing; if (!playing && this.overlay.innerHTML !== overlays[state.mode]) this.overlay.innerHTML = overlays[state.mode];
    ui.start.hidden = state.mode !== 'ready'; ui.pause.disabled = !['playing', 'paused'].includes(state.mode); ui.pause.textContent = state.mode === 'paused' ? 'Resume' : 'Pause';
    ui.status.textContent = playing ? (unlocked ? 'Return to the lime portal in the first room.' : chest ? 'Chest nearby. Press Space or Throw / Open.' : 'Face a lizard. Throw a knife. Find three chests.') : ({ ready: 'Select Enter dungeon.', paused: 'Paused.', won: 'Dungeon cleared.', lost: 'Game over.' })[state.mode];
    if (!resultSent && ['won', 'lost'].includes(state.mode)) { resultSent = true; window.parent.postMessage({ type: 'radbro:game-result', game: ready.game, status: state.mode === 'won' ? 'clear' : 'gameover', score: state.coins + (4 - enemies) * 100 }, '*'); }
  }
}
new Phaser.Game({ type: Phaser.CANVAS, parent: 'game', width: 960, height: 600, scene: Dungeon, banner: false,
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH }, render: { pixelArt: true, roundPixels: true }, audio: { noAudio: true } });
