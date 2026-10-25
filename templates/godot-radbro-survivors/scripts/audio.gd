# Original procedural sounds and score. MIT license. No external recordings.
extends Node

const SAMPLE_RATE := 22050
const MAX_VOICES := 8
const SFX_VOICES := MAX_VOICES - 1
const CUE_NAMES := ["fire", "hit", "hurt", "pickup", "upgrade", "wave", "win", "loss"]
const THROTTLE := {"fire": 0.065, "hit": 0.09, "hurt": 0.2, "pickup": 0.055, "upgrade": 0.15, "wave": 0.3, "win": 0.3, "loss": 0.3}
const INACTIVE_CUES := ["upgrade", "win", "loss"]
# Each tuple is an authored note sequence, note length, and peak amplitude.
const CUES := {
    "fire": [[880.0, 520.0, 260.0], 0.026, 0.18],
    "hit": [[185.0, 120.0], 0.045, 0.23],
    "hurt": [[233.08, 174.61, 116.54], 0.09, 0.28],
    "pickup": [[659.25, 987.77], 0.065, 0.20],
    "upgrade": [[392.0, 493.88, 587.33, 783.99], 0.11, 0.23],
    "wave": [[196.0, 261.63, 392.0], 0.13, 0.23],
    "win": [[392.0, 493.88, 587.33, 783.99, 987.77, 783.99], 0.14, 0.23],
    "loss": [[293.66, 233.08, 174.61, 146.83], 0.18, 0.24],
}
# A new eight-second phrase. Zero means a rest. This is not a borrowed tune.
const BACKING_NOTES := [60, 0, 67, 0, 63, 0, 70, 0, 67, 0, 63, 0, 62, 0, 0, 0, 65, 0, 72, 0, 68, 0, 65, 0, 63, 0, 67, 0, 62, 0, 0, 0]
const BACKING_BASS := [36, 36, 41, 38]
const BACKING_SECONDS := 8.0

var enabled := true
var round_active := false
var unlocked := false
var initialized := false
var streams: Dictionary = {}
var backing_stream: AudioStreamWAV
var voices: Array[AudioStreamPlayer] = []
var backing: AudioStreamPlayer
var clock := 0.0
var backing_clock := 0.0
var last_play: Dictionary = {}
var requested: Dictionary = {}
var played: Dictionary = {}
var blocked := 0
var throttled := 0
var capacity_drops := 0
var unknown := 0
var stolen := 0
var restarts := 0
var peak_voices := 0
var _voice_order: Array[int] = []
var _serial := 0

func _ready() -> void:
    setup()

func _exit_tree() -> void:
    for voice in voices:
        voice.stop()
        voice.stream = null
    if backing != null:
        backing.stop()
        backing.stream = null
    streams.clear()
    backing_stream = null

func setup() -> void:
    if initialized:
        return
    initialized = true
    for kind in CUE_NAMES:
        streams[kind] = _synthesize_cue(kind)
        requested[kind] = 0
        played[kind] = 0
    backing_stream = _synthesize_backing()
    for index in SFX_VOICES:
        var voice := AudioStreamPlayer.new()
        voice.name = "Cue%d" % index
        voice.volume_db = -7.0
        voice.max_polyphony = 1
        voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        add_child(voice)
        voices.append(voice)
        _voice_order.append(0)
    backing = AudioStreamPlayer.new()
    backing.name = "Backing"
    backing.stream = backing_stream
    backing.volume_db = -21.0
    backing.max_polyphony = 1
    backing.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    add_child(backing)

func _process(delta: float) -> void:
    # Only scalar work occurs each frame. Synthesis happens once in setup.
    clock += delta
    if round_active and enabled and unlocked:
        backing_clock = fmod(backing_clock + delta, BACKING_SECONDS)

func play_event(kind: String) -> bool:
    if not initialized:
        return false
    if not streams.has(kind):
        unknown += 1
        return false
    requested[kind] += 1
    if not enabled or not unlocked or (not round_active and kind not in INACTIVE_CUES):
        blocked += 1
        return false
    if clock - float(last_play.get(kind, -1000.0)) < float(THROTTLE[kind]):
        throttled += 1
        return false
    var slot := -1
    for index in voices.size():
        if not voices[index].playing:
            slot = index
            break
    if slot < 0:
        if kind in ["hurt", "upgrade", "wave", "win", "loss"]:
            slot = 0
            for index in _voice_order.size():
                if _voice_order[index] < _voice_order[slot]:
                    slot = index
            voices[slot].stop()
            stolen += 1
        else:
            capacity_drops += 1
            return false
    var voice := voices[slot]
    voice.stream = streams[kind]
    voice.play()
    _serial += 1
    _voice_order[slot] = _serial
    last_play[kind] = clock
    played[kind] += 1
    peak_voices = maxi(peak_voices, _active_voice_count())
    return true

