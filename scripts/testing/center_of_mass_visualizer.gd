extends MeshInstance3D

@onready var pickable : RigidBody3D = get_node("../")

func _process(_delta: float) -> void:
	position = pickable.center_of_mass
