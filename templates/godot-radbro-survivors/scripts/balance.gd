extends RefCounted
## Edit this profile to tune the 90-second prototype. It stores no round state.

const ROUND_SECONDS := 90.0
const WAVE_SECONDS := 30.0
const PLAYER_SPEED := 180.0
const PLAYER_HEALTH := 100.0
const CONTACT_DPS := 14.0
const GUN_RANGE := 320.0
const GUN_INTERVAL := 0.50
const GUN_DAMAGE := 1
const MAX_MOBS := 70
const MAX_ELITES := 6
const NORMAL_HEALTH := 2
const ELITE_HEALTH := 4
const MAX_ENEMY_SPEED := 124.0

# Each pair gives the start and end values within one 30-second wave.
const SPAWN_INTERVALS := [Vector2(0.95, 0.78), Vector2(0.68, 0.53), Vector2(0.46, 0.34)]
const ENEMY_SPEEDS := [Vector2(58.0, 70.0), Vector2(78.0, 94.0), Vector2(98.0, 112.0)]
const ELITE_CHANCES := [0.0, 0.14, 0.25]

static func wave_number(elapsed: float) -> int:
    return clampi(int(maxf(0.0, elapsed) / WAVE_SECONDS) + 1, 1, 3)

static func _wave_progress(elapsed: float) -> float:
    var start := float(wave_number(elapsed) - 1) * WAVE_SECONDS
    return clampf((elapsed - start) / WAVE_SECONDS, 0.0, 1.0)

static func spawn_interval(elapsed: float) -> float:
    var pair: Vector2 = SPAWN_INTERVALS[wave_number(elapsed) - 1]
    return lerpf(pair.x, pair.y, _wave_progress(elapsed))

static func enemy_speed(elapsed: float, elite: bool = false) -> float:
    var pair: Vector2 = ENEMY_SPEEDS[wave_number(elapsed) - 1]
    var speed := lerpf(pair.x, pair.y, _wave_progress(elapsed))
    return minf(MAX_ENEMY_SPEED, speed * (1.10 if elite else 1.0))

static func elite_chance(elapsed: float) -> float:
    return ELITE_CHANCES[wave_number(elapsed) - 1]

static func enemy_health(elite: bool = false) -> int:
    return ELITE_HEALTH if elite else NORMAL_HEALTH

static func xp_threshold(level: int) -> int:
    return maxi(1, level) * 4
