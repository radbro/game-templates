import { LEVEL, createGame, startGame, togglePause, advance, snapshot, hazardPositions } from './game-model.mjs';

const ASSETS = 'assets/';
const keyboard = new Set();
const touches = new Map();
const keyMap = { ArrowLeft: 'left', a: 'left', ArrowRight: 'right', d: 'right', ArrowUp: 'up', w: 'up', ArrowDown: 'down', s: 'down', ' ': 'hop' };
const ui = Object.fromEntries(['start', 'pause', 'restart', 'status', 'loading'].map(id => [id, document.getElementById(id)]));
let state = createGame();
let scene;
let manualTime = false;
let lastStatus = '';
let loadedSuccessfully = false;
let loadFailed = false;
let resultSent = false;
const readyMessage = {
  type: 'radbro:game-ready', game: 'phaser-radcat-courier', title: 'Radcat Courier',
  objective: 'Collect five energy cells and return to the gate.',
  hint: 'Hop over red hazards.',
  controls: ['WASD/arrows move', 'Space hop', 'P pause', 'R restart', 'Touch buttons move and hop'],
  viewport: { width: 960, height: 600 },
};
function reportReady() {
  // Sandboxed embeds have an opaque origin. Send only public game metadata.
  if (loadedSuccessfully) window.parent.postMessage(readyMessage, '*');
}
window.addEventListener('message', event => {
  if (event.source === window.parent && event.data?.type === 'radbro:game-ready-request') reportReady();
});
function inputs() {
  return Object.fromEntries(['left', 'right', 'up', 'down', 'hop'].map(action =>
    [action, keyboard.has(action) || [...touches.values()].includes(action)]));
}
function clearInput() {
  keyboard.clear(); touches.clear();
  document.querySelectorAll('.held').forEach(button => button.classList.remove('held'));
}
function restart() { clearInput(); resultSent = false; state = createGame(); startGame(state); scene?.paint(); }
function pause() { togglePause(state); clearInput(); scene?.paint(); }
ui.start.onclick = () => { startGame(state); scene?.paint(); };
ui.restart.onclick = restart;
ui.pause.onclick = pause;
window.addEventListener('keydown', event => {
  const key = event.key.length === 1 ? event.key.toLowerCase() : event.key;
  if (keyMap[key]) { event.preventDefault(); keyboard.add(keyMap[key]); }
  if (event.repeat) return;
  if (key === 'Enter' && state.mode === 'ready') startGame(state);
  if (key === 'p') pause();
  if (key === 'r') restart();
  if (key === 'Escape' && document.fullscreenElement) document.exitFullscreen?.().catch(() => {});
  if (key === 'f') {
    if (document.fullscreenElement) document.exitFullscreen?.();
    else document.querySelector('.game-shell').requestFullscreen?.().catch(() => {});
  }
});
window.addEventListener('keyup', event => keyboard.delete(keyMap[event.key.toLowerCase()] || keyMap[event.key]));
window.addEventListener('blur', () => { clearInput(); if (state.mode === 'playing') pause(); });
document.querySelectorAll('[data-input]').forEach(button => {
  button.addEventListener('pointerdown', event => {
    event.preventDefault(); button.setPointerCapture(event.pointerId);
    touches.set(event.pointerId, button.dataset.input); button.classList.add('held');
  });
  const release = event => { touches.delete(event.pointerId); button.classList.remove('held'); };
  button.addEventListener('pointerup', release);
  button.addEventListener('pointercancel', release);
  button.addEventListener('lostpointercapture', release);
});

