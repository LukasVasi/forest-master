@tool
class_name PhysicalInteractableHandle
extends PhysicalPickable


## XR Tools Interactable Handle script
##
## The interactable handle is a (usually invisible) object extending from
## [XRToolsPickable] that can be grabbed by the player and is used to
## manipulate interactable objects.
##
## The interactible handle has an origin position of its parent. In order
## to position interactible handles on the interactible object, the handle
## should be placed under a parent handle-origin node, and the origin nodes
## position set as desired.
##
## When the handle is released, it snaps back to its parent origin. If the
## handle is pulled further than its snap distance, then the handle is
## automatically released.


## Distance from the handle origin to auto-snap the grab
@export var snap_distance : float = 0.3


# Handle origin spatial node
@onready var handle_origin: Node3D = get_parent()


# Called when this handle is added to the scene
func _ready() -> void:
	# In Godot 4 we must now manually call our super class ready function
	super()
	
	# Ensure we start frozen, not top level and at our origin
	freeze = true
	top_level = false
	transform = Transform3D.IDENTITY

	# Turn off processing - it will be turned on only when held
	set_physics_process(false)


# Called on every frame when the handle is held to check for snapping
func _physics_process(_delta: float) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	# If too far from the origin then drop the handle
	var origin_pos := handle_origin.global_position
	var handle_pos := global_position
	if handle_pos.distance_to(origin_pos) > snap_distance:
		drop()


# Called when the handle is picked up
func pick_up(by: Node3D) -> PhysicalGrab:
	# Enable the process function while held
	set_physics_process(true)
	
	# Call the base-class to perform the pickup
	var grab := super(by)
	
	if is_instance_valid(grab):
		# Set as top level and unfreeze if pickup is successful
		top_level = true
		freeze = false
	
	return grab



# Called when the handle is dropped
func let_go(by: Node3D) -> void:
	# Call the base-class to perform the drop
	super(by)
	
	# Reset the handle to the original state
	freeze = true
	top_level = false
	transform = Transform3D.IDENTITY

	# Disable the process function as no-longer held
	set_physics_process(false)


# Check handle configurationv
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if !transform.is_equal_approx(Transform3D.IDENTITY):
		warnings.append("Interactable handle must have no transform from its parent handle origin")

	return warnings
