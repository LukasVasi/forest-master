class_name FishingFloatTarget
extends Node3D

## The fishing float target is used for estimating the velocity 
## of the fishing rod's tip. Used for yanking and the float.


signal yanked(yank_velocity: Vector3)


@export_category("Tugging logic")

## Velocity threshold for detecting a yank.
@export var yank_velocity_threshold: float = 2.0

## Yank detection cooldown in seconds used to prevent unintentional spamming.
@export var yank_cooldown: float = 0.8


## Flag for velocity estiamtion state. Enabled when rod is picked up.
var enabled: bool = false: set = _set_enabled

## The estimated velocity of the target - the tip of the fishing rod.
var estimated_velocity: Vector3 = Vector3.ZERO


@onready var _current_position: Vector3 = global_position

## Remaining yank cooldown time.
var _yank_cooldown_remaining: float = 0.0

var _previous_position: Vector3 = Vector3.ZERO

var _instant_velocity: Vector3 = Vector3.ZERO

var _velocity_buffer: Array[Vector3] = []  # Buffer to store recent velocity estimates

var _buffer_size: int = 5  # Number of samples for averaging


## Updates the estimated velocity.
func _physics_process(delta: float) -> void:
	if not enabled:
		set_physics_process(false)
		return
	
	_update_velocity(delta)
	
	if _yank_cooldown_remaining > 0: # apply the yank check cooldown
		_yank_cooldown_remaining -= delta
	else:
		_check_for_yank()


func _update_velocity(delta: float) -> void:
	# Calculate the new instant velocity
	_previous_position = _current_position
	_current_position = global_position
	_instant_velocity = (_current_position - _previous_position) / delta
	
	# Ensure the buffer does not exceed the intended size
	if _velocity_buffer.size() == _buffer_size:
		_velocity_buffer.pop_front()  # Remove the oldest sample
	
	# Add the most recent velocity estimate to the buffer
	_velocity_buffer.append(_instant_velocity)
	
	# Calculate the average velocity
	estimated_velocity = _velocity_buffer.reduce(_sum, Vector3.ZERO) / _velocity_buffer.size()


## Check if the player is yanking the fishing rod. 
func _check_for_yank() -> void:
	# TODO: register yank in any direction except downwards
	if estimated_velocity.y > yank_velocity_threshold:
		_yank_cooldown_remaining = yank_cooldown
		yanked.emit(estimated_velocity)


## Summator, used for getting the sum of the velocity buffer.
func _sum(accum: Vector3, velocity: Vector3) -> Vector3:
	return accum + velocity


func _set_enabled(new_value: bool) -> void:
	enabled = new_value
	set_physics_process(enabled)
