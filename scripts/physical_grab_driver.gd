class_name PhysicalGrabDriver
extends Node

## Moves a pickable object when it is picked up

## Target pickable
var target : PhysicalPickableV2

## Primary grab information
var primary_grab : PhysicalGrab = null

## Secondary grab information
var secondary_grab : PhysicalGrab = null

var _original_linear_damp : float

var _original_angular_damp : float

var _target_inertia : Vector3

func _init(
	p_grab : PhysicalGrab
) -> void:
	primary_grab = p_grab
	target = primary_grab.what
	
	_original_linear_damp = target.linear_damp
	_original_angular_damp = target.angular_damp
	#_update_damp()
	
	_target_inertia = PhysicsServer3D.body_get_direct_state(target.get_rid()).inverse_inertia.inverse()
	print(_target_inertia)
	
	process_physics_priority = -80
	primary_grab.set_arrived()


#func _physics_process(_delta : float) -> void:
	## TODO: check for arrival and set arrived properly
	#
	#
	#var primary_movement_force : Vector3
	#var primary_rotation_torque : Vector3
	#
	#var secondary_movement_force : Vector3
	#var secondary_rotation_torque : Vector3
	#
	#
	#var controller := primary_grab.controller
	#var destination_transform := controller.global_transform * primary_grab.transform.inverse()
	#
	#var movement_direction := target.global_position.direction_to(destination_transform.origin)
	#var movement_factor : float = min((destination_transform.origin - target.global_position).length(), 2)
	#primary_movement_force = movement_direction * movement_factor * primary_grab.hand.hand_movement_force
#
	#var grab_point_pos := primary_grab.transform.origin
	#var object_center := target.global_position
	#var radii := (grab_point_pos - object_center).abs()
#
	#var quat_target := destination_transform.basis.get_rotation_quaternion()
	#var quat_curr := target.global_basis.get_rotation_quaternion()
	#var quat_delta := quat_target * (quat_curr.inverse())
	#var euler_delta := Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	#
	## Account for the radius differences on each axis
	#if radii.x > 0: euler_delta.x /= radii.x
	#if radii.y > 0: euler_delta.y /= radii.y
	#if radii.z > 0: euler_delta.z /= radii.z
	#
	#primary_rotation_torque = 1 * euler_delta * primary_grab.hand.hand_rotation_torque
	#
	#if secondary_grab:
		#controller = secondary_grab.controller
		#destination_transform = controller.global_transform * secondary_grab.transform.inverse()
		#movement_direction = target.global_position.direction_to(destination_transform.origin)
		#movement_factor = min((destination_transform.origin - target.global_position).length(), 2)
		#secondary_movement_force = movement_direction * movement_factor * secondary_grab.hand.hand_movement_force
#
		#quat_target = destination_transform.basis.get_rotation_quaternion()
		#quat_curr = target.global_basis.get_rotation_quaternion()
		#quat_delta = quat_target * (quat_curr.inverse())
		#euler_delta = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
		#
		## Torque needs to be halfed because summing up just makes it freak out
		#secondary_rotation_torque = (euler_delta * secondary_grab.hand.hand_rotation_torque) / 2
		#primary_rotation_torque /= 2
	#
	#target.apply_central_force(primary_movement_force + secondary_movement_force)
	#target.apply_torque(_target_inertia * (primary_rotation_torque + secondary_rotation_torque))
	#
	## Force the transform update at this moment
	#target.force_update_transform()


## Set the secondary grab point
func add_grab(p_grab : PhysicalGrab) -> void:
	# Set the secondary grab
	if p_grab.grab_point.mode and p_grab.grab_point.mode == XRToolsGrabPointHand.Mode.PRIMARY:
		print_verbose("%s> new primary grab by %s" % [target.name, p_grab.by.name])
		secondary_grab = primary_grab
		primary_grab = p_grab
		primary_grab.set_arrived()
		#_update_damp()
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
	#_update_damp()
	queue_free()


# TODO: improve this?
## Used for a hacky way to match the picked up object's behaviour to the hand.
## Sets the object's damping to values of the priamry hand.
#func _update_damp() -> void:
	#if primary_grab:
		#target.linear_damp = primary_grab.hand.linear_damp
		#target.angular_damp = primary_grab.hand.angular_damp
	#else:
		#target.linear_damp = _original_linear_damp
		#target.angular_damp = _original_angular_damp
