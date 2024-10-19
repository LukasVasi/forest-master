class_name PhysicalFollower
extends RigidBody3D

## Uses forces to move and rotate this [RigidBody3D] towards 
## a desired transform expressed by a [Node3D]

# TODO: decide on physics process priority

@export var movement_force : float = 1.0

@export var rotation_torque : float = 1.0

var target : Node3D

var _inertia : Vector3

func _ready() -> void:
	# Retrieve the inertia of the follower for use in torque calculations
	_inertia = PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia.inverse()


func _physics_process(_delta: float) -> void:
	# Move to target
	var movement_delta: Vector3 = target.global_position - global_position
	apply_central_force(movement_delta * movement_force)
	
	# Rotate to target
	var quat_target: Quaternion = target.global_basis.get_rotation_quaternion()
	var quat_hand: Quaternion = global_basis.get_rotation_quaternion()
	var quat_delta: Quaternion = quat_target * (quat_hand.inverse())
	var rotation_delta: Vector3 = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	apply_torque(rotation_delta * rotation_torque)

	# Force the transform update at this moment
	force_update_transform()
