@tool
class_name FishingFloatUIViewport
extends "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.gd"

## Position the ui above the fishing float and rotate it towards the player.
func update(fish_direction: FishingManager.FishDirection, tension_ratio: float, float_position : Vector3, player_position : Vector3) -> void:
	scene_node.direction = fish_direction
	scene_node.tension_ratio = tension_ratio
	global_position = Vector3(float_position.x, player_position.y + 1.5, float_position.z)
	
	# Rotate towards the player but only on the Y axis
	player_position.y = global_position.y
	look_at(player_position, Vector3.UP, true)
