extends GPUParticles3D

## Move a top level particle to parent. Basically to ignore rotation.

@onready var parent : Node3D = get_node("../")

func _ready() -> void:
	top_level = true

func _process(_delta: float) -> void:
	global_position = parent.global_position
