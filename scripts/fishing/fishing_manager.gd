class_name FishingManager
extends Node


## The fish scenes that will be spawned upon catching.
const RaudeScene = preload("res://scenes/fishing/fishes/raude.tscn")
const KuojaScene = preload("res://scenes/fishing/fishes/kuoja.tscn")
const LynasScene = preload("res://scenes/fishing/fishes/lynas.tscn")

# NOTE: if we ever want to save some extra memory for other activities, distractions could
# all be preloaded and only instantiated when fishing starts instead of being children to this node
#const DistractionFishScene = preload("res://scenes/fishing/distractions/distraction_fish.tscn")
#const DistractionWindScene = preload("res://scenes/fishing/distractions/distraction_wind.tscn")


signal on_state_changed(new_state: State)

signal fish_caught(fish : Fish)


enum State 
{
	Sleeping, # not currently fishing
	Baiting,
	Reeling
}

# The direction (from the player's perspective) that the fish is pushing the float
enum FishDirection
{
	Forward,
	Left,
	Right,
}


@export_category("Fishing")

## The threshold of interest for the fish to bite on trial.
@export var fish_interest_threshold: float = 90

## The amount of fish interest gained when succeeding a trial.
@export var interest_gain_on_complete: float = 30

## The amount of fish interest lost when failing a trial.
@export var interest_loss_on_fail: float = 15

## The amount of fish interest lost when tugging not during a trial.
@export var interest_loss_on_miss: float = 10

## The time you need to wait between trials.
@export var trial_time: float = 3.0

## Multiplyer that determines the randomness of time between trials.
## 0 means no randomness, 
## 1 means the time between trials can last anywhere between 0 s and twice the normal time.
@export_range(0.0, 1.0) var trial_wait_time_randomness: float = 0.1

## The time between distractions.
@export var distraction_time: float = 3.0

## Multiplyer that determines the randomness of time between distractions.
@export_range(0.0, 1.0) var distraction_time_randomness: float = 0.2

## The time in seconds that the player has to react to a trial.
@export var catch_window: float = 1.5


@export_group("Distractions")

## The maximum distance a distraction can spawn from the float
@export var max_distance: float = 6.0

## The minimum distance a distraction can spawn from the float
@export var min_distance: float = 2.0


var can_catch: bool = false

var trial_number: int = 0

#region Timers

@onready var _trial_timer: Timer = get_node("TrialTimer")

@onready var _catch_timer: Timer = get_node("CatchTimer")

@onready var _reel_timer: Timer = get_node("ReelTimer")

@onready var _distraction_timer: Timer = get_node("DistractionTimer");

#endregion

## The fishing rod.
@onready var _fishing_rod: FishingRod = get_tree().get_first_node_in_group("fishing_rod")

## The player.
@onready var _player: Node3D = get_tree().get_first_node_in_group("player")

## The viewport that displays the fishing ui above the float.
@onready var _float_ui_viewport: FishingFloatUIViewport = get_node("FishingFloatUIViewport")

var wind_distraction: bool = false
var wind_transition_speed: float = 0.2
var wind_transition_time: float = 0.0

var _current_fish_interest: float = 0

var distractions: Array[Distraction] = []
var fish_scenes: Array[PackedScene] = []

var state: State = State.Sleeping

var _fish_direction: FishDirection = FishDirection.Forward
var _current_session: FishingSession = null


func _ready() -> void:
	_fishing_rod.fishing_float.target.yanked.connect(_on_fishing_rod_yanked)
	_fishing_rod.snapped.connect(_on_fishing_rod_snapped)
	
	_float_ui_viewport.visible = false
	
	for distraction in get_node("DistractionContainer").get_children():
		distractions.append(distraction)
		
	fish_scenes.append(RaudeScene)
	fish_scenes.append(KuojaScene)
	fish_scenes.append(LynasScene)


