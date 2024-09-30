@tool
class_name PickableViewport
extends XRToolsPickable

## If true, the screen follows the camera
@export var follow_camera : bool = true: set = set_follow_camera

@export var movement_speed : float = 5.0

@export var rotation_speed : float = 8.0

## The transform offset of the menu in front of the player
@export var offset_transform : Transform3D = Transform3D(Basis(), Vector3(0.0, 0.0, -0.8))

# The player to track
@onready var player : XROrigin3D = get_tree().get_first_node_in_group("player")

# Camera to track
@onready var camera : XRCamera3D = player.get_node("XRCamera3D") : set = set_camera

@onready var viewport: Node3D = get_node("Viewport2Din3D")

func _ready() -> void:
	super._ready()
	# Hide the viewport
	viewport.enabled = false
	viewport.visible = false
	
	# Disable the physics processing
	set_physics_process(false)
	$CollisionShape3D.disabled = true
	
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)

func _physics_process(delta: float) -> void:
	# Skip if in editor
	if Engine.is_editor_hint():
		return
	
	# Skip if picked up
	if is_picked_up():
		return
	
	# Skip if no camera or player to track
	if !camera:
		return
	
	var target_transform := _get_target_transform()
	
	global_position = global_position.move_toward(target_transform.origin, movement_speed * delta)
	
	global_basis = global_basis.slerp(target_transform.basis, rotation_speed * delta)


# Called when this object is dropped
func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	offset_transform = camera.global_transform.affine_inverse() * global_transform

	# Get the grab information
	var grab := _grab_driver.get_grab(by)
	if not grab:
		return

	# Remove the grab from the driver and release the grab
	_grab_driver.remove_grab(grab)
	grab.release()

	# Test if still grabbing
	if _grab_driver.primary:
		# Test if we need to swap grab-points
		if is_instance_valid(_grab_driver.primary.hand_point):
			# Verify the current primary grab point is a valid primary grab point
			if _grab_driver.primary.hand_point.mode != XRToolsGrabPointHand.Mode.SECONDARY:
				return

			# Find a more suitable grab-point
			var new_grab_point := _get_grab_point(_grab_driver.primary.by, null)
			print_verbose("%s> held only by secondary, swapping grab points" % name)
			switch_active_grab_point(new_grab_point)

		# Grab is still good
		return

	# Drop the grab-driver
	print_verbose("%s> dropping" % name)
	_grab_driver.discard()
	_grab_driver = null

	# Restore RigidBody mode
	freeze = restore_freeze
	collision_mask = original_collision_mask
	collision_layer = original_collision_layer

	# Set velocity
	linear_velocity = p_linear_velocity
	angular_velocity = p_angular_velocity

	# let interested parties know
	dropped.emit(self)


func _teleport_to_target() -> void:
	global_transform = _get_target_transform()


func _get_target_transform() -> Transform3D:
	return camera.global_transform * offset_transform


func _update_follow_camera() -> void:
	if camera and !Engine.is_editor_hint():
		set_process(follow_camera)


func _on_pause_state_changed(paused: bool) -> void:
	if paused:
		_teleport_to_target()
	viewport.enabled = paused
	viewport.visible = paused
	set_physics_process(paused)
	$CollisionShape3D.disabled = not paused


## Set the camera to track
func set_camera(p_camera : XRCamera3D) -> void:
	camera = p_camera
	_update_follow_camera()


## Set the follow_camera property
func set_follow_camera(p_enabled : bool) -> void:
	follow_camera = p_enabled
	_update_follow_camera()
