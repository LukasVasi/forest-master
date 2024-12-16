@tool
extends "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.gd"

@onready var _player_camera : Node3D = get_tree().get_first_node_in_group("player").get_node("XRCamera3D")
@onready var _skillet : Node3D = get_node("../")

func update() -> void:
	if not Engine.is_editor_hint():
		global_position = _skillet.global_position + Vector3.UP * 0.38
		look_at(_player_camera.global_position, Vector3.UP, true)
