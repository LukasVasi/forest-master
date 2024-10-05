class_name PickablePauseMenuContainer
extends Node3D

## Determines if the screen is following the _camera with a specific offset.
@export var follow_camera : bool = true: set = set_follow_camera

## The movement speed at which the menu moves to the target location.
@export var movement_speed : float = 5.0

## The rotation speed at which the menu rotates to target rotation.
@export var rotation_speed : float = 8.0

## The transform offset of the menu in front of the _player.
@export var initial_offset_transform : Transform3D = Transform3D(Basis(), Vector3(0.0, 0.0, -0.8))

@export var max_distance : float = 10.0

@export var min_distance : float = 1.0

@onready var _player : XROrigin3D = get_tree().get_first_node_in_group("player")

# Camera to track
@onready var _camera : XRCamera3D = _player.get_node("XRCamera3D") : set = set_camera

@onready var viewport: Node3D = get_node("Viewport2Din3D")

var _offset_transform : Transform3D

var _grabbed_by: Node3D
var _grab_transform: Transform3D

func _ready() -> void:
	_offset_transform = initial_offset_transform
	
	# Hide the viewport
	viewport.enabled = false
	viewport.visible = false
	
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)


func _physics_process(delta: float) -> void:
	# TODO: maybe remove this as it is not a tool?
	# Skip if in editor
	if Engine.is_editor_hint():
		return
	
	if follow_camera and not is_picked_up():
		_follow_camera(delta)
	
	if is_picked_up():
		global_transform = _grabbed_by.global_transform * _grab_transform.inverse()

func _follow_camera(delta: float) -> void:
	if !_player or !_camera:
		return
	
	# Retrieve the transform that we want to move and rotate towards
	var target_transform := _get_target_transform()
	
	global_position = global_position.move_toward(target_transform.origin, movement_speed * delta)
	
	global_basis = global_basis.slerp(target_transform.basis, rotation_speed * delta)


func reset_offset() -> void:
	if not is_picked_up():
		_offset_transform = initial_offset_transform


# Test if this object is picked up
func is_picked_up() -> bool:
	return _grabbed_by != null


func is_enabled() -> bool:
	return PauseManager.paused


func drop() -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	_grabbed_by = null


# Called when this container is picked up
func pick_up(by: Node3D) -> void:
	# Skip if not enabled
	if not is_enabled():
		return
	
	# Test if we're already picked up:
	if is_picked_up():
		# Swapping hands, let go with the primary grab
		let_go()

	_grabbed_by = by
	_grab_transform = global_transform.inverse() * _grabbed_by.global_transform


# Called when this object is dropped
func let_go() -> void:
	# Skip if not picked up
	if not is_picked_up():
		return

	_offset_transform = _camera.global_transform.affine_inverse() * global_transform

	_grabbed_by = null


func move_grab(delta: float, joystick_value: Vector2) -> void:
	if not is_picked_up():
		return
	
	var forward_direction = _grab_transform.basis.z.normalized()
	
	var movement_factor = joystick_value.y * delta

	_grab_transform.origin += forward_direction * movement_factor


func _teleport_to_target() -> void:
	global_transform = _get_target_transform()


func _get_target_transform() -> Transform3D:
	return _camera.global_transform * _offset_transform


func _update_follow_camera() -> void:
	if _camera and !Engine.is_editor_hint():
		set_process(follow_camera)


func _on_pause_state_changed(paused: bool) -> void:
	if paused:
		_teleport_to_target()
	viewport.enabled = paused
	viewport.visible = paused
	set_physics_process(paused)


## Set the _camera to track
func set_camera(p_camera : XRCamera3D) -> void:
	_camera = p_camera
	_update_follow_camera()


## Set the follow_camera property
func set_follow_camera(p_enabled : bool) -> void:
	follow_camera = p_enabled
	_update_follow_camera()
