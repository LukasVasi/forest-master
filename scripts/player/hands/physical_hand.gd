@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name PhysicalHand
extends RigidBody3D

## The Physical Hand script
##
## Actual real hand that uses force to try and follow the controller. Can interact with the world.

## Signal emitted when the pickup picks something up
signal has_picked_up(what: PhysicalPickable)

## Signal emitted when the pickup drops something
signal has_dropped

## Signal emitted when the hand is reset
signal hand_reset(hand: Node3D)


# Default pickup collision mask of 3:pickable and 19:handle
const DEFAULT_GRAB_MASK := 0b0000_0000_0000_0100_0000_0000_0000_0100

# Constant for worst-case grab distance
const MAX_GRAB_DISTANCE2: float = 1000000.0


## The main properties of the physical hand

@export var ghost_hand : GhostHand

## The max distance that the hand can depart from the controller before being teleported.
@export var max_distance_to_controller : float = 0.8

## Name of the Trigger action in the OpenXR Action Map. Used for posing.
@export var trigger_action : String = "trigger"

## Name of the trigger clicking action. Used for actions when picked up.
@export var trigger_click_action : String = "trigger_click"

## Name of the Grip action in the OpenXR Action Map. Used for picking up and posing.
@export var grip_action : String = "grip"

@export var grab_joint: Generic6DOFJoint3D # Joint is holding objects


## PID controller default values are tuned for subjective feeling of realistic hand physics
## These values have biggest influence on how hand feels and behaves
@export_group("PID Controller Linear")
@export var Kp_linear: float = 800
@export var Ki_linear: float = 0
@export var Kd_linear: float = 80
@export var proportional_limit_linear: float = INF
@export var integral_limit_linear: float = INF
@export var derivative_limit_linear: float = INF


@export_group("PID Controller Angular")
@export var Kp_angular: float = 5
@export var Ki_angular: float = 0
@export var Kd_angular: float = 1
@export var proportional_limit_angular: float = INF
@export var integral_limit_angular: float = INF
@export var derivative_limit_angular: float = INF


@export_group("Rumble feedback")

## The distance from the controller at which a haptic feedback is provided. 
@export var distance_to_rumble : float = 0.3

## The maximum rumble magnitude that will be used at max distance.
@export_range(0.0, 1.0) var max_rumble_magnitude : float = 0.2

## The rumble event used to provide rumble feedback when the hand gets too far.
@export var rumble_event : XRToolsRumbleEvent

## Rumble trackers that are used to process and emit the feedback (right or left hand).
@export var rumble_trackers : Array[StringName]


@export_group("Hand visuals")

## Blend tree to use
@export var hand_blend_tree : AnimationNodeBlendTree: set = set_hand_blend_tree

## Default hand pose
@export var default_pose : XRToolsHandPoseSettings: set = set_default_pose

## Override the hand material
@export var hand_material_override : Material: set = set_hand_material_override


@export_group("Function pickup")

## Grip threshold (from configuration)
@onready var _grip_threshold : float = XRTools.get_grip_threshold()

## Grab collision mask. Defines the collision layers used in detecting pickable objects.
@export_flags_3d_physics \
		var grab_collision_mask : int = DEFAULT_GRAB_MASK: set = _set_grab_collision_mask

## The minimum grab distance. Defines the radius of the collision sphere 
## which detects pickable objects when the hand at normal height.
@export var min_grab_distance : float = 0.2: set = _set_min_grab_distance

## The maximum grab distance. Defines the radius of the collision sphere 
## which detects pickable objects when the hand is near the floor.
@export var max_grab_distance : float = 0.4: set = _set_max_grab_distance

## The player body that this hand is attached to. Used to alter the grab distance
## based on the hands position relative to the player body's origin.
@export var player_body : PlayerBody


var pid_controller_linear: PIDController
var pid_controller_angular: PIDController

var previous_controller_position: Vector3
var controller_velocity: Vector3

var distance_to_controller: float = 0.0

## Controller used for input/tracking
var _controller : XRController3D

## Hand mesh
var _hand_mesh : MeshInstance3D

