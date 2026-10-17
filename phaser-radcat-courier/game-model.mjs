// World coordinates use the top-left origin. X points right. Y points down.
// Change this data to make a new level. Keep each cell outside all walls.
export const LEVEL = {
  width: 960, height: 600, timeLimit: 90, speed: 230, radius: 17,
  spawn: { x: 120, y: 476 }, gate: { x: 120, y: 476, radius: 48 },
  walls: [
    { x: 302, y: 318, w: 64, h: 204 },
    { x: 554, y: 112, w: 64, h: 232 },
    { x: 716, y: 436, w: 144, h: 52 },
  ],
  cells: [{ x: 208, y: 166 }, { x: 440, y: 146 }, { x: 464, y: 440 },
    { x: 766, y: 170 }, { x: 826, y: 354 }],
  hazards: [{ x: 430, y: 290, travel: 65, speed: 1.6 },
    { x: 750, y: 340, travel: 70, speed: 1.2 }],
};
export const STEP = 1 / 60;

export function createGame(level = LEVEL) {
  return { mode: 'ready', player: { ...level.spawn }, cells: level.cells.map(c => ({ ...c, collected: false })),
    elapsed: 0, remaining: level.timeLimit, lives: 3, hop: 0, hopCooldown: 0,
    immune: 0, moving: false, facing: 1, previousHop: false, accumulator: 0 };
}
export function startGame(state) { if (state.mode === 'ready') state.mode = 'playing'; }
export function togglePause(state) {
  if (state.mode === 'playing') state.mode = 'paused';
  else if (state.mode === 'paused') state.mode = 'playing';
}
export function hazardPositions(state, level = LEVEL) {
  return level.hazards.map(h => ({ x: h.x + Math.sin(state.elapsed * h.speed) * h.travel, y: h.y, radius: 23 }));
}
export function circleHitsRect(x, y, radius, rect) {
  const nearestX = Math.max(rect.x, Math.min(x, rect.x + rect.w));
  const nearestY = Math.max(rect.y, Math.min(y, rect.y + rect.h));
  return Math.hypot(x - nearestX, y - nearestY) < radius;
}
function blocked(x, y, level) {
  return x < level.radius + 32 || x > level.width - level.radius - 32
    || y < level.radius + 72 || y > level.height - level.radius - 32
    || level.walls.some(w => circleHitsRect(x, y, level.radius, w));
}
export function tick(state, input = {}, dt = STEP, level = LEVEL) {
  if (state.mode !== 'playing') return;
  state.elapsed += dt;
  state.remaining = Math.max(0, level.timeLimit - state.elapsed);
  state.hop = Math.max(0, state.hop - dt);
  state.hopCooldown = Math.max(0, state.hopCooldown - dt);
  state.immune = Math.max(0, state.immune - dt);
  if (input.hop && !state.previousHop && state.hopCooldown === 0) {
    state.hop = 0.98; state.hopCooldown = 1.2;
  }
  state.previousHop = Boolean(input.hop);
  let dx = Number(Boolean(input.right)) - Number(Boolean(input.left));
  let dy = Number(Boolean(input.down)) - Number(Boolean(input.up));
  const length = Math.hypot(dx, dy) || 1;
  dx = dx / length * level.speed * dt;
  dy = dy / length * level.speed * dt;
  state.moving = Boolean(dx || dy);
  if (dx) state.facing = Math.sign(dx);
  if (!blocked(state.player.x + dx, state.player.y, level)) state.player.x += dx;
  if (!blocked(state.player.x, state.player.y + dy, level)) state.player.y += dy;
  for (const cell of state.cells) {
    if (!cell.collected && Math.hypot(state.player.x - cell.x, state.player.y - cell.y) < 35) cell.collected = true;
  }
  if (!state.hop && !state.immune && hazardPositions(state, level).some(h =>
    Math.hypot(state.player.x - h.x, state.player.y - h.y) < h.radius + level.radius)) {
    state.lives -= 1; state.player = { ...level.spawn }; state.immune = 1.5;
  }
  if (state.lives <= 0 || state.remaining === 0) state.mode = 'lost';
  else if (state.cells.every(c => c.collected) && Math.hypot(state.player.x - level.gate.x,
    state.player.y - level.gate.y) < level.gate.radius) state.mode = 'won';
}
// Both the browser loop and the test hook use this same fixed-step simulation.
export function advance(state, input, milliseconds, level = LEVEL) {
  if (!Number.isFinite(milliseconds) || milliseconds < 0) throw new RangeError('Time must be finite and positive.');
  if (state.mode !== 'playing') return;
  state.accumulator += milliseconds / 1000;
  while (state.accumulator + 1e-10 >= STEP && state.mode === 'playing') {
    tick(state, input, STEP, level); state.accumulator -= STEP;
  }
}
export function snapshot(state, level = LEVEL) {
  return { coordinates: 'top-left origin; x right; y down', mode: state.mode,
    player: { x: +state.player.x.toFixed(2), y: +state.player.y.toFixed(2), radius: level.radius,
      hop: +state.hop.toFixed(2), immune: +state.immune.toFixed(2) },
    cells: state.cells.filter(c => !c.collected).map(({ x, y }) => ({ x, y })),
    collected: state.cells.filter(c => c.collected).length, total: state.cells.length,
    gate: level.gate, walls: level.walls, hazards: hazardPositions(state, level),
    lives: state.lives, remaining: +state.remaining.toFixed(2) };
}
