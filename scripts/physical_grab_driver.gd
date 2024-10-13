class_name PhysicalGrabDriver
extends Node

## Moves a pickable object when it is picked up

## Target pickable
var target : PhysicalPickable

## Primary grab information
var primary_grab : PhysicalGrab = null

## Secondary grab information
var secondary_grab : PhysicalGrab = null

func _init(
	p_grab : PhysicalGrab
) -> void:
	primary_grab = p_grab
	target = primary_grab.what
	process_physics_priority = -80
	primary_grab.set_arrived()


func _physics_process(_delta : float) -> void:
	# TODO: check for arrival and set arridev properly
	var controller := primary_grab.controller
	var destination_transform := controller.global_transform * primary_grab.transform.inverse()
	var destination_origin := destination_transform.origin
	var destination_basis := destination_transform.basis
	
	target.apply_central_force(target.global_transform.origin.direction_to(destination_origin) * minf(primary_grab.hand.hand_movement_force, 2 * target.mass * ProjectSettings.get_setting("physics/3d/default_gravity")))
	
	#target.global_basis = destination_basis
	var quat_target := destination_basis.get_rotation_quaternion()
	var quat_curr := target.global_basis.get_rotation_quaternion()
	var quat_delta := quat_target * (quat_curr.inverse())
	var euler_delta := Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	target.apply_torque(euler_delta * primary_grab.hand.hand_rotation_torque)
	
	#var controller_target := primary_hand._controller as XRController3D
	#var destination := controller_target.global_transform * primary_grab_point.transform.inverse()
	## Move to target
	#var movement_delta: Vector3 = destination.origin - target.global_position
	#target.apply_force(movement_delta * 10, primary_grab_point.global_position - target.global_position)
	#
	## Rotate to target
	#var quat_target: Quaternion = destination.basis.get_rotation_quaternion()
	#var quat_hand: Quaternion = controller_target.global_basis.get_rotation_quaternion()
	#var quat_delta: Quaternion = quat_target * (quat_hand.inverse())
	#var rotation_delta: Vector3 = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	#target.apply_torque(rotation_delta * primary_hand.hand_rotation_torque)
	
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
	queue_free()
