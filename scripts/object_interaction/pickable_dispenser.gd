class_name PickableDispenser
extends Area3D

## This script realises a dispenser for pickable objects.
## When a [XRToolsFunctionPickup] tries to pickup this object, 
## it spawns an isntance of one of the dispensed scenes and 
## makes it get picked up by the [XRToolsFunctionPickup] that tried to pick this up.


# Signal emitted when the highlight state changes
signal highlight_updated(pickable: Variant, enable: Variant)

signal dispensed(pickable : Variant)


## If true, the dispenser supports being picked up
@export var enabled : bool = true

## The pickable object scenes that are used for instantiation
@export var dispensed_scenes: Array[PackedScene] = []

## Collision objects that are a part of the dispenser 
## and should have a collision exception with dispensables.
@export var collision_exceptions : Array[CollisionObject3D]

# Dictionary of nodes requesting highlight
var _highlight_requests : Dictionary = {}

# Is this node highlighted
var _highlighted : bool = false


# Add support for is_xr_class on XRTools classes
func is_xr_class(p_name : String) -> bool:
	return p_name == "PickableDispenser"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if dispensed_scenes.size() == 0:
		enabled = false
		return
	
	for dispensed_scene in dispensed_scenes:
		if not dispensed_scene:
			push_error("Dispensed scene in null")
			enabled = false
			return
		var instance: PhysicalPickable = dispensed_scene.instantiate()
		if not instance.has_method("pick_up"):
			push_error("Pickable dispenser needs dispensed scenes to have the pick_up method")
			enabled = false
			instance.queue_free()
			return
		else:
			instance.queue_free()


## Test if this object can dispense a pickup
func can_pick_up(_by: Node3D) -> bool:
	return enabled


## This method requests highlighting of the [XRToolsPickable].
## If [param from] is null then all highlighting requests are cleared,
## otherwise the highlight request is associated with the specified node.
func request_highlight(from: PhysicalHand, on: bool = true) -> void:
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


# Called when FunctionPickup requests a pciakble
func get_dispensable(by: Node3D) -> PhysicalPickable:
	var dispensed_object: PhysicalPickable = _get_dispensable_instance()
	if is_instance_valid(dispensed_object):
		collision_exceptions.all(func(collision_object : CollisionObject3D) -> void: dispensed_object.add_collision_exception_with(collision_object))
		add_child(dispensed_object)
		dispensed_object.global_position = by.global_position
		dispensed.emit(dispensed_object)
		return dispensed_object
	else:
		return null


## Instantiate a random scene by default
func _get_dispensable_instance() -> PhysicalPickable:
	return dispensed_scenes.pick_random().instantiate()