class CourierScene extends Phaser.Scene {
  preload() {
    for (const key of ['ground', 'wall', 'energy', 'gate', 'hazard', 'beacon']) {
      this.load.svg(key, `${ASSETS}relay-arena-2d/${key}.svg`);
    }
    for (const key of ['idle', 'walk', 'hop']) {
      // Keep source JSON frame metadata. Each source frame is 320 × 320.
      this.load.atlas(key, `${ASSETS}radcat-motion-v2/sprites/${key}-sheet.png`,
        `${ASSETS}radcat-motion-v2/sprites/${key}-sheet.json`);
    }
    this.load.on('loaderror', file => { loadFailed = true; ui.loading.textContent = `Could not load ${file.key}. Run the asset preparation command.`; });
  }
  create() {
    scene = this;
    this.cameras.main.setBackgroundColor('#233d49');
    this.add.tileSprite(480, 300, 960, 600, 'ground');
    this.add.rectangle(480, 50, 960, 100, 0x102536, 0.92);
    this.add.text(36, 22, 'THE RELAY YARD', { fontFamily: 'Arial', fontSize: '15px', color: '#a4bdcc', fontStyle: 'bold' });
    this.hud = this.add.text(924, 22, '', { fontFamily: 'Arial', fontSize: '18px', color: '#e8f2df', align: 'right' }).setOrigin(1, 0);
    this.add.rectangle(480, 334, 896, 468).setStrokeStyle(2, 0x7caaa2, .28);
    this.add.image(LEVEL.gate.x, LEVEL.gate.y, 'gate').setDisplaySize(128, 96).setAlpha(.8);
    this.gateLabel = this.add.text(120, 538, 'RETURN HERE', { fontFamily: 'Arial', fontSize: '11px', color: '#a5dff3' }).setOrigin(.5);
    for (const wall of LEVEL.walls) {
      this.add.rectangle(wall.x + wall.w / 2 + 5, wall.y + wall.h / 2 + 7, wall.w, wall.h, 0x091a26, .5);
      this.add.tileSprite(wall.x + wall.w / 2, wall.y + wall.h / 2, wall.w, wall.h, 'wall');
    }
    this.cellImages = LEVEL.cells.map(c => this.add.image(c.x, c.y, 'energy').setDisplaySize(40, 40));
    this.hazardImages = LEVEL.hazards.map(h => this.add.image(h.x, h.y, 'hazard').setDisplaySize(54, 54));
    this.shadow = this.add.ellipse(state.player.x, state.player.y + 10, 46, 15, 0x071e29, .5);
    this.cat = this.add.sprite(state.player.x, state.player.y - 31, 'idle', 'idle-00').setDisplaySize(108, 108);
    this.beacon = this.add.image(LEVEL.gate.x, LEVEL.gate.y - 60, 'beacon').setDisplaySize(34, 34).setVisible(false);
    this.shade = this.add.rectangle(480, 338, 770, 310, 0x102536, .97).setStrokeStyle(2, 0x8bada4, .5);
    this.title = this.add.text(480, 252, '', { fontFamily: 'Arial', fontSize: '34px', fontStyle: 'bold', color: '#d0f397' }).setOrigin(.5);
    this.message = this.add.text(480, 324, '', { fontFamily: 'Arial', fontSize: '20px', align: 'center', lineSpacing: 12, color: '#e1ebef' }).setOrigin(.5);
    this.hint = this.add.text(480, 417, '', { fontFamily: 'Arial', fontSize: '14px', color: '#a7c6d5' }).setOrigin(.5);
    ui.loading.hidden = true; ui.start.disabled = false; ui.restart.disabled = false;
    window.render_game_to_text = () => JSON.stringify(snapshot(state));
    window.advanceTime = milliseconds => {
      manualTime = true;
      advance(state, inputs(), milliseconds); this.paint();
    };
    this.paint();
    loadedSuccessfully = !loadFailed;
    reportReady();
  }
  update(_time, delta) {
    // Long background frames cannot consume the route timer.
    if (!manualTime) advance(state, inputs(), Math.min(delta, 100));
    this.paint();
  }
  paint() {
    const collected = state.cells.filter(c => c.collected).length;
    if (!resultSent && (state.mode === 'won' || state.mode === 'lost')) {
      resultSent = true;
      window.parent.postMessage({ type: 'radbro:game-result', game: 'phaser-radcat-courier',
        status: state.mode === 'won' ? 'clear' : 'gameover', score: collected * 100 }, '*');
    }
    this.hud.setText(`${collected} / ${state.cells.length} CELLS    ${Math.ceil(state.remaining)}s    ${state.lives} LIVES`);
    this.cellImages.forEach((image, i) => image.setVisible(!state.cells[i].collected));
    hazardPositions(state).forEach((h, i) => this.hazardImages[i].setPosition(h.x, h.y));
    const animation = state.hop > 0 ? 'hop' : state.moving && state.mode === 'playing' ? 'walk' : 'idle';
    const count = animation === 'hop' ? 7 : 6;
    const frameMs = animation === 'idle' ? 300 : animation === 'walk' ? 120 : 140;
    const animationMs = animation === 'hop' ? (0.98 - state.hop) * 1000 : state.elapsed * 1000;
    const frame = animation === 'hop' ? Math.min(6, Math.floor(animationMs / frameMs)) : Math.floor(animationMs / frameMs) % count;
    this.cat.setTexture(animation, `${animation}-${String(Math.max(0, frame)).padStart(2, '0')}`)
      .setPosition(state.player.x, state.player.y - 31).setFlipX(state.facing < 0)
      .setAlpha(state.immune > 0 && Math.floor(state.elapsed * 12) % 2 ? .45 : 1);
    this.shadow.setPosition(state.player.x, state.player.y + 10);
    this.beacon.setVisible(collected === state.cells.length);
    this.gateLabel.setText(collected === state.cells.length ? 'GATE READY' : 'RETURN HERE');
    const overlays = {
      ready: ['Your route starts here.', 'Collect five energy cells.\nHop over the red hazards. Return to the gate.', 'Select Start route or press Enter.'],
      paused: ['Route paused', 'Your cells and time are saved.', 'Select Resume or press P.'],
      won: ['Delivery complete!', 'All five cells reached the gate.', 'Select Restart or press R for another route.'],
      lost: ['Route ended', state.lives <= 0 ? 'The hazards used all three lives.' : 'The route timer reached zero.', 'Select Restart or press R to try again.'],
    };
    const overlay = overlays[state.mode];
    [this.shade, this.title, this.message, this.hint].forEach(item => item.setVisible(Boolean(overlay)));
    if (overlay) { this.title.setText(overlay[0]); this.message.setText(overlay[1]); this.hint.setText(overlay[2]); }
    ui.start.hidden = state.mode !== 'ready';
    ui.pause.disabled = !['playing', 'paused'].includes(state.mode);
    ui.pause.textContent = state.mode === 'paused' ? 'Resume' : 'Pause';
    const status = state.mode === 'playing' ? (collected === state.cells.length ? 'All cells collected. Return to the lime gate.' : 'Collect cells. Hop over hazards. You have three lives.') : overlays[state.mode]?.[0];
    if (status !== lastStatus) { ui.status.textContent = status; lastStatus = status; }
  }
}
new Phaser.Game({ type: Phaser.CANVAS, parent: 'game', width: LEVEL.width, height: LEVEL.height,
  backgroundColor: '#233d49', scene: CourierScene, banner: false,
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  render: { antialias: true, roundPixels: false }, audio: { noAudio: true } });
