class_name FishingFloatTarget
extends Node3D

## The fishing float target is used for estimating the velocity 
## of the fishing rod's tip. Used for tugging and the float.

@export_category("Tugging logic")

## Velocity threshold for detecting a tug.
@export var tug_velocity_threshold: float = 5.0

## Tug detection cooldown in seconds used to prevent unintentional spamming.
@export var tug_cooldown: float = 0.8


## The fishing rod (needed to handle a tug).
@onready var fishing_rod: FishingRod = get_node("../")


var estimated_velocity: Vector3 = Vector3.ZERO


## Remaining tug cooldown time.
var _tug_cooldown_remaining: float = 0.0

var _current_position: Vector3 = Vector3.ZERO

var _previous_position: Vector3 = Vector3.ZERO

var _instant_velocity: Vector3 = Vector3.ZERO

var _velocity_buffer: Array[Vector3] = []  # Buffer to store recent velocity estimates

var _buffer_size: int = 5  # Number of samples for averaging


func _ready() -> void:
	set_physics_process(false)
	_current_position = global_position


## Updates the estimated velocity. Enabled and disabled by fishing rod.
func _physics_process(delta: float) -> void:
	_update_velocity(delta)
	
	if _tug_cooldown_remaining > 0: # apply the tug check cooldown
		_tug_cooldown_remaining -= delta
	else:
		_check_for_tug()


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
	estimated_velocity = _velocity_buffer.reduce(sum, Vector3.ZERO) / _velocity_buffer.size()


## Check if the player is tugging the fishing rod. 
func _check_for_tug() -> void:
	if estimated_velocity.y > tug_velocity_threshold:
		_tug_cooldown_remaining = tug_cooldown
		fishing_rod.handle_tug()


## Summator, used for getting the sum of the velocity buffer.
func sum(accum: Vector3, velocity: Vector3) -> Vector3:
	return accum + velocity