## Hand animation player
var _animation_player : AnimationPlayer

## Hand animation tree
var _animation_tree : AnimationTree

## Animation blend tree
var _tree_root : AnimationNodeBlendTree

## Sorted stack of PoseOverride
var _pose_overrides := []

## Force grip value (< 0 for no force)
var _force_grip := -1.0

## Force trigger value (< 0 for no force)
var _force_trigger := -1.0

# Sorted stack of TargetOverride
var _target_overrides := []

# Current target (controller or override)
var _target : Node3D

var _rumbling : bool = false


var grip_pressed : bool = false
var closest_object : Node3D = null
var picked_up_object : PhysicalPickable = null

var _grab_area : Area3D
var _grab_collision : CollisionShape3D

var _objects_in_grab_area := Array()


# Add support for is_xr_class on XRTools classes
func is_xr_class(p_name : String) -> bool:
	return p_name == "XRToolsPhysicsHand" or p_name == "XRToolsHand"


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	# Disconnect from parent transform as we move to it in the physics step,
	# and boost the physics priority after any grab-drivers but before other
	# processing.
	top_level = true
	process_physics_priority = -70
	
	# Setup the pid controllers used to simulate smooth physical movement
	pid_controller_linear = PIDController.new({
		Kp = Kp_linear,
		Ki = Ki_linear,
		Kd = Kd_linear,
		proportional_limit = proportional_limit_linear,
		integral_limit = integral_limit_linear,
		derivative_limit = derivative_limit_linear
	})
	pid_controller_angular = PIDController.new({
		Kp = Kp_angular,
		Ki = Ki_angular,
		Kd = Kd_angular,
		proportional_limit = proportional_limit_angular,
		integral_limit = integral_limit_angular,
		derivative_limit = derivative_limit_angular
	})
	
	# Minimal inertia is required for controllable hand rotation
	set_inertia(Vector3(0.01, 0.01, 0.01))
	
	# Find our controller
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")
	_controller.button_pressed.connect(_on_button_pressed)

	# Find the relevant hand nodes
	_hand_mesh = _find_child(self, "MeshInstance3D")
	_animation_player = _find_child(self, "AnimationPlayer")
	_animation_tree = _find_child(self, "AnimationTree")
	
	# Create the grab collision shape for the grab area
	_grab_collision = CollisionShape3D.new()
	_grab_collision.set_name("GrabCollisionShape")
	_grab_collision.shape = SphereShape3D.new()
	_grab_collision.shape.radius = min_grab_distance

	# Create the grab area
	_grab_area = Area3D.new()
	_grab_area.set_name("GrabArea")
	_grab_area.collision_layer = 0
	_grab_area.collision_mask = grab_collision_mask
	_grab_area.add_child(_grab_collision)
	_grab_area.area_entered.connect(_on_grab_entered)
	_grab_area.body_entered.connect(_on_grab_entered)
	_grab_area.area_exited.connect(_on_grab_exited)
	_grab_area.body_exited.connect(_on_grab_exited)
	add_child(_grab_area)
	
	# Apply all updates
	_update_colliders()
	_update_hand_blend_tree()
	_update_hand_material_override()
	_update_pose()
	_update_target()
	_reset_hand()


func _reset_hand() -> void:
	drop_object()
	freeze = true
	global_transform = _controller.global_transform
	freeze = false
	_reset_pid_controllers()
	hand_reset.emit(self)


