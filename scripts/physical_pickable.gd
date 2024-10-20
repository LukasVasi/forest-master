@tool
class_name PhysicalPickable
extends RigidBody3D

# Default layer for held objects is 17:held-object
const DEFAULT_LAYER := 0b0000_0000_0000_0001_0000_0000_0000_0000

## Signal emitted when the highlight state changes
signal highlight_updated(pickable: PhysicalPickable, enable: bool)

## Signal emitted when this object is picked up (held by a player or snap-zone)
signal picked_up(pickable: PhysicalPickable)

## Signal emitted when this object is dropped
signal dropped(pickable: PhysicalPickable)

## Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable: PhysicalPickable)

## Signal emitted when the user releases the action button while holding this object
signal action_released(pickable: PhysicalPickable)

## Signal emitted when this object is grabbed (primary or secondary).
## Emitted in the grab class.
signal grabbed(pickable: PhysicalPickable, by: PhysicalHand)

## Signal emitted when this object is released (primary or secondary).
## Emitted in the grab class.
signal released(pickable: PhysicalPickable, by: PhysicalHand)

## Layer for this object while picked up
@export_flags_3d_physics var picked_up_layer : int = DEFAULT_LAYER

## If true, the pickable supports being picked up
@export var enabled : bool = true

## If true, the grip control must be held to keep the object picked up
@export var press_to_hold : bool = true

# Remember some state so we can return to it when the user drops the object
@onready var original_collision_mask : int = collision_mask
@onready var original_collision_layer : int = collision_layer

var _grabs : Array[PhysicalGrab] = []

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false

# Array of grab points
var _grab_points : Array[PhysicalGrabPoint] = []


func _ready() -> void:
	# Get all grab points
	for child in get_children():
		var grab_point := child as PhysicalGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)


# TODO: test if this hand isn't already picking up
# Test if this object can be picked up
func can_pick_up(by: Node3D) -> bool:
	# Refuse if not enabled
	if not enabled:
		return false
	else:
		return _grabs.size() < 2


## Called when this object is picked up. Returns the grab information.
func pick_up(by: PhysicalHand) -> PhysicalGrab:
	# Skip if not enabled
	if not enabled:
		return
	
	var new_grab : PhysicalGrab
	
	if not is_picked_up():
		# Find a suitable primary hand grab
		var by_grab_point := _get_grab_point(by, null)
		if not is_instance_valid(by_grab_point):
			return null
		new_grab = PhysicalGrab.new(by, self, by_grab_point)
		
		# TODO: set center of mass to palm instead of center of grab point because they don't align
		collision_layer = picked_up_layer
		angular_damp = 1 # Reduce rotational forces to make holding more natural
		var new_center_of_mass := new_grab.grab_point.global_position - global_position
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = new_center_of_mass
	else:
		var by_grab_point := _get_grab_point(by, _grabs.front().grab_point)
		if not is_instance_valid(by_grab_point):
			return null
		new_grab = PhysicalGrab.new(by, self, by_grab_point)
		
		var new_center_of_mass := new_grab.grab_point.global_position - global_position
		center_of_mass = (center_of_mass + new_center_of_mass) / 2
	
	# Add the grab information
	_grabs.append(new_grab)
	
	# Report picked up
	picked_up.emit(self)
	
	return new_grab


## Called when this object is dropped
func let_go(by: PhysicalHand) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return
	
	# Skip if such grab doesn't exist
	if not _grabs.any(func(grab: PhysicalGrab) -> bool: return grab.hand == by):
		return
	
	for grab in _grabs:
		if grab.hand == by:
			# Remove the grab from the driver and release the grab
			_grabs.erase(grab)
			grab.release()
	
	# Check if there is still a grab
	if _grabs.is_empty():
		# Reset the [RigidBody3D] properties
		collision_layer = original_collision_layer
		angular_damp = 0
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
		center_of_mass = Vector3.ZERO
		
		# Let interested parties know
		dropped.emit(self)
	else:
		# If a grab is present - set the center of mass to it
		var new_center_of_mass := _grabs[0].grab_point.global_position - global_position
		center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		center_of_mass = new_center_of_mass


# Called when user presses the action button while holding this object
func action() -> void:
	action_pressed.emit(self)


# Called when user releases the action button while holding this object
func action_release() -> void:
	action_released.emit(self)


func drop() -> void:
	# Skip if not picked up
	if not is_picked_up():
		return
	
	for grab in _grabs:
		grab.hand.drop_object()


func drop_and_free() -> void:
	drop()
	queue_free()


## This method requests highlighting of the [XRToolsPickable].
## If [param from] is null then all highlighting requests are cleared,
## otherwise the highlight request is associated with the specified node.
func request_highlight(from : Node, on : bool = true) -> void:
	# Save if we are highlighted
	var old_highlighted := _highlighted

	# Update the highlight requests dictionary
	if not from:
		_highlight_requests.clear()
	elif on:
		_highlight_requests[from] = from
	else:
		_highlight_requests.erase(from)

	# Update the highlighted state
	_highlighted = _highlight_requests.size() > 0

	# Report any changes
	if _highlighted != old_highlighted:
		highlight_updated.emit(self, _highlighted)


# Test if this object is picked up
func is_picked_up() -> bool:
	return not _grabs.is_empty()


## Get the controller currently holding this object
func get_picked_up_by_controller() -> XRController3D:
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Get the primary pickup controller
	return _grabs.front().controller


## Find the most suitable grab-point for the grabber
func _get_grab_point(grabber : Node3D, current : XRToolsGrabPoint) -> XRToolsGrabPoint:
	# Find the best grab-point
	var fitness := 0.0
	var point : XRToolsGrabPoint = null
	for p : XRToolsGrabPoint in _grab_points:
		var f := p.can_grab(grabber, current)
		if f > fitness:
			fitness = f
			point = p

	# Resolve redirection
	while point is XRToolsGrabPointRedirect:
		point = point.target

	# Return the best grab point
	print_verbose("%s> picked grab-point %s" % [name, point])
	return point


# Called when the node exits the tree
func _exit_tree() -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	for grab in _grabs:
		grab.release()
	
	_grabs.clear()
