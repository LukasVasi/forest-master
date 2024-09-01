class_name CreatureMovement
extends PathFollow3D

@export var movement_speed: float = 1.0

func _ready() -> void:
	# Place at a random spot along the path
	var random_ratio: float = randf_range(0.0, 1.0)
	progress_ratio = random_ratio


func _process(delta: float) -> void:
	progress += delta * movement_speed
