# Bounded, deterministic feedback. These events never change combat or consume RNG.
extends Node2D
const MAX_EVENTS := 64
var events: Array[Dictionary] = []
var active := false
var art_style := "radcat"
var elapsed := 0.0
var serial := 0
var event_counts: Dictionary = {}

func set_art_style(style: String) -> void:
    art_style = style
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if style == "native" else CanvasItem.TEXTURE_FILTER_LINEAR
    queue_redraw()

func emit_effect(kind: String, location: Vector2, angle: float = 0.0) -> void:
    if art_style not in ["native", "illustrated"]:
        return
    if events.size() >= MAX_EVENTS:
        events.pop_front()
    serial += 1
    event_counts[kind] = int(event_counts.get(kind, 0)) + 1
    events.append({"id": serial, "kind": kind, "position": location, "angle": angle, "age": 0.0, "duration": 0.18 if kind == "muzzle" else 0.52 if kind in ["defeat", "upgrade"] else 0.34})
    queue_redraw()

func clear() -> void:
    events.clear()
    elapsed = 0.0
    serial = 0
    event_counts.clear()
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not active:
        return
    elapsed += delta
    for index in range(events.size() - 1, -1, -1):
        events[index].age += delta
        if events[index].age >= events[index].duration:
            events.remove_at(index)
    queue_redraw()

func snapshot() -> Dictionary:
    var kinds: Dictionary = {}
    for event in events:
        kinds[event.kind] = int(kinds.get(event.kind, 0)) + 1
    var emitted: Dictionary = {}
    for kind in ["muzzle", "hit", "defeat", "pickup", "upgrade"]:
        emitted[kind] = int(event_counts.get(kind, 0))
    return {"style": art_style, "count": events.size(), "limit": MAX_EVENTS, "clock": snappedf(elapsed, 0.001), "kinds": kinds, "emitted": emitted, "events": events.map(func(event): return {"id": event.id, "kind": event.kind, "age": snappedf(event.age, 0.001)})}

func _draw() -> void:
    for event in events:
        var progress: float = event.age / event.duration
        var fade := 1.0 - progress
        var point: Vector2 = event.position
        var color := Color("81f3d0") if event.kind in ["pickup", "upgrade"] else Color("f7db8c")
        color.a = fade
        if art_style == "native":
            var count := 8 if event.kind in ["defeat", "upgrade"] else 4
            var radius := (5.0 + progress * 20.0) if event.kind != "muzzle" else 4.0 + progress * 9.0
            for index in count:
                var angle: float = event.angle + index * TAU / count
                var offset := Vector2.RIGHT.rotated(angle) * radius
                var square := 3.0 if event.kind != "muzzle" else 2.0
                draw_rect(Rect2((point + offset).round() - Vector2.ONE * square / 2.0, Vector2.ONE * square), color)
            if event.kind == "hit":
                draw_line(point + Vector2(-5, -5) * fade, point + Vector2(5, 5) * fade, color, 2)
                draw_line(point + Vector2(-5, 5) * fade, point + Vector2(5, -5) * fade, color, 2)
        elif art_style == "illustrated":
            var radius := 4.0 + progress * (26.0 if event.kind in ["defeat", "upgrade"] else 15.0)
            draw_circle(point, radius * 0.9, Color(color, fade * 0.08))
            draw_circle(point, radius * 0.6, Color(color, fade * 0.12))
            if event.kind == "muzzle":
                draw_circle(point, 4.0 * fade, Color("fff2ca"))
                draw_line(point - Vector2.RIGHT.rotated(event.angle) * 3, point + Vector2.RIGHT.rotated(event.angle) * radius, color, 2, true)
            else:
                draw_arc(point, radius, -PI * 0.8 + progress, PI * 0.8 + progress, 20, Color(color, fade * 0.6), 1.5, true)
                for index in 3:
                    var angle: float = event.id * 0.3 + index * TAU / 3.0
                    var start := point + Vector2.RIGHT.rotated(angle) * radius * 0.4
                    var finish := point + Vector2.RIGHT.rotated(angle + 0.25) * radius
                    draw_line(start, finish, Color(color, fade * 0.55), 2.0 * fade, true)
