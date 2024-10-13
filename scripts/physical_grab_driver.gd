class_name PhysicalGrabDriver
extends Node

## Moves a pickable object when it is picked up

## Target pickable
var target : PhysicalPickable

## Primary grab point information
var primary_grab_point : XRToolsGrabPointHand = null

## Primary physical hand
var primary_hand : PhysicalHand = null

## Secondary grab point information
var secondary_grab_point : XRToolsGrabPointHand = null

## Secondary physical hand
var secondary_hand : PhysicalHand = null

func _init(
	p_target : PhysicalPickable,
	p_physical_hand : PhysicalHand, 
	p_grab_point : XRToolsGrabPointHand
) -> void:
	target = p_target
	process_physics_priority = -80
	
	# TODO: remove
	#target.freeze = true
	
	p_physical_hand.add_collision_exception_with(target)
	p_physical_hand.add_target_override(p_grab_point, 0)
	
	primary_grab_point = p_grab_point
	primary_hand = p_physical_hand

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta : float) -> void:
	var controller := primary_hand._controller
	var destination_transform := controller.global_transform * primary_grab_point.transform.inverse()
	var destination_origin := destination_transform.origin
	var destination_basis := destination_transform.basis
	
	target.apply_central_force(target.global_transform.origin.direction_to(destination_origin) * minf(primary_hand.hand_movement_force, 2 * target.mass * ProjectSettings.get_setting("physics/3d/default_gravity")))
	
	#target.global_basis = destination_basis
	var quat_target := destination_basis.get_rotation_quaternion()
	var quat_curr := target.global_basis.get_rotation_quaternion()
	var quat_delta := quat_target * (quat_curr.inverse())
	var euler_delta := Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	target.apply_torque(euler_delta * primary_hand.hand_rotation_torque)
	
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
func add_grab(
	p_physical_hand : PhysicalHand, 
	p_grab_point : XRToolsGrabPointHand
	) -> void:
	# Set the secondary grab
	p_physical_hand.add_collision_exception_with(target)
	p_physical_hand.add_target_override(p_grab_point, 0)
	if p_grab_point.mode and p_grab_point.mode == XRToolsGrabPointHand.Mode.PRIMARY:
		print_verbose("%s> new primary grab by %s" % [target.name, p_physical_hand.by.name])
		secondary_grab_point = primary_grab_point
		secondary_hand = primary_hand
		
		primary_grab_point = p_grab_point
		primary_hand = p_physical_hand
	else:
		print_verbose("%s> new secondary grab %s" % [target.name, p_physical_hand.by.name])
		secondary_grab_point = p_grab_point
		secondary_hand = p_physical_hand


func remove_grab(p_grab_point : XRToolsGrabPointHand) -> void:
	# Remove the appropriate grab
	if p_grab_point == primary_grab_point:
		# Remove primary (secondary promoted)
		primary_hand.remove_collision_exception_with(target)
		primary_hand.remove_target_override(primary_grab_point)
		
		primary_grab_point = secondary_grab_point
		primary_hand = secondary_hand
		
		secondary_grab_point = null
		secondary_hand = null
	elif p_grab_point == secondary_grab_point:
		# Remove secondary
		secondary_hand.remove_collision_exception_with(target)
		secondary_hand.remove_target_override(secondary_grab_point)
		
		secondary_grab_point = null
		secondary_hand = null


func discard() -> void:
	if secondary_grab_point:
		remove_grab(secondary_grab_point)
	if primary_grab_point:
		remove_grab(primary_grab_point)
	# TODO: remove
	#target.freeze = false
	queue_free()
