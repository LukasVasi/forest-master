class_name Dragonfly
extends Node3D

@export var speed: float = 6
@export var maxDistance: float = 6.0
@export var minDepth: float = 0.22
var direction: Vector3 = Vector3(1, 0, 0)
var traveledDistance: float = 0.0

func _process(delta: float) -> void:
	translate(direction * speed * delta)

	traveledDistance += abs(speed) * delta

	if traveledDistance >= maxDistance:
		traveledDistance = 0.0
		rotate_object_local(Vector3(0, 1, 0), 55.0)

	if global_transform.origin.y <= minDepth:
		global_transform.origin.y = minDepth
