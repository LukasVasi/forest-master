@tool
class_name PhysicalPickable
extends RigidBody3D


# Default layer for held objects is 17:held-object
const DEFAULT_LAYER := 0b0000_0000_0000_0001_0000_0000_0000_0000

# Signal emitted when the highlight state changes
signal highlight_updated(pickable, enable)

## Layer for this object while picked up
@export_flags_3d_physics var picked_up_layer : int = DEFAULT_LAYER

## If true, the pickable supports being picked up
@export var enabled : bool = true

## If true, the grip control must be held to keep the object picked up
@export var press_to_hold : bool = true

var _grab_driver : PhysicalGrabDriver

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false

# Array of grab points
var _grab_points : Array[XRToolsGrabPoint] = []


func _ready():
	# Get all grab points
	for child in get_children():
		var grab_point := child as XRToolsGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)
			
	print(_grab_points.size())


#func _physics_process(delta: float) -> void:
	#if _grabber:
		#print("Hello")
		#apply_force(_grabber.global_position - global_position, _grabber.global_position - global_position)

# Test if this object can be picked up
func can_pick_up(by: Node3D) -> bool:
	# Refuse if not enabled
	if not enabled:
		return false

	# Allow if not held by anything
	if not is_picked_up():
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
		var by_grab_point := _grab_points[0]
		print(by_grab_point)
		_grab_driver = PhysicalGrabDriver.new(self, by.hand, by_grab_point)
		add_child(_grab_driver)
	
	print("Object picked up")


# Called when this object is dropped
func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	print_verbose("%s> dropping" % name)
	_grab_driver.discard()
	_grab_driver = null
	print("Object let go")


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
