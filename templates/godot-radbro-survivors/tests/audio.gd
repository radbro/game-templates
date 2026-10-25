extends SceneTree
## PCM and state proof. A dummy audio driver does not prove audible browser output.
const AudioNode = preload("res://scripts/audio.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)
        push_error(label)

func check_pcm(stream: AudioStreamWAV, label: String, seconds: float) -> void:
    check(stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo, label + " is mono signed 16-bit PCM")
    check(stream.mix_rate == 22050, label + " has the authored sample rate")
    var pcm := stream.data
    check(pcm.size() > 0 and pcm.size() % 2 == 0, label + " has complete sample frames")
    check(absf(stream.get_length() - seconds) < 0.001, label + " has the authored duration")
    var peak := 0
    var energy := 0.0
    var biggest_step := 0
    var previous := 0
    for index in pcm.size() / 2:
        var value := pcm.decode_s16(index * 2)
        peak = maxi(peak, absi(value))
        energy += float(value) * value
        biggest_step = maxi(biggest_step, absi(value - previous))
        previous = value
    check(peak > 1000 and peak < 12000, label + " is non-silent and leaves mixing headroom")
    check(is_finite(energy) and sqrt(energy / (pcm.size() / 2)) > 30, label + " has finite non-silent PCM energy")
    check(biggest_step < 5000, label + " avoids abrupt full-scale sample edges")
    check(pcm.decode_s16(0) == 0 and pcm.decode_s16(pcm.size() - 2) == 0, label + " starts and ends at zero")

func run() -> void:
    var audio := AudioNode.new()
    root.add_child(audio)
    audio.set_process(false)
    check(audio.initialized and audio.get_child_count() == 8, "Setup creates one fixed eight-player pool")
    audio.setup()
    check(audio.get_child_count() == 8, "Setup is idempotent")
    var bytes := 0
    for kind in AudioNode.CUE_NAMES:
        var spec: Array = AudioNode.CUES[kind]
        var stream: AudioStreamWAV = audio.streams[kind]
        check_pcm(stream, kind, float(spec[1]) * spec[0].size())
        check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, kind + " is a one-shot")
        bytes += stream.data.size()
    check_pcm(audio.backing_stream, "backing", 8.0)
    bytes += audio.backing_stream.data.size()
    check(bytes < 600000, "All generated PCM stays below 600 KB")
    check(audio.backing_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and audio.backing_stream.loop_end == 176400, "Backing loops over the complete authored phrase")
    var second := AudioNode.new()
    root.add_child(second)
    second.set_process(false)
    for kind in AudioNode.CUE_NAMES:
        check(second.streams[kind].data == audio.streams[kind].data, kind + " synthesis is deterministic")
    check(second.backing_stream.data == audio.backing_stream.data, "Backing synthesis is deterministic")
    second.free()
    check(audio.snapshot().active_voices == 0 and not audio.unlocked, "Ready state has no audio before Start")
    check(not audio.play_event("fire"), "Pre-Start events are blocked")
    check(audio.requested.fire == 1 and audio.played.fire == 0, "Requested events differ from actual plays")
    audio.set_enabled(false)
    audio.set_round_active(true)
    check(audio.unlocked and not audio.snapshot().backing_playing, "Starting while muted stays silent")
    check(not audio.play_event("hurt"), "Muted events are blocked")
    audio.set_enabled(true)
    check(audio.snapshot().backing_playing, "Unmute starts backing only after Start")
    check(audio.play_event("fire"), "Active fire plays")
    check(not audio.play_event("fire") and audio.throttled == 1, "Repeated fire is throttled")
    check(audio.play_event("hit") and not audio.play_event("hit"), "Repeated hit is throttled")
    check(audio.play_event("pickup") and not audio.play_event("pickup"), "Repeated pickup is throttled")
    for kind in ["hurt", "upgrade", "wave", "win", "loss"]:
        check(audio.play_event(kind), kind + " has an actual playback path")
    check(audio.snapshot().active_voices == 8 and audio.peak_voices == 8, "The backing and cue pool never exceed eight voices")
    check(audio.stolen == 1, "A high-priority cue replaces the oldest voice at capacity")
    audio._process(0.1)
    check(not audio.play_event("fire") and audio.capacity_drops == 1, "Low-priority fire drops when the fixed pool is full")
    audio._process(0.2)
    await create_timer(0.05).timeout
    var before_pause: float = audio.backing_clock
    audio.set_round_active(false)
    audio._process(0.5)
    check(audio.backing_clock == before_pause and audio.snapshot().active_voices == 0, "Pause stops cues and freezes backing")
    check(audio.backing.stream_paused, "Pause freezes the engine backing stream")
    check(not audio.play_event("hit"), "Combat events are blocked during pause")
    check(audio.play_event("upgrade"), "The upgrade cue can play while backing is frozen")
    audio.set_round_active(false)
    check(audio.snapshot().active_voices == 1, "Repeated inactive state does not cut off an outcome or upgrade cue")
    await create_timer(0.05).timeout
    audio.set_enabled(false)
    check(audio.snapshot().active_voices == 0, "Mute stops active cue voices immediately")
    audio._process(0.5)
    check(audio.backing_clock == before_pause, "Mute does not advance backing telemetry")
    audio.set_enabled(true)
    check(not audio.snapshot().backing_playing, "Unmute during pause does not resume backing")
    audio.set_round_active(true)
    audio._process(0.25)
    check(audio.backing_clock > before_pause and audio.snapshot().backing_playing, "Resume continues backing")
    audio.set_round_active(false)
    check(audio.play_event("win"), "Win cue plays after the round stops")
    audio._process(0.4)
    check(audio.play_event("loss"), "Loss cue plays after the round stops")
    await create_timer(0.05).timeout
    var requested_before: Dictionary = audio.requested.duplicate()
    var played_before: Dictionary = audio.played.duplicate()
    audio.set_enabled(false)
    audio.restart()
    check(not audio.enabled and not audio.round_active and audio.backing_clock == 0.0, "Restart preserves mute and resets round playback")
    check(audio.snapshot().active_voices == 0 and not audio.backing.playing, "Restart stops every engine player")
    check(audio.requested == requested_before and audio.played == played_before, "Restart preserves lifetime telemetry")
    check(audio.last_play.is_empty(), "Restart clears event throttles")
    audio.set_enabled(true)
    check(audio.snapshot().active_voices == 0, "Restart does not play before the next Start")
    audio.set_round_active(true)
    check(audio.play_event("fire"), "The next round starts without a stale throttle")
    check(not audio.play_event("not-a-cue") and audio.unknown == 1, "Unknown events are rejected")
    var source := FileAccess.get_file_as_string("res://scripts/audio.gd")
    check(not source.contains("randf(") and not source.contains("randi(") and not source.contains("randomize(") and not source.contains("RandomNumberGenerator"), "Synthesis does not access gameplay randomness")
    check(not source.contains("FileAccess") and not source.contains("HTTPRequest"), "Audio does not load recordings or network data")
    print("SURVIVORS_AUDIO ", "PASS" if failures.is_empty() else failures, " pcm_bytes=", bytes, " driver=", AudioServer.get_driver_name())
    await create_timer(0.05).timeout
    audio.set_enabled(false)
    audio.free()
    # Fixed-fps fixtures can finish before a real mixer cycle has elapsed.
    OS.delay_msec(150)
    await process_frame
    quit(0 if failures.is_empty() else 1)
