class_name Dragonfly
extends Node3D

@export var speed = 6
@export var maxDistance = 6.0
@export var minDepth = 0.22
var direction = Vector3(1, 0, 0)
var traveledDistance = 0.0

func _process(delta):
	translate(direction * speed * delta)

	traveledDistance += abs(speed) * delta

	if traveledDistance >= maxDistance:
		traveledDistance = 0.0
		rotate_object_local(Vector3(0, 1, 0), 55.0)

	if global_transform.origin.y <= minDepth:
		global_transform.origin.y = minDepth
