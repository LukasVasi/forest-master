class_name PauseMenuContainer
extends Node3D


## The movement speed at which the menu moves to the target location.
@export var movement_speed : float = 5.0

## The rotation speed at which the menu rotates to target rotation.
@export var rotation_speed : float = 8.0

## The initial transform offset of the menu in front of the player.
@export var initial_offset_transform : Transform3D = Transform3D(Basis(), Vector3(0.0, 0.0, -0.8))

## The player to track.
@onready var _player : XROrigin3D = get_tree().get_first_node_in_group("player")

## The player camera to track.
@onready var _camera : XRCamera3D = _player.get_node("XRCamera3D") : set = set_camera

## The viewport that displays the pause menu.
@onready var viewport: Node3D = get_node("Viewport2Din3D")

## Determines if the pause menu container is enabled.
var _enabled : bool = false: set = set_enabled

## The current offset from the player camera.
var _offset_transform : Transform3D

## The function pickup that has currently grabbed the container.
var _grabbed_by: Node3D

var _grab_transform: Transform3D = Transform3D()

func _ready() -> void:
	_offset_transform = initial_offset_transform
	
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)
	
	_update_enabled()


func _physics_process(delta: float) -> void:
	if _camera and not is_picked_up():
		_follow_camera(delta)
	
	if is_picked_up():
		_follow_grabber()

func _follow_camera(delta: float) -> void:
	var target_transform := _get_target_transform()
	
	global_position = global_position.move_toward(target_transform.origin, movement_speed * delta)
	
	global_basis = global_basis.slerp(target_transform.basis, rotation_speed * delta)


func _follow_grabber() -> void:
	global_transform = _grabbed_by.global_transform * _grab_transform.inverse()


func reset_offset() -> void:
	if not _enabled:
		return
	
	if not is_picked_up():
		print("Not picked up, resetting")
		_offset_transform = initial_offset_transform
	else:
		print("Picked up, doing the big reset")
		# If picked up, let go, reset and then pickup again
		var grabber := _grabbed_by
		let_go()
		_offset_transform = initial_offset_transform
		_teleport_to_target()
		pick_up(grabber)


# Test if this object is picked up
func is_picked_up() -> bool:
	return _grabbed_by != null


func is_enabled() -> bool:
	return PauseManager.paused


# Called when this container is picked up
func pick_up(by: Node3D) -> void:
	# Skip if not _enabled
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

	# Save the current offset as the new target offset
	_offset_transform = _camera.global_transform.affine_inverse() * global_transform

	# Reset the grabber and grab transform
	_grabbed_by = null
	_grab_transform = Transform3D()


## Adjusts the offset of the pause menu while picked up based on joystick control.
func move_grab(delta: float, joystick_value: Vector2) -> void:
	if not is_picked_up():
		return
	
	var forward_direction := _grab_transform.basis.z.normalized()
	
	var movement_factor := joystick_value.y * delta

	_grab_transform.origin += forward_direction * movement_factor


func _teleport_to_target() -> void:
	print("Teleporting to target offset")
	global_transform = _get_target_transform()


func _get_target_transform() -> Transform3D:
	return _camera.global_transform * _offset_transform


func _on_pause_state_changed(paused: bool) -> void:
	if paused:
		_teleport_to_target()
	_enabled = paused


func set_enabled(p_enabled : bool) -> void:
	_enabled = p_enabled
	_update_enabled()


func _update_enabled() -> void:
	viewport.enabled = _enabled
	viewport.visible = _enabled
	set_physics_process(_enabled)


## Set the _camera to track
func set_camera(p_camera : XRCamera3D) -> void:
	_camera = p_camera
