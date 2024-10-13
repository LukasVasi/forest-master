class_name PhysicalGrabDriver
extends Node

## Moves a pickable object when it is picked up

## Target pickable
var target : PhysicalPickable

## Primary grab information
var primary_grab : PhysicalGrab = null

## Secondary grab information
var secondary_grab : PhysicalGrab = null

var _original_linear_damp : float

var _original_angular_damp : float

func _init(
	p_grab : PhysicalGrab
) -> void:
	primary_grab = p_grab
	target = primary_grab.what
	
	_original_linear_damp = target.linear_damp
	_original_angular_damp = target.angular_damp
	_update_damp()
	
	process_physics_priority = -80
	primary_grab.set_arrived()


func _physics_process(_delta : float) -> void:
	# TODO: check for arrival and set arrived properly
	
	
	var primary_movement_force : Vector3
	var primary_rotation_torque : Vector3
	
	var secondary_movement_force : Vector3
	var secondary_rotation_torque : Vector3
	
	
	var controller := primary_grab.controller
	var destination_transform := controller.global_transform * primary_grab.transform.inverse()
	var movement_delta := destination_transform.origin - target.global_position
	primary_movement_force = movement_delta * primary_grab.hand.hand_movement_force

	var quat_target := destination_transform.basis.get_rotation_quaternion()
	var quat_curr := target.global_basis.get_rotation_quaternion()
	var quat_delta := quat_target * (quat_curr.inverse())
	var euler_delta := Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	primary_rotation_torque = euler_delta * primary_grab.hand.hand_rotation_torque
	
	if secondary_grab:
		controller = primary_grab.controller
		destination_transform = controller.global_transform * primary_grab.transform.inverse()
		movement_delta = destination_transform.origin - target.global_position
		secondary_movement_force = movement_delta * primary_grab.hand.hand_movement_force

		quat_target = destination_transform.basis.get_rotation_quaternion()
		quat_curr = target.global_basis.get_rotation_quaternion()
		quat_delta = quat_target * (quat_curr.inverse())
		euler_delta = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
		
		# Torque needs to be halfed because summing up just makes it freak out
		secondary_rotation_torque = (euler_delta * primary_grab.hand.hand_rotation_torque) / 2
		primary_rotation_torque /= 2
	
	target.apply_central_force(primary_movement_force + secondary_movement_force)
	target.apply_torque(primary_rotation_torque + secondary_rotation_torque)
	
	# Force the transform update at this moment
	target.force_update_transform()


## Set the secondary grab point
func add_grab(p_grab : PhysicalGrab) -> void:
	# Set the secondary grab
	if p_grab.grab_point.mode and p_grab.grab_point.mode == XRToolsGrabPointHand.Mode.PRIMARY:
		print_verbose("%s> new primary grab by %s" % [target.name, p_grab.by.name])
		secondary_grab = primary_grab
		primary_grab = p_grab
		primary_grab.set_arrived()
		_update_damp()
	else:
		print_verbose("%s> new secondary grab %s" % [target.name, p_grab.by.name])
		secondary_grab = p_grab
		secondary_grab.set_arrived()


func remove_grab(p_grab : PhysicalGrab) -> void:
	# Remove the appropriate grab
	if p_grab == primary_grab:
		# Remove primary (secondary promoted)
		primary_grab = secondary_grab
		secondary_grab = null
	elif p_grab == secondary_grab:
		# Remove secondary
		secondary_grab = null


## Get the grab information for the grab node
func get_grab(by : Node3D) -> PhysicalGrab:
	if primary_grab and primary_grab.by == by:
		return primary_grab

	if secondary_grab and secondary_grab.by == by:
		return secondary_grab

	return null


func discard() -> void:
	if secondary_grab:
		remove_grab(secondary_grab)
	if primary_grab:
		remove_grab(primary_grab)
	_update_damp()
	queue_free()


# TODO: imporve this?
## Used for a hacky way to match the picked up object's behaviour to the hand.
## Sets the object's damping to values of the priamry hand.
func _update_damp() -> void:
	if primary_grab:
		target.linear_damp = primary_grab.hand.linear_damp
		target.angular_damp = primary_grab.hand.angular_damp
	else:
		target.linear_damp = _original_linear_damp
		target.angular_damp = _original_angular_damp
