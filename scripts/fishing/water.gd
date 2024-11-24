class_name Water
extends Area3D

@onready var _fishing_manager: FishingManager = get_tree().get_first_node_in_group("fishing")

## Handles objects' entry into the water. 
func _on_water_entered(body: Node3D) -> void:
	if body is FishingFloat and is_instance_valid(_fishing_manager):
		_fishing_manager._start_fishing()
	
	if body.has_method("on_water_entered"):
		body.on_water_entered(global_position.y)


## Handles objects' exit from the water.
func _on_water_exited(body: Node3D) -> void:
	if body is FishingFloat and is_instance_valid(_fishing_manager):
		_fishing_manager._finish_fishing()
	
	if body.has_method("on_water_exited"):
		body.on_water_exited()
