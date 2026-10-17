extends Node3D
## Display one named part of the shared playground import.
@export_enum("ground_tile", "gate", "barrier", "energy_pickup", "beacon", "tree", "rock", "platform", "flag") var piece := "ground_tile"
const KIT = preload("res://assets/radcat-playground/radcat-playground.glb")

func _ready() -> void:
    var source := KIT.instantiate()
    var part := source.find_child(piece, true, false)
    if part != null:
        add_child(part.duplicate())
    source.free()