## This method  reads the grip and trigger action values to animate the hand.
## And then it applies the necessary forces to move the hand towards its target.
func _physics_process(delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return
	
	# Animate the hand mesh with the controller inputs
	if _controller:
		_animate_hand_with_controller_inputs()
	
	_update_closest_object()
	
	# Handle our grip
	var grip_value := _controller.get_float(grip_action)
	if (grip_pressed and grip_value < (_grip_threshold - 0.1)):
		grip_pressed = false
		_on_grip_release()
	elif (!grip_pressed and grip_value > (_grip_threshold + 0.1)):
		grip_pressed = true
		_on_grip_pressed()
	
	distance_to_controller = _controller.global_position.distance_to(global_position)
	
	_process_rumbling()
	
	# Check distance to hand
	if distance_to_controller > max_distance_to_controller:
		# Physics hand can be bugged or stuck so it needs to reset itself automatically
		# when it is too far away from the controller but only when controller isn't in an object.
		if is_instance_valid(ghost_hand):
			if ghost_hand.can_teleport_to():
				_reset_hand() # if we have ghost hand, reset only when able
		else:
			_reset_hand()
	
	if get_tree().paused and is_instance_valid(picked_up_object):
		drop_object()
	
	_move(delta)
	
	# Calculate controller hand velocity
	# NOTE: XR Kit implementation calculated it relative to player but I doubt I need that
	# because I set the physical hands as a top level child so player's movemnts aren't propagated to them
	#controller_skeleton_velocity = (controller_skeleton.global_transform.origin - %Origin.global_transform.origin - previous_controller_skeleton_position) / delta
	#previous_controller_skeleton_position = controller_skeleton.global_transform.origin - %Origin.global_transform.origin
	controller_velocity = (_controller.global_position - previous_controller_position) / delta
	previous_controller_position = _controller.global_position
	
	# Force the transform update at this moment
	force_update_transform()
	
	_update_colliders()


func _process_rumbling() -> void:
	if distance_to_controller > distance_to_rumble:
		if not _rumbling:
			_rumbling = true
			RumbleManager.add(self, rumble_event, rumble_trackers)
		var rumble_magnitude: float = max_rumble_magnitude * (distance_to_controller - distance_to_rumble)  / (max_distance_to_controller - distance_to_rumble) 
		rumble_event.magnitude = rumble_magnitude
	elif distance_to_controller < distance_to_rumble and _rumbling:
		_rumbling = false
		RumbleManager.remove(self, rumble_trackers)


func _animate_hand_with_controller_inputs() -> void:
	var grip : float = _controller.get_float(grip_action)
	var trigger : float = _controller.get_float(trigger_action)

	# Allow overriding of grip and trigger
	if _force_grip >= 0.0: grip = _force_grip
	if _force_trigger >= 0.0: trigger = _force_trigger

	$AnimationTree.set("parameters/Grip/blend_amount", grip)
	$AnimationTree.set("parameters/Trigger/blend_amount", trigger)


func _move(delta: float) -> void:
	# Target is the controller
	var target := _controller.global_transform
	
	if not get_tree().paused:
		var linear_acceleration: Vector3 = pid_controller_linear.calculate(target.origin, global_transform.origin, delta)
		var angular_acceleration: Vector3 = pid_controller_angular.calculate((target.basis * global_transform.basis.inverse()).get_euler(), Vector3.ZERO, delta)
		
		# TODO: use quaternions for rotation calculation 
		#var quat_target: Quaternion = _target.global_basis.get_rotation_quaternion()
		#var quat_hand: Quaternion = global_basis.get_rotation_quaternion()
		#var quat_delta: Quaternion = quat_target * (quat_hand.inverse())
		#var rotation_delta: Vector3 = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
		
		# Desired acceleration needs to be multiplied by mass to get the desired torque
		apply_central_force(linear_acceleration * mass)
		
		# TODO: this should also probably account for inertia, but a certain value is 
		# always set in stone at the moment, so doesn't really matter
		apply_torque(angular_acceleration)
	else:
		global_transform = target
		_reset_pid_controllers()


func _reset_pid_controllers() -> void:
	pid_controller_linear.integral = Vector3.ZERO
	pid_controller_linear.previous_error = Vector3.ZERO
	pid_controller_angular.integral = Vector3.ZERO
	pid_controller_angular.previous_error = Vector3.ZERO


# TODO: fix the center of mass issue with heavy objects:
# when the center of mass of a really heavy object is set to the grab point, 
# they sometimes fall over
# TODO: change the types to represent actual used types not just Node3D
func _pick_up_object(target: Node3D) -> void:
	# Skip if target null or freed
	if not is_instance_valid(target):
		return
	
	# Check if already holding an object
	if is_instance_valid(picked_up_object):
		# Skip if holding the target object
		if picked_up_object == target:
			return
		# Holding something else? drop it
		drop_object()
	
	var pickable_target : PhysicalPickable
	
	if target is PhysicalPickable:
		pickable_target = target
	elif target is PickableDispenser:
		pickable_target = target.get_dispensable(self)
	elif target is PhysicalSnapZone:
		pickable_target = target.picked_up_object
		target.drop_object()
	
	# Check if target was acquired, fail if not
	if not is_instance_valid(pickable_target):
		return
	
	var grab : PhysicalGrab = pickable_target.pick_up(self)
	
	# Check if succeded in picking up, fail if not
	if not is_instance_valid(grab):
		return
	
	# Pick up our target
	picked_up_object = pickable_target
	
	var grab_point := grab.grab_point
	
	# TODO: move smoothly
	# Teleport to grab point
	freeze = true
	global_transform = grab_point.global_transform
	freeze = false
	
	grab.set_arrived()
	
	# Set joint between hand and grabbed object
	grab_joint.set_node_a(get_path())
	grab_joint.set_node_b(picked_up_object.get_path())
	
	# If grabbing a static object, we let physical hand rotate freely on the surface of the object
	#if picked_up_object.is_class("StaticBody3D"):
	#	grab_joint.set_flag_y(grab_joint.FLAG_ENABLE_ANGULAR_LIMIT, false) # FLAG_ENABLE_ANGULAR_LIMIT = 1
	
	grab_joint.set_flag_y(grab_joint.FLAG_ENABLE_ANGULAR_LIMIT, true) # FLAG_ENABLE_ANGULAR_LIMIT = 1
	
	# If object picked up then emit signal
	if is_instance_valid(picked_up_object):
		picked_up_object.request_highlight(self, false)
		has_picked_up.emit(picked_up_object)


# TODO: Compare objects in grab_area for controller and physics hand and only if they match, grab this object - ???
# TODO: highlight color based on object mass
## Drop the currently held object
func drop_object() -> void:
	if not is_instance_valid(picked_up_object):
		return
	
	# Let go of the current held object
	picked_up_object.let_go(self)
	
	# Reset the grab joint
	grab_joint.set_node_a("")
	grab_joint.set_node_b("")
	
	picked_up_object = null
	has_dropped.emit()


## Get the [XRController3D] driving this pickup.
func get_controller() -> XRController3D:
	return _controller


func _on_grip_pressed() -> void:
	#if not is_instance_valid(held_object):
		#grab()
	if is_instance_valid(picked_up_object) and !picked_up_object.press_to_hold:
		drop_object()
	elif is_instance_valid(closest_object):
		_pick_up_object(closest_object)


func _on_grip_release() -> void:
	if is_instance_valid(picked_up_object) and picked_up_object.press_to_hold:
		drop_object()


func _on_button_pressed(p_button: String) -> void:
	if p_button == trigger_click_action:
		if is_instance_valid(picked_up_object) and picked_up_object.has_method("action"):
			picked_up_object.action()


func _on_button_released(p_button: String) -> void:
	if p_button == trigger_click_action:
		if is_instance_valid(picked_up_object) and picked_up_object.has_method("action_release"):
			picked_up_object.action_release()


# This method verifies the hand has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check hand for mesh instance
	if not _find_child(self, "MeshInstance3D"):
		warnings.append("Hand does not have a MeshInstance3D")

	# Check hand for animation player
	if not _find_child(self, "AnimationPlayer"):
		warnings.append("Hand does not have a AnimationPlayer")

	# Check hand for animation tree
	var tree : AnimationTree = _find_child(self, "AnimationTree")
	if not tree:
		warnings.append("Hand does not have a AnimationTree")
	elif not tree.tree_root:
		warnings.append("Hand AnimationTree has no root")

	# Return warnings
	return warnings


## Find an [XRToolsHand] node.
##
## This function searches from the specified node for an [XRToolsHand] assuming
## the node is a sibling of the hand under an [XROrigin3D].
static func find_instance(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## This function searches from the specified node for the left controller
## [XRToolsHand] assuming the node is a sibling of the [XROrigin3D].
static func find_left(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## This function searches from the specified node for the right controller
## [XRToolsHand] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node : Node) -> XRToolsHand:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"XRToolsHand") as XRToolsHand


## Set the blend tree
func set_hand_blend_tree(blend_tree : AnimationNodeBlendTree) -> void:
	hand_blend_tree = blend_tree
	if is_inside_tree():
		_update_hand_blend_tree()
		_update_pose()


## Set the hand material override
func set_hand_material_override(material : Material) -> void:
	hand_material_override = material
	if is_inside_tree():
		_update_hand_material_override()


## Set the default open-hand pose
func set_default_pose(pose : XRToolsHandPoseSettings) -> void:
	default_pose = pose
	if is_inside_tree():
		_update_pose()


## Add a pose override
func add_pose_override(who : Node, priority : int, settings : XRToolsHandPoseSettings) -> void:
	# Remove any existing pose override from this source
	var modified := _remove_pose_override(who)

	# Insert the pose override
	if settings:
		_insert_pose_override(who, priority, settings)
		modified = true

	# Update the pose
	if modified:
		_update_pose()


## Remove a pose override
func remove_pose_override(who : Node) -> void:
	# Remove the pose override
	var modified := _remove_pose_override(who)

	# Update the pose
	if modified:
		_update_pose()


## Force the grip and trigger values (primarily for preview)
func force_grip_trigger(grip : float = -1.0, trigger : float = -1.0) -> void:
	# Save the forced values
	_force_grip = grip
	_force_trigger = trigger

	# Update the animation if forcing to specific values
	if grip >= 0.0: $AnimationTree.set("parameters/Grip/blend_amount", grip)
	if trigger >= 0.0: $AnimationTree.set("parameters/Trigger/blend_amount", trigger)


## This function adds a target override. The collision hand will attempt to
## move to the highest priority target, or the [XRController3D] if no override
## is specified.
func add_target_override(target : Node3D, priority : int) -> void:
	# Remove any existing target override from this source
	var modified := _remove_target_override(target)

	# Insert the target override
	_insert_target_override(target, priority)
	modified = true

	# Update the target
	if modified:
		_update_target()


## This function remove a target override.
func remove_target_override(target : Node3D) -> void:
	# Remove the target override
	var modified := _remove_target_override(target)

	# Update the pose
	if modified:
		_update_target()


func _update_hand_blend_tree() -> void:
	# As we're going to make modifications to our animation tree, we need to do
	# a deep copy, simply setting resource local to scene does not seem to be enough
	if _animation_tree and hand_blend_tree:
		_tree_root = hand_blend_tree.duplicate(true)
		_animation_tree.tree_root = _tree_root


func _update_hand_material_override() -> void:
	if _hand_mesh:
		_hand_mesh.material_override = hand_material_override


func _update_pose() -> void:
	# Skip if no blend tree
	if !_tree_root:
		return

	# Select the pose settings
	var pose_settings : XRToolsHandPoseSettings = default_pose
	if _pose_overrides.size():
		pose_settings = _pose_overrides[0].settings

	# Get the open and closed pose animations
	var open_pose : Animation = pose_settings.open_pose
	var closed_pose : Animation = pose_settings.closed_pose

	# Apply the open hand pose in the player and blend tree
	if open_pose:
		var open_name: StringName = _animation_player.find_animation(open_pose)
		if open_name == "":
			open_name = "open_hand"
			if _animation_player.has_animation(open_name):
				_animation_player.get_animation_library("").remove_animation(open_name)

			_animation_player.get_animation_library("").add_animation(open_name, open_pose)

		var open_hand_obj : AnimationNodeAnimation = _tree_root.get_node("OpenHand")
		if open_hand_obj:
			open_hand_obj.animation = open_name

	# Apply the closed hand pose in the player and blend tree
	if closed_pose:
		var closed_name: StringName = _animation_player.find_animation(closed_pose)
		if closed_name == "":
			closed_name = "closed_hand"
			if _animation_player.has_animation(closed_name):
				_animation_player.get_animation_library("").remove_animation(closed_name)

			_animation_player.get_animation_library("").add_animation(closed_name, closed_pose)

		var closed_hand_obj : AnimationNodeAnimation = _tree_root.get_node("ClosedHand1")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name

		closed_hand_obj = _tree_root.get_node("ClosedHand2")
		if closed_hand_obj:
			closed_hand_obj.animation = closed_name


func _insert_pose_override(who : Node, priority : int, settings : XRToolsHandPoseSettings) -> void:
	# Construct the pose override
	var override := PoseOverride.new(who, priority, settings)

	# Iterate over all pose overrides in the list
	for pos in _pose_overrides.size():
		# Get the pose override
		var pose : PoseOverride = _pose_overrides[pos]

		# Insert as early as possible to not invalidate sorting
		if pose.priority <= priority:
			_pose_overrides.insert(pos, override)
			return

	# Insert at the end
	_pose_overrides.push_back(override)


func _remove_pose_override(who : Node) -> bool:
	var pos := 0
	var length := _pose_overrides.size()
	var modified := false

	# Iterate over all pose overrides in the list
	while pos < length:
		# Get the pose override
		var pose : PoseOverride = _pose_overrides[pos]

		# Check for a match
		if pose.who == who:
			# Remove the override
			_pose_overrides.remove_at(pos)
			modified = true
			length -= 1
		else:
			# Advance down the list
			pos += 1

	# Return the modified indicator
	return modified


# This function inserts a target override into the overrides list by priority
# order.
func _insert_target_override(target : Node3D, priority : int) -> void:
	# Construct the target override
	var override := TargetOverride.new(target, priority)

	# Iterate over all target overrides in the list
	for pos in _target_overrides.size():
		# Get the target override
		var o : TargetOverride = _target_overrides[pos]

		# Insert as early as possible to not invalidate sorting
		if o.priority <= priority:
			_target_overrides.insert(pos, override)
			return

	# Insert at the end
	_target_overrides.push_back(override)


# This function removes a target from the overrides list
func _remove_target_override(target : Node) -> bool:
	var pos := 0
	var length := _target_overrides.size()
	var modified := false

	# Iterate over all pose overrides in the list
	while pos < length:
		# Get the target override
		var o : TargetOverride = _target_overrides[pos]

		# Check for a match
		if o.target == target:
			# Remove the override
			_target_overrides.remove_at(pos)
			modified = true
			length -= 1
		else:
			# Advance down the list
			pos += 1

	# Return the modified indicator
	return modified


# This function updates the target for hand movement.
func _update_target() -> void:
	if _target_overrides.size():
		_target = _target_overrides[0].target
	else:
		_target = get_parent()


func _on_pause_state_changed(paused: bool) -> void:
	if paused:
		#_func_pickup.drop_object()
		#_teleport_to_target()
		pass


static func _find_child(node : Node, type : String) -> Node:
	# Iterate through all children
	for child in node.get_children():
		# If the child is a match then return it
		if child.is_class(type):
			return child

		# Recurse into child
		var found := _find_child(child, type)
		if found:
			return found

	# No child found matching type
	return null


## Update the closest object field with the best choice of grab
func _update_closest_object() -> void:
	# Find the closest object we can pickup
	var new_closest_obj: Node3D = null
	if not picked_up_object:
		# Find the closest in grab area
		new_closest_obj = _get_closest_grab()
	
	# Skip if no change
	if closest_object == new_closest_obj:
		return
	
	# remove highlight on old object
	if is_instance_valid(closest_object):
		closest_object.request_highlight(self, false)
	
	# add highlight to new object
	closest_object = new_closest_obj
	if is_instance_valid(closest_object):
		closest_object.request_highlight(self, true)


## Find the pickable object closest to our hand's grab location
func _get_closest_grab() -> Node3D:
	var new_closest_obj: Node3D = null
	var new_closest_distance := MAX_GRAB_DISTANCE2
	for o : Node3D in _objects_in_grab_area:
		# Skip objects that can not be picked up
		if not o.has_method("can_pick_up") or not o.can_pick_up(self):
			continue
		
		# Save if this object is closer than the current best
		var distance_squared := global_transform.origin.distance_squared_to(
				o.global_transform.origin)
		if distance_squared < new_closest_distance:
			new_closest_obj = o
			new_closest_distance = distance_squared
	
	# Return best object
	return new_closest_obj


## Called when the grab collision mask has been modified
func _set_grab_collision_mask(new_value: int) -> void:
	grab_collision_mask = new_value
	if is_inside_tree() and _grab_collision:
		_grab_collision.collision_mask = new_value


## Called when the grab distance has been modified
func _set_min_grab_distance(new_value: float) -> void:
	min_grab_distance = new_value
	if is_inside_tree():
		_update_colliders()


## Called when the grab distance has been modified
func _set_max_grab_distance(new_value: float) -> void:
	max_grab_distance = new_value
	if is_inside_tree():
		_update_colliders()


## Update the colliders geometry
func _update_colliders() -> void:
	# Update the grab sphere
	if _grab_collision:
		if not is_instance_valid(player_body):
			# Player body not set, just use min distance
			_grab_collision.shape.radius = min_grab_distance
		else:
			var relative_hand_y := global_position.y - player_body.global_position.y
			var min_height := player_body.current_player_height * 0.3
			var weight := clampf((relative_hand_y - min_height) / min_height, 0.0, 1.0)
			_grab_collision.shape.radius = lerpf(max_grab_distance, min_grab_distance, weight)


## Called when an object enters the grab sphere
func _on_grab_entered(target: Node3D) -> void:
	# Reject objects which don't support picking up
	if (
		target is not PhysicalPickable 
		and target is not PickableDispenser
		and target is not PhysicalSnapZone
		):
		return
	
	# Ignore objects already known
	if _objects_in_grab_area.find(target) >= 0:
		return

	# Add to the list of objects in grab area
	_objects_in_grab_area.push_back(target)


## Called when an object exits the grab sphere
func _on_grab_exited(target: Node3D) -> void:
	_objects_in_grab_area.erase(target)


## PID controller class used to calculate hand movement forces
class PIDController:
	var Kp: float
	var Ki: float
	var Kd: float
	var error: Vector3
	var proportional: Vector3
	var proportional_limit: float
	var previous_error: Vector3
	var integral: Vector3
	var integral_limit: float
	var derivative: Vector3
	var derivative_limit: float
	var output: Vector3

	func _init(args: Dictionary) -> void:
		Kp = args.Kp
		Ki = args.Ki
		Kd = args.Kd
		proportional_limit = args.proportional_limit
		integral_limit = args.integral_limit
		derivative_limit = args.derivative_limit
		previous_error = Vector3(0, 0, 0)
		integral = Vector3(0, 0, 0)


	func update(args: Dictionary) -> void:
		Kp = args.Kp
		Ki = args.Ki
		Kd = args.Kd
		integral_limit = args.integral_limit
		derivative_limit = args.derivative_limit


	func calculate(target: Vector3, current: Vector3, delta: float) -> Vector3:
		error = target - current
		proportional = error
		proportional = proportional.limit_length(proportional_limit)
		integral += error * delta
		integral = integral.limit_length(integral_limit)
		derivative = (error - previous_error) / delta
		derivative = derivative.limit_length(derivative_limit)
		previous_error = error
		output = Kp * proportional + Ki * integral + Kd * derivative

		return output


## Pose-override class
class PoseOverride:
	## Who requested the override
	var who : Node

	## Pose priority
	var priority : int

	## Pose settings
	var settings : XRToolsHandPoseSettings

	## Pose-override constructor
	func _init(w : Node, p : int, s : XRToolsHandPoseSettings) -> void:
		who = w
		priority = p
		settings = s


## Target-override class
class TargetOverride:
	## Target of the override
	var target : Node3D

	## Target priority
	var priority : int

	## Target-override constructor
	func _init(t : Node3D, p : int) -> void:
		target = t
		priority = p
