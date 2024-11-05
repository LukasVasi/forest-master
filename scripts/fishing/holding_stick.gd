extends Node3D

func _ready() -> void:
	$PhysicalSnapZone.initial_object = get_tree().get_first_node_in_group("fishing_rod").get_path()
