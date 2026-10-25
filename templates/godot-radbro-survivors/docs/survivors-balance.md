# Survivors prototype balance

The prototype lasts 90 seconds. It has three 30-second waves.
Edit `scripts/balance.gd` to change its baseline values.
The profile stores no round state.

The saved browser round ended with 122 kills, six upgrades, and 100 health.
It followed a broad circuit and selected each upgrade type in turn.
That result shows a low-pressure route. It does not measure all player skill levels.
See the local evidence at `evidence/survivors-full-look/final/outcome.json`.

## Profile

| Value | Previous | Current |
| --- | --- | --- |
| Player health / speed | 100 / 180 | 100 / 180 |
| Contact damage per enemy per second | 14 | 14 |
| Gun target range | 440 | 320 |
| Initial shot interval | 0.45 seconds | 0.50 seconds |
| Enemy health / elite health | 2 / 4 | 2 / 4 |
| First-wave spawn interval | 1.05 to 0.84 seconds | 0.95 to 0.78 seconds |
| Second-wave spawn interval | 0.84 to 0.63 seconds | 0.68 to 0.53 seconds |
| Third-wave spawn interval | 0.63 to 0.42 seconds | 0.46 to 0.34 seconds |
| First-wave enemy speed | 45 to 56.4 | 58 to 70 |
| Second-wave enemy speed | 56.4 to 67.8 | 78 to 94 |
| Third-wave enemy speed | 67.8 to 79.2 | 98 to 112 |
| Elite chance by wave | 0 / 24% / 24% | 0 / 14% / 25% |
| Live enemy cap / elite cap | 70 / no separate cap | 70 / 6 |

Elites move 10% faster. Their speed cannot exceed 124.
Enemies remain slower than the starting player.
Shorter gun range lets enemies enter more of the arena before they die.
The stage changes make the wave number affect play.
The elite cap limits random clusters. It does not remove normal enemy pressure.
Upgrade effects, XP thresholds, controls, and game states stay the same.

## Verification

Run from the repository root:

```sh
python3 scripts/prepare.py godot-radbro-survivors
/Applications/Godot.app/Contents/MacOS/Godot --headless --path templates/godot-radbro-survivors --editor --import --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path templates/godot-radbro-survivors --fixed-fps 60 --script tests/balance.gd
```

The test loads the real main scene. It uses real input actions, live enemies,
projectiles, contact damage, XP pickup, upgrades, and the round clock.
It checks fixed seeds 7, 42, and 314159 with two policies.
The idle policy does not move. The circuit policy moves between four fixed points
and selects rapid fire, power, and speed/heal in turn.
The checks require at least one idle loss and one moving win.
They also check wave boundaries, hard caps, restart values, and a repeated seed.

These are bot fixtures. They check feasible outcomes and regressions.
They do not prove that the difficulty is final or fun.
Browser frame timing, touch play, first-time players, art readability, and human
upgrade choices still need a fresh play test after integration.

## Engine fixture results, 2026-10-25

Godot 4.6.2 passed all 26 checks. Seven seeded rounds completed.
The repeated seed 7 circuit produced the same result.
The forced spawn check reached 70 enemies and respected the six-elite cap.
The final log has no engine errors or warnings.
Audio stayed enabled with the headless Dummy driver.
The test gives the audio thread 150 milliseconds to release WAV playback before exit.

| Seed | Idle result | Circuit and upgrade result | Circuit kills | Circuit upgrades |
| --- | --- | --- | --- | --- |
| 7 | Lost at 23.22 seconds | Won at 90.02 seconds; 79.9 health | 146 | 7 |
| 42 | Lost at 83.78 seconds | Won at 90.02 seconds; 93.7 health | 151 | 7 |
| 314159 | Lost at 31.35 seconds | Won at 90.02 seconds; 90.7 health | 149 | 7 |

Before integration, the same three circuit bots all won with 100 health.
They had 124 to 126 kills. The new profile adds contact pressure while the route
remains viable. No further profile change was made after these results.
The local log is `evidence/survivors-release/balance.log`.