func _process(_delta: float) -> void:
	if state != State.Sleeping:
		var tension_ration: float = _fishing_rod.get_tension_ratio() if state == State.Reeling else -1.0
		_float_ui_viewport.update(_fish_direction, tension_ration, _fishing_rod.fishing_float.global_position, _player.global_position)


# TODO: refactor
func _physics_process(_delta: float) -> void:
	if state == State.Reeling:
		# Move the float away from the player
		var float_direction_to_target := _fishing_rod.fishing_float.global_position.direction_to(_player.global_position)
		float_direction_to_target.y = 0
		float_direction_to_target = float_direction_to_target.normalized()
		
		match _fish_direction:
			FishDirection.Forward:
				_fishing_rod.fishing_float.apply_central_force(-float_direction_to_target * 0.1)
			FishDirection.Right:
				var right_direction := -float_direction_to_target.cross(Vector3.UP).normalized()
				_fishing_rod.fishing_float.apply_central_force(right_direction * 0.1)
			FishDirection.Left:
				var left_direction := float_direction_to_target.cross(Vector3.UP).normalized()
				_fishing_rod.fishing_float.apply_central_force(left_direction * 0.1)


# NOTE: maybe passively ticking fish interest rate when baiting?
func _start_fishing() -> void:
	print("Started fishing")
	_current_session = FishingSession.new()
	_current_fish_interest = 0
	state = State.Baiting
	on_state_changed.emit(state)
	trial_number = 1
	_reset_timers()
	_reset_distraction_timer()


func _complete_trial() -> void:
	print("Trial completed")
	_current_session.total_trials += 1
	_current_session.complete_trials += 1
	_float_ui_viewport.visible = false
	_current_fish_interest += interest_gain_on_complete
	_fishing_rod.fishing_float.emit_success_particles()
	trial_number += 1
	_reset_timers()


func _fail_trial() -> void:
	print("Trial failed")
	_current_session.total_trials += 1
	_float_ui_viewport.visible = false
	_current_fish_interest -= interest_loss_on_fail
	_fishing_rod.fishing_float.emit_fail_particles()
	_reset_timers()


func _miss_trial() -> void:
	print("Trial missed")
	_current_fish_interest -= interest_loss_on_miss
	_fishing_rod.fishing_float.emit_fail_particles()


func _catch_fish() -> void:
	var fish_scene: PackedScene = fish_scenes.pick_random()
	
	if fish_scene:
		# Create a new instance of the fish
		var fish_instance: Fish = fish_scene.instantiate()
		
		if fish_instance:
			# Add the fish and snap it to the fish snap zone
			add_child(fish_instance)
			fish_instance.global_position = _fishing_rod.fish_snap_zone.global_position
			_fishing_rod.fish_snap_zone.pick_up_object(fish_instance)
			
			fish_caught.emit(fish_instance)


func _finish_fishing() -> void:
	print("Finished fishing")
	_float_ui_viewport.visible = false
	trial_number = 0
	_trial_timer.stop()
	_catch_timer.stop()
	_reel_timer.stop()
	_distraction_timer.stop()
	state = State.Sleeping
	_fishing_rod.tension = 0.0
	on_state_changed.emit(state)
	StatisticsManager.user_statistics.add_fishing_session(
		_current_session.fish_caught,
		_current_session.rod_snapped,
		_current_session.total_trials,
		_current_session.complete_trials
	)


func _reset_distraction_timer() -> void:
	_distraction_timer.wait_time = _get_time_until_distraction()
	_distraction_timer.start()


func _reset_timers() -> void:
	_trial_timer.wait_time = _get_time_until_next_trial()
	_catch_timer.wait_time = catch_window
	_trial_timer.start()


## Calculates the randomised time until next trial.
func _get_time_until_next_trial() -> float:
	var randomness := trial_time * trial_wait_time_randomness
	var time_until_next_trial := randf_range(trial_time - randomness, trial_time + randomness)
	return time_until_next_trial


