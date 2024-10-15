@tool
class_name PhysicalPickable
extends RigidBody3D


# Default layer for held objects is 17:held-object
const DEFAULT_LAYER := 0b0000_0000_0000_0001_0000_0000_0000_0000

## Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)

## Signal emitted when this object is picked up (held by a player or snap-zone)
signal picked_up(pickable)

## Signal emitted when this object is dropped
signal dropped(pickable)

## Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable)

## Signal emitted when the user releases the action button while holding this object
signal action_released(pickable)

## Signal emitted when this object is grabbed (primary or secondary).
## Emitted in the grab class.
signal grabbed(pickable, by)

## Signal emitted when this object is released (primary or secondary).
## Emitted in the grab class.
signal released(pickable, by)

## Layer for this object while picked up
@export_flags_3d_physics var picked_up_layer : int = DEFAULT_LAYER

## If true, the pickable supports being picked up
@export var enabled : bool = true

## If true, the grip control must be held to keep the object picked up
@export var press_to_hold : bool = true

@export var force_multiplier : float = 1.0

@export var torque_multiplier : Vector3 = Vector3.ONE

# Remember some state so we can return to it when the user drops the object
@onready var original_collision_mask : int = collision_mask
@onready var original_collision_layer : int = collision_layer

var _grab_driver : PhysicalGrabDriver

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false

# Array of grab points
var _grab_points : Array[PhysicalGrabPoint] = []


func _ready():
	# Get all grab points
	for child in get_children():
		var grab_point := child as PhysicalGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)


# Test if this object can be picked up
func can_pick_up(by: Node3D) -> bool:
	# Refuse if not enabled
	if not enabled:
		return false

	# Allow if not held by anything
	if not is_picked_up():
		return true
	elif not _grab_driver.secondary_grab:
		return true
	else:
		return false


# Called when this object is picked up
func pick_up(by: Node3D) -> void:
	# Skip if not enabled
	if not enabled:
		return
	
	if not is_picked_up():
		# Find a suitable primary hand grab
		var by_grab_point := _get_grab_point(by, null)
		var grab := PhysicalGrab.new(by, self, by_grab_point)
		_grab_driver = PhysicalGrabDriver.new(grab)
		add_child(_grab_driver)
		collision_layer = picked_up_layer
	else:
		var by_grab_point := _get_grab_point(by, _grab_driver.primary_grab.grab_point)
		var grab := PhysicalGrab.new(by, self, by_grab_point)
		_grab_driver.add_grab(grab)
	
	# Report picked up
	picked_up.emit(self)

# Called when this object is dropped
func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return
	
	# Get the grab information
	var grab := _grab_driver.get_grab(by)
	if not grab:
		return
	
	# Remove the grab from the driver and release the grab
	_grab_driver.remove_grab(grab)
	grab.release()
	
	# Check if there is still a grab
	if not _grab_driver.primary_grab:
		# Drop the grab-driver
		print_verbose("%s> dropping" % name)
		_grab_driver.discard()
		_grab_driver = null
		
		collision_layer = original_collision_layer
	
		# Let interested parties know
		dropped.emit(self)


# Called when user presses the action button while holding this object
func action():
	action_pressed.emit(self)


# Called when user releases the action button while holding this object
func action_release():
	action_released.emit(self)


func drop():
	# Skip if not picked up
	if not is_picked_up():
		return

	# Request secondary grabber to drop
	if _grab_driver.secondary_grab:
		_grab_driver.secondary_grab.function_pickup.drop_object()

	# Request primary grabber to drop
	_grab_driver.primary_grab.function_pickup.drop_object()


func drop_and_free():
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
	return _grab_driver != null


## Get the controller currently holding this object
func get_picked_up_by_controller() -> XRController3D:
	# Skip if not picked up
	if not is_picked_up():
		return null

	# Get the primary pickup controller
	return _grab_driver.primary_grab.controller


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
func _exit_tree():
	# Skip if not picked up
	if not is_instance_valid(_grab_driver):
		return

	# Release primary grab
	if _grab_driver.primary:
		_grab_driver.primary.release()

	# Release secondary grab
	if _grab_driver.secondary:
		_grab_driver.secondary.release()
