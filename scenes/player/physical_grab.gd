class_name PhysicalGrab

## The Physical Grab Class
##
## This class is the custom physical implementation of XRTools Grab. 
## It encodes information about an active grab. Additionally it applies
## hand poses and collision exceptions as appropriate.

## Priority for grip poses
const GRIP_POSE_PRIORITY := 100

## Priority for grip targeting
const GRIP_TARGET_PRIORITY := 100

## The grabber node (function pickup as Node3D)
var by : Node3D

## The physical pickup associated with the grabber
var function_pickup : PhysicalFunctionPickup

## The controller associated with the grabber
var controller : XRController3D

## The physical hand associated with the grabber
var hand : PhysicalHand

## Grab target
var what : PhysicalPickable

## Hand grab point information
var grab_point : XRToolsGrabPointHand

## Grab transform
var transform : Transform3D

## Has target arrived at grab point
var _arrived : bool = false


## Initialize the grab
func _init(
	p_by : Node3D,
	p_what : PhysicalPickable,
	p_point : XRToolsGrabPointHand
	) -> void:
	
	# TODO: there are now some null checks from the XRTools implementation
	# that might not be necessary as this will break 
	# if one of these things are null
	by = p_by
	function_pickup = p_by as PhysicalFunctionPickup
	controller = function_pickup.get_controller() if function_pickup else null
	hand = function_pickup.hand if function_pickup else null
	
	what = p_what
	grab_point = p_point

	# Calculate the grab transform
	if p_point:
		transform = p_point.transform
	else:
		transform = p_what.global_transform.inverse() * by.global_transform

	# Apply collision exceptions
	if is_instance_valid(hand):
		hand.add_collision_exception_with(what)
		what.add_collision_exception_with(hand)


## Release the grab
func release() -> void:
	# Clear any hand pose
	_clear_hand_pose()

	# Remove collision exceptions
	if is_instance_valid(hand):
		hand.remove_collision_exception_with(what)
		what.remove_collision_exception_with(hand)

	# Report the release
	print_verbose("%s> released by %s", [what.name, by.name])
	what.released.emit(what, by)


## Set the target as arrived at the grab-point
func set_arrived() -> void:
	# Ignore if already arrived
	if _arrived:
		return

	# Set arrived and apply any hand pose
	print_verbose("%s> arrived at %s" % [what.name, grab_point])
	_arrived = true
	_set_hand_pose()

	# Report the grab
	print_verbose("%s> grabbed by %s", [what.name, by.name])
	what.grabbed.emit(what, by)


# Set hand-pose overrides
func _set_hand_pose() -> void:
	# Skip if not hand
	if not is_instance_valid(hand) or not is_instance_valid(grab_point):
		return

	# Apply the hand-pose
	if grab_point.hand_pose:
		hand.add_pose_override(grab_point, GRIP_POSE_PRIORITY, grab_point.hand_pose)

	# Apply hand snapping
	if grab_point.snap_hand:
		hand.add_target_override(grab_point, GRIP_TARGET_PRIORITY)


# Clear any hand-pose overrides
func _clear_hand_pose() -> void:
	# Skip if not hand
	if not is_instance_valid(hand) or not is_instance_valid(grab_point):
		return

	# Remove hand-pose
	hand.remove_pose_override(grab_point)

	# Remove hand snapping
	hand.remove_target_override(grab_point)