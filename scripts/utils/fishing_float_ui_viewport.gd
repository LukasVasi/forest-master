@tool
class_name FishingFloatUIViewport
extends "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.gd"

var _fishing_float: Node3D

var _player: Node3D

func _ready() -> void:
	super()
	
	if not Engine.is_editor_hint():
		_fishing_float = get_tree().get_first_node_in_group("fishing_rod").get_node("FishingFloat")
		_player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Move the viewport above the float and turn it at the player
	if is_instance_valid(_fishing_float) and visible:
		var float_location := _fishing_float.global_position
		global_position = Vector3(float_location.x, float_location.y + 2, float_location.z)
		look_at(_player.global_position)
