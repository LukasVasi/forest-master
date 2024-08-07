class_name FishingFloatTarget
extends Node3D

var previous_position: Vector3 = Vector3.ZERO
var current_position: Vector3 = Vector3.ZERO
var velocity_buffer: Array[Vector3] = []  # Buffer to store recent velocity estimates
var buffer_size: int = 5  # Number of samples for averaging

var estimated_velocity: Vector3 = Vector3.ZERO
var instant_velocity: Vector3 = Vector3.ZERO

@export_category("Tugging logic")

## Velocity threshold for detecting a tug.
@export var tug_velocity_threshold: float = 5.0

## Tug detection cooldown in seconds used to prevent unintentional spamming.
@export var tug_cooldown: float = 0.8

## Remaining tug cooldown time.
var _tug_cooldown_remaining: float = 0.0

## Determines if the fishing rod is picked up.
## No calculations are run until it is.
var fishing_rod_picked_up: bool = false:
	set = set_picked_up

## The fishing rod (needed to handle a tug).
@onready var fishing_rod: FishingRod = get_node("../")


func _ready():
	current_position = global_position

func _physics_process(delta):
	if fishing_rod_picked_up:
		_update_velocity(delta)
		
		if _tug_cooldown_remaining > 0: # apply the tug check cooldown
			_tug_cooldown_remaining -= delta
		else:
			_check_for_tug()


func _update_velocity(delta):
	# Calculate the new instant velocity
	previous_position = current_position
	current_position = global_position
	instant_velocity = (current_position - previous_position) / delta
	
	
	# Ensure the buffer does not exceed the intended size
	if velocity_buffer.size() == buffer_size:
		velocity_buffer.pop_front()  # Remove the oldest sample
	
	# Add the most recent velocity estimate to the buffer
	velocity_buffer.append(instant_velocity)
	
	# Calculate the average velocity
	estimated_velocity = velocity_buffer.reduce(sum) / velocity_buffer.size()


## Check if the player is tugging the fishing rod. 
func _check_for_tug():
	if estimated_velocity.y > tug_velocity_threshold:
		_tug_cooldown_remaining = tug_cooldown
		fishing_rod.handle_tug()


## Summator, used for getting the sum of the velocity buffer.
func sum(accum, number):
	return accum + number


func set_picked_up(picked_up_status: bool):
	fishing_rod_picked_up = picked_up_status
