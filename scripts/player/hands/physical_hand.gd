@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name PhysicalHand
extends RigidBody3D

## The Physical Hand script
##
## Actual real hand that uses force to try and follow the controller. Can interact with the world.

## ----------------- Custom stuff

## The force that pushes the hand towards the target.
@export var hand_movement_force : float = 400.0

## The torque that rotates the hand according to the target.
@export var hand_rotation_torque : float = 200.0

## The max distance that the hand can depart from the controller before being teleported.
@export var max_distance_to_controller : float = 2.0

@export_category("Rumble feedback")

## The distance from the controller at which a haptic feedback is provided. 
@export var distance_to_rumble : float = 0.3

## The maximum rumble magnitude that will be used at max distance.
@export_range(0.0, 1.0) var max_rumble_magnitude : float = 0.2

## The rumble event for when the hand gets too far
@export var rumble_event : XRToolsRumbleEvent

@export var rumble_trackers : Array[StringName]

## --------------------------- XR Tools Hand stuff

## Blend tree to use
@export var hand_blend_tree : AnimationNodeBlendTree: set = set_hand_blend_tree

## Override the hand material
@export var hand_material_override : Material: set = set_hand_material_override

## Default hand pose
@export var default_pose : XRToolsHandPoseSettings: set = set_default_pose

## Name of the Grip action in the OpenXR Action Map.
@export var grip_action : String = "grip"

## Name of the Trigger action in the OpenXR Action Map.
@export var trigger_action : String = "trigger"

var distance_to_target: float = 0.0

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

var _func_pickup : FunctionPickup

var _initial_mass : float

var _initial_gravity_scale : float

var _rumbling : bool = false

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

## ------------------------------- XR Tools Physics Hand stuff

# Default hand bone layer of 18:player-hand
#const DEFAULT_LAYER := 0b0000_0000_0000_0010_0000_0000_0000_0000


## Collision layer applied to all [XRToolsHandPhysicsBone] children.
##
## This is used to set physics collision layers for every bone in a hand.
## Additionally [XRToolsHandPhysicsBone] nodes can specify additional
## bone-specific collision layers - for example to give the fore-finger bone
## additional collision capabilities.
#@export_flags_3d_physics var collision_layer : int = DEFAULT_LAYER

## Bone collision margin applied to all [XRToolsHandPhysicsBone] children.
##
## This is used for fine-tuning the collision margins for all
## [XRToolsHandPhysicsBone] children in the hand.
@export var margin : float = 0.004

## Group applied to all [XRToolsHandPhysicsBone] children.
##
## This is used to set groups for every bone in the hand. Additionally
## [XRToolsHandPhysicsBone] nodes can specify additional bone-specific groups.
@export var bone_group : String = ""


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPhysicsHand" or name == "XRToolsHand"


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Disconnect from parent transform as we move to it in the physics step,
	# and boost the physics priority after any grab-drivers but before other
	# processing.
	if not Engine.is_editor_hint():
		top_level = true
		process_physics_priority = -70
	
	_initial_mass = mass
	_initial_gravity_scale = gravity_scale
	
	# Find our controller
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")
	
	# Find our pickup
	_func_pickup = XRTools.find_xr_child(self, "*", "XRToolsFunctionPickup")
	_func_pickup.has_picked_up.connect(_on_has_picked_up)
	_func_pickup.has_dropped.connect(_on_has_dropped)

	# Find the relevant hand nodes
	_hand_mesh = _find_child(self, "MeshInstance3D")
	_animation_player = _find_child(self, "AnimationPlayer")
	_animation_tree = _find_child(self, "AnimationTree")

	# Apply all updates
	_update_hand_blend_tree()
	_update_hand_material_override()
	_update_pose()
	_update_target()
	
	if not Engine.is_editor_hint():
		PauseManager.pause_state_changed.connect(_on_pause_state_changed)
		# Teleport to controller
		_teleport_to_target()


func _teleport_to_target() -> void:
	freeze = true
	global_transform = _target.global_transform
	freeze = false


## This method  reads the grip and trigger action values to animate the hand.
## And then it applies the necessary forces to move the hand towards its target.
func _physics_process(_delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return
	
	# Animate the hand mesh with the controller inputs
	if _controller:
		var grip : float = _controller.get_float(grip_action)
		var trigger : float = _controller.get_float(trigger_action)

		# Allow overriding of grip and trigger
		if _force_grip >= 0.0: grip = _force_grip
		if _force_trigger >= 0.0: trigger = _force_trigger

		$AnimationTree.set("parameters/Grip/blend_amount", grip)
		$AnimationTree.set("parameters/Trigger/blend_amount", trigger)
	
	# TODO: maybe introduce a local variable or just do it differently somehow?
	if PauseManager.paused:
		global_transform = _target.global_transform
		return
	
	distance_to_target = _target.global_position.distance_to(global_position)
	
	if distance_to_target > distance_to_rumble:
		if not _rumbling:
			_rumbling = true
			XRToolsRumbleManager.add(self, rumble_event, rumble_trackers)
		
		var rumble_magnitude: float = max_rumble_magnitude * (distance_to_target - distance_to_rumble)  / (max_distance_to_controller - distance_to_rumble) 
		rumble_event.magnitude = rumble_magnitude
	elif distance_to_target < distance_to_rumble and _rumbling:
		_rumbling = false
		XRToolsRumbleManager.clear(self, rumble_trackers)
	
	# Check distance to hand
	if distance_to_target > max_distance_to_controller:
		# Hand's too far away, maybe gotten stuck or holding an object that's too heavy
		_func_pickup.drop_object()
		_teleport_to_target()
	else:
		# Move to target
		var movement_delta: Vector3 = _target.global_position - global_position
		apply_central_force(movement_delta * hand_movement_force)
		
		# Rotate to target
		var quat_target: Quaternion = _target.global_basis.get_rotation_quaternion()
		var quat_hand: Quaternion = global_basis.get_rotation_quaternion()
		var quat_delta: Quaternion = quat_target * (quat_hand.inverse())
		var rotation_delta: Vector3 = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
		apply_torque(rotation_delta * hand_rotation_torque)
	
	# Force the transform update at this moment
	force_update_transform()


func _on_has_picked_up(object: Node3D) -> void:
	var object_rigid: RigidBody3D = object as RigidBody3D
	mass += object_rigid.mass
	gravity_scale = object_rigid.gravity_scale


func _on_has_dropped() -> void:
	mass = _initial_mass
	gravity_scale = _initial_gravity_scale


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
		_func_pickup.drop_object()
		_teleport_to_target()


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
