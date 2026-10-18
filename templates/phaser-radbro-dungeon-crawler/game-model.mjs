// Adapted from Ourcade's MIT Faune, Lizard, Chest, and Game classes.
// See UPSTREAM.json and upstream/source for the pinned original implementation.
export const RULES = Object.freeze({ speed: 100, enemySpeed: 50, knifeSpeed: 300, maxKnives: 3, radius: 6, damageGrace: 1.1 });
const distance = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
const vectors = [[0, -1], [0, 1], [-1, 0], [1, 0]];

export function makeLevel(map) {
  const ground = map.layers.find(layer => layer.name === 'Ground');
  const walls = map.layers.find(layer => layer.name === 'Walls');
  const tileset = map.tilesets[0];
  const solids = new Set(tileset.tiles.filter(tile => tile.properties?.some(p => p.name === 'collides' && p.value)).map(tile => tile.id + tileset.firstgid));
  const objects = name => map.layers.find(layer => layer.name === name).objects.map(item => ({ x: item.x + item.width / 2, y: item.y - item.height / 2 }));
  return { map, ground, walls, solids, tileSize: map.tilewidth, columns: map.width, width: 688, height: 448,
    spawn: { x: 128, y: 128 }, chests: objects('Chests'), enemies: objects('Lizards') };
}
export function createGame(level) {
  return { mode: 'ready', level, elapsed: 0, rng: 726, health: 3, coins: 0, immune: 0, moving: false,
    facing: { x: 1, y: 0 }, visualFacing: 1, cooldown: 0, knockback: { x: 0, y: 0, time: 0 },
    player: { ...level.spawn }, chests: level.chests.map((p, i) => ({ ...p, id: i, opened: false })),
    enemies: level.enemies.map((p, i) => ({ ...p, id: i, alive: true, direction: i % 4, turnIn: 2 })), knives: [], accumulator: 0 };
}
export function startGame(state) { if (state.mode === 'ready') state.mode = 'playing'; }
export function togglePause(state) {
  if (state.mode === 'playing') state.mode = 'paused';
  else if (state.mode === 'paused') state.mode = 'playing';
}
function random(state) { state.rng = (Math.imul(state.rng, 1664525) + 1013904223) >>> 0; return state.rng / 4294967296; }
function changeDirection(state, enemy) { enemy.direction = (enemy.direction + 1 + Math.floor(random(state) * 3)) % 4; enemy.turnIn = 2; }
export function isOpen(level, x, y, radius = RULES.radius) {
  for (const dx of [-radius, radius]) for (const dy of [-radius, radius]) {
    const cx = Math.floor((x + dx) / level.tileSize), cy = Math.floor((y + dy) / level.tileSize);
    if (cx < 0 || cy < 0 || cx >= level.columns || cy >= level.map.height) return false;
    const index = cy * level.columns + cx;
    if (!level.ground.data[index] || level.solids.has(level.walls.data[index])) return false;
  }
  return true;
}
function move(state, actor, dx, dy, chests = false) {
  const allowed = (x, y) => isOpen(state.level, x, y) && (!chests || !state.chests.some(c => Math.abs(c.x - x) < 12 && Math.abs(c.y - y) < 12));
  let blocked = false;
  if (allowed(actor.x + dx, actor.y)) actor.x += dx; else if (dx) blocked = true;
  if (allowed(actor.x, actor.y + dy)) actor.y += dy; else if (dy) blocked = true;
  return blocked;
}
export function nearChest(state) { return state.chests.find(chest => !chest.opened && distance(state.player, chest) < 28); }
export function attack(state) {
  if (state.mode !== 'playing' || state.cooldown > 0 || state.knockback.time > 0) return;
  const chest = nearChest(state);
  if (chest) { chest.opened = true; state.coins += 50 + Math.floor(random(state) * 151); state.cooldown = .25; return; }
  if (state.knives.length >= RULES.maxKnives) return;
  const { x, y } = state.facing;
  state.knives.push({ x: state.player.x + x * 12, y: state.player.y + y * 12, vx: x * RULES.knifeSpeed, vy: y * RULES.knifeSpeed, life: 1.5 });
  state.cooldown = .25;
}
function step(state, input, dt) {
  if (state.mode !== 'playing') return;
  state.elapsed += dt;
  state.immune = Math.max(0, state.immune - dt);
  state.cooldown = Math.max(0, state.cooldown - dt);
  state.moving = false;
  // The source selects one cardinal direction. A last direction also controls throws.
  let dx = input.left ? -1 : input.right ? 1 : 0;
  let dy = dx ? 0 : input.up ? -1 : input.down ? 1 : 0;
  if (state.knockback.time > 0) {
    state.knockback.time -= dt;
    move(state, state.player, state.knockback.x * dt, state.knockback.y * dt, true);
  } else {
    if (dx || dy) { state.facing = { x: dx, y: dy }; state.moving = true; if (dx) state.visualFacing = dx; }
    move(state, state.player, dx * RULES.speed * dt, dy * RULES.speed * dt, true);
    if (input.attack) attack(state);
  }
  for (const enemy of state.enemies) {
    if (!enemy.alive) continue;
    enemy.turnIn -= dt;
    if (enemy.turnIn <= 0) changeDirection(state, enemy);
    const [ex, ey] = vectors[enemy.direction];
    if (move(state, enemy, ex * RULES.enemySpeed * dt, ey * RULES.enemySpeed * dt)) changeDirection(state, enemy);
  }
  state.knives = state.knives.filter(knife => {
    knife.x += knife.vx * dt; knife.y += knife.vy * dt; knife.life -= dt;
    if (knife.life <= 0 || !isOpen(state.level, knife.x, knife.y, 1)) return false;
    const target = state.enemies.find(enemy => enemy.alive && distance(knife, enemy) < 11);
    if (target) { target.alive = false; return false; }
    return true;
  });
  const enemy = state.enemies.find(e => e.alive && distance(e, state.player) < 13);
  if (enemy && state.immune <= 0) {
    state.health -= 1; state.immune = RULES.damageGrace;
    const length = distance(state.player, enemy) || 1;
    state.knockback = { x: (state.player.x - enemy.x) / length * 200, y: (state.player.y - enemy.y) / length * 200, time: .15 };
    if (state.health <= 0) { state.mode = 'lost'; state.moving = false; }
  }
  if (state.mode === 'playing' && state.enemies.every(e => !e.alive) && state.chests.every(c => c.opened) && distance(state.player, state.level.spawn) < 20) {
    state.mode = 'won'; state.moving = false;
  }
}
export function advance(state, input, milliseconds) {
  if (state.mode !== 'playing' || !Number.isFinite(milliseconds) || milliseconds < 0) return;
  // Fixed steps preserve knife, wall, and enemy collision at high and low frame rates.
  state.accumulator += Math.min(milliseconds, 30000) / 1000;
  while (state.accumulator + 1e-12 >= 1 / 120) { step(state, input, 1 / 120); state.accumulator -= 1 / 120; }
}
export function snapshot(state) {
  const rounded = actor => ({ x: +actor.x.toFixed(2), y: +actor.y.toFixed(2) });
  return { coordinates: 'World pixels. Origin at top left. X increases right. Y increases down. Tiles are 16 pixels.',
    mode: state.mode, player: { ...rounded(state.player), facing: state.facing, moving: state.moving }, health: state.health,
    coins: state.coins, elapsed: +state.elapsed.toFixed(2), immune: +state.immune.toFixed(2),
    chests: state.chests.map(c => ({ id: c.id, ...rounded(c), opened: c.opened })),
    enemies: state.enemies.filter(e => e.alive).map(e => ({ id: e.id, ...rounded(e) })),
    knives: state.knives.map(rounded), exit: { ...state.level.spawn, unlocked: state.enemies.every(e => !e.alive) && state.chests.every(c => c.opened) },
    interaction: nearChest(state) ? 'Attack opens the nearby chest.' : 'Attack throws a knife in the last movement direction.' };
}