## Calculates the randomised time until next distraction.
func _get_time_until_distraction() -> float:
	var randomness := distraction_time * distraction_time_randomness
	var time := randf_range(distraction_time - randomness, distraction_time + randomness)
	return time


func _on_fishing_rod_snapped() -> void:
	_current_session.rod_snapped = true
	_finish_fishing()


func _on_fishing_rod_yanked(yank_velocity: Vector3) -> void:
	match state:
		State.Reeling:
			# TODO: match this with the lock distance
			if _fishing_rod.fishing_float.distance_to_target < _fishing_rod.float_reset_distance + 0.2:
				_current_session.fish_caught = true
				_catch_fish()
				_finish_fishing()
				_fishing_rod.fishing_float.state = FishingFloat.State.Attached
		State.Baiting:
			if can_catch:
				print("Processing a correctly timed yank")
				_catch_timer.stop()
				can_catch = false
				
				var yank_direction : Vector3 = yank_velocity.normalized()
				var fish_direction : Vector3
				match _fish_direction:
					FishDirection.Forward:
						fish_direction = _fishing_rod.fishing_float.global_basis.y
					FishDirection.Right:
						fish_direction = -_fishing_rod.fishing_float.global_basis.x
					FishDirection.Left:
						fish_direction = _fishing_rod.fishing_float.global_basis.x
				var alignment : float = yank_direction.dot(fish_direction)
				print("Alignment was ", alignment)
				var correct_direction : bool = alignment > 0.2
				
				if correct_direction:
					print("Direction was correct")
					if _current_fish_interest < fish_interest_threshold:
						_complete_trial()
					else:
						_fishing_rod.fishing_float.emit_success_particles()
						state = State.Reeling
						on_state_changed.emit(state)
						_reel_timer.start()
				else:
					print("Direction was wrong")
					_fail_trial()
			else:
				_miss_trial()
				


## Connected to the timeout of the trial timer - when the moment to catch comes.
func _on_trial_timer_timeout() -> void:
	_randomize_fish_direction()
	
	_float_ui_viewport.visible = true
	_fishing_rod.fishing_float.plunge()
	can_catch = true
	_catch_timer.start()


func _randomize_fish_direction() -> void:
	var random := randi_range(0, 2)
	match random:
		0:
			_fish_direction = FishDirection.Forward
			print("Fish direction set to forward")
		1:
			_fish_direction = FishDirection.Left
			print("Fish direction set to left")
		2:
			_fish_direction = FishDirection.Right
			print("Fish direction set to right")


## Connected to the timeout of the catch timer - when the moment to catch passes.
func _on_catch_timer_timeout() -> void:
	can_catch = false
	_fail_trial()


func _on_distraction_timer_timeout() -> void:
	if state != State.Sleeping:
		_reset_distraction_timer()
		var available_distractions := distractions.filter(func(d: Distraction) -> bool: return not d.active)
		if available_distractions.size() > 0:
			var available_distraction: Distraction = available_distractions.pick_random()
			available_distraction.activate(_random_position_for_distraction(), _fishing_rod)


func _check_fishing_rod_reset() -> void:
	if (
			_fishing_rod._moved and not _fishing_rod.is_picked_up() and _player 
			and _fishing_rod.global_position.distance_to(_player.global_position) > 10.0
	):
		_fishing_rod.reset()


func _random_position_for_distraction() -> Vector3:
	var float_position := _fishing_rod.fishing_float.global_position
	# TODO: this can go beyond fishable water
	# Get random coords in circle around float
	var angle := randf() * TAU
	var radius := randf_range(min_distance, max_distance)
	var pos_x := float_position.x + cos(angle) * radius
	var pos_z := float_position.z + sin(angle) * radius
	var pos_y := 0 # global_position.y
	return Vector3(pos_x, pos_y, pos_z)


class FishingSession:
	var fish_caught: bool = false
	var rod_snapped: bool = false
	var total_trials: int = 0
	var complete_trials: int = 0
