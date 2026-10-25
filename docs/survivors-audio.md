# Survivors procedural audio

`scripts/audio.gd` contains original synthesis code, sound effects, and a short original backing phrase. It uses the root MIT license. It has no downloaded samples, new dependencies, file reads, or network requests.

The node generates 483,252 bytes of mono signed 16-bit PCM at 22,050 Hz. It generates the data once in `setup()`. The eight-second backing phrase loops. A short attack and release envelope shapes each note. The PCM starts and ends at zero.

## Integration

Create the node once. Add it to the scene tree. `_ready()` calls the idempotent `setup()` method.

```gdscript
const AudioNode = preload("res://scripts/audio.gd")
var sound = AudioNode.new()
add_child(sound)
```

Call `sound.set_round_active(true)` from the explicit Start action. This unlocks sound. It starts the backing phrase only if sound is enabled. Do not call it at initial page load.

Call `sound.play_event(kind)` for these events:

| Kind | Trigger |
| --- | --- |
| `fire` | A projectile fires |
| `hit` | A projectile hits an enemy |
| `hurt` | The player takes damage |
| `pickup` | The player collects XP |
| `upgrade` | The upgrade screen opens or a choice completes |
| `wave` | A new enemy wave starts |
| `win` | The round ends with a win |
| `loss` | The round ends with a loss |

Use the cue once for each trigger. `play_event()` returns true only when it starts an engine voice. Fire, hit, and pickup have short throttles. Other cues also have a guard against duplicate calls.

Call `sound.set_round_active(false)` when the game enters pause, upgrade, win, or loss. It stops current sound effects. It freezes the backing stream. Call the terminal or upgrade cue after this state change. Those three cues can play while the round is inactive. Repeating the same state does not cut them off.

Call `sound.set_round_active(true)` on Resume or after the upgrade choice. The backing stream continues. Call `sound.set_enabled(false)` to mute. Mute stops active effects and freezes backing. Unmute does not resume backing while the round remains inactive.

Call `sound.restart()` before the next round starts. It stops playback, resets the backing position, and clears event throttles. It preserves the mute choice, user unlock, and lifetime telemetry. Call `set_round_active(true)` when that next round starts.

## Bounds and telemetry

The pool contains seven effect players and one backing player. Each player has a polyphony limit of one. Total active voices cannot exceed eight. A high-priority cue can replace the oldest effect at capacity. A low-priority cue drops when the pool is full.

`sound.snapshot()` returns the mute and round state, driver, voice limit, current voice count, peak voice count, backing state, and counters. `requested` counts recognized event requests. `played` counts calls accepted by an engine player. `blocked`, `throttled`, and `capacity_drops` explain rejected requests. `stolen` counts effect replacements. `unknown` counts invalid names.

`backing_clock` is local playback telemetry. It freezes during pause and mute. It is not a sample-accurate measurement of the hardware output. None of these values changes gameplay or consumes gameplay randomness.

## Verification

Run from the template folder:

```sh
godot --headless --script tests/audio.gd
```

The test checks duration, sample rate, mono format, finite non-silent PCM energy, amplitude headroom, sample edges, deterministic bytes, loop bounds, and memory size. It also checks pre-Start silence, voice limits, throttling, pause, mute, restart, and counters.

The headless test uses Godot's Dummy driver. It proves PCM and node state. A browser check must separately prove user-gesture unlock, graph output, mute, and pause behavior. Physical speaker output needs a listening check.

## Browser device limit on this machine

Chromium's default audio device stalls in both headed and headless runs. A plain oscillator also stalls. The AudioContext reports running, but its clock stays at zero. The game works with the browser-supported silent output sink. This test setting runs the real audio graph without sending sound to a physical device.

Use the explicit test option only when needed:

```sh
AUDIO_TEST_SINK=none node templates/godot-radbro-survivors/tests/release-browser.mjs
```

The test records the sink in `checks.json`. It measures nonzero PCM after Start, zero output during mute and pause, restored output on unmute, and a defeat cue after backing stops. `tests/browser-audio.mjs` supplies the opt-in browser constructor setting. The game itself uses the normal output device. Physical speaker audibility remains unverified.
