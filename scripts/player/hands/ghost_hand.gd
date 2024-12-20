@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name GhostHand
extends Area3D


## Ghost Hand Script
##
## This hand is based on Godot XR Tools hand.
## Follows the controller exactly. Does not interact with the world by itself.
##
## Manages the hand poses so they'd match player inputs.
## Controls the transparency of the ghost hand shader. 


## Blend tree to use
@export var hand_blend_tree : AnimationNodeBlendTree: set = set_hand_blend_tree


## Default hand pose
@export var default_pose : XRToolsHandPoseSettings: set = set_default_pose

## Name of the Grip action in the OpenXR Action Map.
@export var grip_action : String = "grip"

## Name of the Trigger action in the OpenXR Action Map.
@export var trigger_action : String = "trigger"

@export_category("Transparency")

## Override the hand material with the ghost hand material. 
## Must have the min_alpha, max_alpha and alpha parameters.
@export var hand_material_override : ShaderMaterial: set = set_hand_material_override

## The relative path to the corresponding physical hand
@export var physical_hand_path : NodePath

@export var min_visibility_distance : float = 0.3

@export var max_visibility_distance : float = 0.6

var _max_shader_alpha : float

var _min_shader_alpha : float

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

var _physical_hand : PhysicalHand

var _hand_material_override_duplicate : ShaderMaterial

## Pose-override class
class PoseOverride:
	## Who requested the override
	var who : Node

	## Pose priority
	var priority : int

	## Pose settings
	var settings : XRToolsHandPoseSettings

	## Pose-override constructor
	func _init(w : Node, p : int, s : XRToolsHandPoseSettings):
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
	func _init(t : Node3D, p : int):
		target = t
		priority = p


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsHand"


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find our controller
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")
	
	# Find our physical hand
	if physical_hand_path and not physical_hand_path.is_empty():
		_physical_hand = get_node(physical_hand_path)

	# Find the relevant hand nodes
	_hand_mesh = _find_child(self, "MeshInstance3D")
	_animation_player = _find_child(self, "AnimationPlayer")
	_animation_tree = _find_child(self, "AnimationTree")

	# Apply all updates
	_update_hand_blend_tree()
	_update_hand_material_override()
	_update_pose()


## This method reads the grip and trigger action values to animate the hand.
func _process(_delta: float) -> void:
	# Do not run if in the editor
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
	
	# Update the visibility and shader
	if _physical_hand:
		var distance_to_hand: float = _physical_hand.distance_to_controller
		
		if distance_to_hand < min_visibility_distance:
			if visible : visible = false
		else:
			if not visible : visible = true
			var alpha_ratio: float = clampf((distance_to_hand - min_visibility_distance) / (max_visibility_distance - min_visibility_distance), 0.0, 1.0)
			var alpha_value: float = _min_shader_alpha + (_max_shader_alpha - _min_shader_alpha) * alpha_ratio
			_hand_material_override_duplicate.set_shader_parameter("alpha", alpha_value)

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
func set_hand_material_override(material : ShaderMaterial) -> void:
	if ( 
		material.get_shader_parameter("alpha") == null 
		or material.get_shader_parameter("min_alpha") == null
		or material.get_shader_parameter("max_alpha") == null
	):
		push_error("The passed material is not supported. Shader must have alpha, min_alpha and max_alpha params")
	else:
		# Set the material override
		hand_material_override = material
		if is_node_ready():
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


func _update_hand_blend_tree() -> void:
	# As we're going to make modifications to our animation tree, we need to do
	# a deep copy, simply setting resource local to scene does not seem to be enough
	if _animation_tree and hand_blend_tree:
		_tree_root = hand_blend_tree.duplicate(true)
		_animation_tree.tree_root = _tree_root


func _update_hand_material_override() -> void:
	if not is_node_ready():
		return
	
	# Duplicate so as not to change the og resource's alpha
	_hand_material_override_duplicate = hand_material_override.duplicate()
	_min_shader_alpha = _hand_material_override_duplicate.get_shader_parameter("min_alpha")
	_max_shader_alpha = _hand_material_override_duplicate.get_shader_parameter("max_alpha")
	_hand_mesh.material_override = _hand_material_override_duplicate


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
		var open_name = _animation_player.find_animation(open_pose)
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
		var closed_name = _animation_player.find_animation(closed_pose)
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


func can_teleport_to() -> bool:
	return has_overlapping_bodies()
