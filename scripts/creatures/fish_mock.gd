extends RigidBody3D

@onready var water : MeshInstance3D = get_node("/root/Staging/Scene/Main/Water")

var speed = 1.5
var maxDistance = 7.0
var minDepth = -2
var direction = Vector3(1, 0, 0)
var traveledDistance = 0.0

func _process(delta):

	translate(direction * speed * delta)

	traveledDistance += abs(speed) * delta

	if traveledDistance >= maxDistance:
		traveledDistance = 0.0
		rotation_degrees.y += 180.0

	if global_transform.origin.y <= minDepth:
		global_transform.origin.y = minDepth
		
	if global_position.y >= water.global_position.y:
		global_position.y = water.global_position.y