func set_enabled(value: bool) -> void:
    if enabled == value:
        return
    enabled = value
    if not initialized:
        return
    if not enabled:
        _stop_cues()
    _sync_backing()

func set_round_active(value: bool) -> void:
    if round_active == value:
        return
    round_active = value
    # Call true only from the game's explicit Start or Resume action.
    if value:
        unlocked = true
    if not initialized:
        return
    if not value:
        _stop_cues()
    _sync_backing()

func restart() -> void:
    round_active = false
    backing_clock = 0.0
    last_play.clear()
    restarts += 1
    if initialized:
        _stop_cues()
        backing.stop()
        backing.stream_paused = false
    # Keep lifetime counters, user unlock, and the user's mute choice.

func _stop_cues() -> void:
    for voice in voices:
        voice.stop()

func _sync_backing() -> void:
    if round_active and enabled and unlocked:
        if not backing.playing:
            backing.play()
        backing.stream_paused = false
        peak_voices = maxi(peak_voices, _active_voice_count())
    else:
        backing.stream_paused = true

func _active_voice_count() -> int:
    var count := 0
    for voice in voices:
        if voice.playing and not voice.stream_paused:
            count += 1
    if backing != null and backing.playing and not backing.stream_paused:
        count += 1
    return count

func snapshot() -> Dictionary:
    return {"enabled": enabled, "unlocked": unlocked, "round_active": round_active,
        "driver": AudioServer.get_driver_name(), "voice_limit": MAX_VOICES,
        "active_voices": _active_voice_count(), "peak_voices": peak_voices,
        "backing_playing": backing != null and backing.playing and not backing.stream_paused,
        "backing_clock": snappedf(backing_clock, 0.001), "requested": requested.duplicate(),
        "played": played.duplicate(), "blocked": blocked, "throttled": throttled,
        "capacity_drops": capacity_drops, "stolen": stolen, "unknown": unknown, "restarts": restarts}

func _wav(data: PackedByteArray) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = SAMPLE_RATE
    stream.stereo = false
    stream.data = data
    return stream

func _synthesize_cue(kind: String) -> AudioStreamWAV:
    var score: Array = CUES[kind]
    var notes: Array = score[0]
    var note_length: float = score[1]
    var duration := note_length * notes.size()
    var frames := int(round(duration * SAMPLE_RATE))
    var pcm := PackedByteArray()
    pcm.resize(frames * 2)
    var phase := 0.0
    for index in frames:
        var time := float(index) / SAMPLE_RATE
        var note := mini(int(time / note_length), notes.size() - 1)
        var local_time := fmod(time, note_length)
        var envelope := minf(local_time / 0.004, (note_length - local_time) / 0.012)
        envelope = clampf(envelope, 0.0, 1.0) * exp(-2.4 * local_time / note_length)
        var frequency: float = notes[note]
        phase += TAU * frequency / SAMPLE_RATE
        var tone := (sin(phase) + 0.2 * sin(phase * 2.0)) / 1.2
        var sample := tone * envelope * float(score[2])
        if index == frames - 1:
            sample = 0.0
        pcm.encode_s16(index * 2, int(round(sample * 32767.0)))
    return _wav(pcm)

func _synthesize_backing() -> AudioStreamWAV:
    var frames := int(BACKING_SECONDS * SAMPLE_RATE)
    var pcm := PackedByteArray()
    pcm.resize(frames * 2)
    var lead_phase := 0.0
    var bass_phase := 0.0
    for index in frames:
        var time := float(index) / SAMPLE_RATE
        var step := mini(int(time / 0.25), BACKING_NOTES.size() - 1)
        var local_time := fmod(time, 0.25)
        var note: int = BACKING_NOTES[step]
        var bass_note: int = BACKING_BASS[int(time / 2.0)]
        var lead_frequency := 440.0 * pow(2.0, (note - 69) / 12.0)
        var bass_frequency := 440.0 * pow(2.0, (bass_note - 69) / 12.0)
        lead_phase += TAU * lead_frequency / SAMPLE_RATE
        bass_phase += TAU * bass_frequency / SAMPLE_RATE
        var lead_envelope := clampf(minf(local_time / 0.008, (0.25 - local_time) / 0.06), 0.0, 1.0)
        var bass_time := fmod(time, 0.5)
        var bass_envelope := clampf(minf(bass_time / 0.01, (0.5 - bass_time) / 0.08), 0.0, 1.0)
        var sample := sin(bass_phase) * bass_envelope * 0.09
        if note > 0:
            sample += sin(lead_phase) * lead_envelope * 0.055
        var edge := clampf(minf(time / 0.01, (BACKING_SECONDS - time) / 0.01), 0.0, 1.0)
        if index == frames - 1:
            edge = 0.0
        pcm.encode_s16(index * 2, int(round(sample * edge * 32767.0)))
    var stream := _wav(pcm)
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = frames
    return stream
