class_name FishingWater
extends Area3D


## The fish scenes that will be spawned upon catching.
const RaudeScene = preload("res://scenes/fishing/fishes/raude.tscn")
const KuojaScene = preload("res://scenes/fishing/fishes/kuoja.tscn")
const LynasScene = preload("res://scenes/fishing/fishes/lynas.tscn")

# NOTE: if we ever want to save some extra memory for other activities, distractions could
# all be preloaded and only instantiated when fishing starts instead of being children to this node
#const DistractionFishScene = preload("res://scenes/fishing/distractions/distraction_fish.tscn")
#const DistractionWindScene = preload("res://scenes/fishing/distractions/distraction_wind.tscn")

signal on_state_changed(new_state: FishingState)

@export_group("Fishing")

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
@export_range(0.0, 1.0) var trial_wait_time_randomness: float = 0.2

## The time between distractions.
@export var distraction_time: float = 2.0

## Multiplyer that determines the randomness of time between distractions.
@export_range(0.0, 1.0) var distraction_time_randomness: float = 0.0

## The time in seconds that the player has to react to a trial.
@export var catch_window: float = 1.0

@export_group("Distractions")

## The maximum distance a distraction can spawn from the float
@export var max_distance: float = 6.0

## The minimum distance a distraction can spawn from the float
@export var min_distance: float = 2.0

var can_catch: bool = false

var trial_number: int = 0

@onready var trial_timer: Timer = get_node("TrialTimer")

@onready var catch_timer: Timer = get_node("CatchTimer")

@onready var reel_timer: Timer = get_node("ReelTimer")

@onready var distraction_timer: Timer = get_node("DistractionTimer");

## The fishing rod.
@onready var fishing_rod: FishingRod = get_tree().get_first_node_in_group("fishing_rod")

## The fishing float.
@onready var fishing_float: FishingFloat = fishing_rod.get_node("FishingFloat") if fishing_rod else null

## The player (needed to target the fish).
@onready var player: XROrigin3D = get_tree().get_first_node_in_group("player")

@onready var water_mesh: MeshInstance3D = get_node("../")

@onready var water_shader: ShaderMaterial

@onready var distraction_kuoja: DistractionFish = get_node("DistractionKuoja")

@onready var distraction_raude: DistractionFish = get_node("DistractionRaude")

@onready var distraction_lynas: DistractionFish = get_node("DistractionLynas")

@onready var distraction_wind: DistractionWind = get_node("DistractionWind")

@onready var float_ui_viewport: FishingFloatUIViewport = get_node("FishingFloatUIViewport")

var wind_distraction: bool = false
var wind_transition_speed: float = 0.2
var wind_transition_time: float = 0.0

var _current_fish_interest: float = 0

var distractions: Array[Distraction] = []

var fish_scenes: Array[PackedScene] = []

var current_state: FishingState = FishingState.Sleeping

var _current_reeling_direction: ReelingDirection = ReelingDirection.Forward


enum FishingState 
{
	Sleeping, # not currently fishing
	Baiting,
	Reeling
}

# The direction (from the player's perspective) that the fish is pushing the float
enum ReelingDirection
{
	Forward,
	Left,
	Right,
}


func _ready() -> void:
	fishing_rod.tugged.connect(_on_fishing_rod_tugged)
	float_ui_viewport.visible = false
	
	if water_mesh:
		water_shader = water_mesh.get_surface_override_material(0)
	
	if distraction_kuoja:
		distractions.append(distraction_kuoja)
	if distraction_raude:
		distractions.append(distraction_raude)
	if distraction_lynas:
		distractions.append(distraction_lynas)
	if distraction_wind:
		distractions.append(distraction_wind)
		
	fish_scenes.append(RaudeScene)
	fish_scenes.append(KuojaScene)
	fish_scenes.append(LynasScene)


func _physics_process(_delta: float) -> void:
	if current_state == FishingState.Reeling:
		# Move the float away from the player
		var float_direction_to_target := fishing_float.global_position.direction_to(player.global_position)
		float_direction_to_target.y = 0
		float_direction_to_target = float_direction_to_target.normalized()
		
		match _current_reeling_direction:
			ReelingDirection.Forward:
				fishing_float.apply_central_force(-float_direction_to_target * 0.1)
			ReelingDirection.Right:
				var right_direction := float_direction_to_target.cross(Vector3.UP).normalized()
				fishing_float.apply_central_force(right_direction * 0.1)
			ReelingDirection.Left:
				var left_direction := -float_direction_to_target.cross(Vector3.UP).normalized()
				fishing_float.apply_central_force(left_direction * 0.1)


# NOTE: maybe passively ticking fish interest rate when baiting?
func _start_fishing() -> void:
	_current_fish_interest = 0
	current_state = FishingState.Baiting
	on_state_changed.emit(current_state)
	trial_number = 1
	_reset_timers()
	_reset_distraction_timer()


func _complete_trial() -> void:
	float_ui_viewport.visible = false
	_current_fish_interest += interest_gain_on_complete
	fishing_float.emit_success_particles()
	trial_number += 1
	_reset_timers()


func _fail_trial() -> void:
	float_ui_viewport.visible = false
	_current_fish_interest -= interest_loss_on_fail
	fishing_float.emit_fail_particles()
	_reset_timers()


func _catch_fish() -> void:
	var fish_spawn_position := fishing_float.global_position
	var fish_scene: PackedScene = fish_scenes.pick_random()
	
	if fish_scene:
		# Create a new instance of the fish
		var fish_instance: Fish = fish_scene.instantiate()
		
		if fish_instance:
			# Add the fish and set it up
			fish_instance.visible = false
			fish_instance.freeze = true
			add_child(fish_instance)
			fish_instance.global_position = fish_spawn_position
			
			# Apply the impulse at the initial spawn
			var impulse := _get_fish_launch_impulse(fish_instance)
			fish_instance.freeze = false
			fish_instance.visible = true
			fish_instance.apply_central_impulse(impulse)


func _get_fish_launch_impulse(fish: Fish) -> Vector3:
	# TODO: move launch variables to export
	var launch_angle: float = PI / 3
	var time_to_target: float = 2
	var g: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	var offset_to_player := player.global_position - fish.global_position
	
	# Calculate the horizontal distance in the XZ-plane
	var horizontal_displacement := Vector3(offset_to_player.x, 0, offset_to_player.z)
	var horizontal_distance := horizontal_displacement.length()
	
	# Calculate horizontal velocity component using the target time and launch angle
	var horizontal_velocity := horizontal_distance / (cos(launch_angle) * time_to_target)
	
	# Direction vector for horizontal motion in the XZ plane
	var horizontal_direction := horizontal_displacement.normalized()
	
	# Calculate vertical velocity to ensure the projectile reaches the target height and position in time_to_target
	var vertical_velocity := (offset_to_player.y + 1.0 + 0.5 * g * pow(time_to_target, 2)) / time_to_target
	
	# Combine horizontal and vertical components to form the initial velocity vector
	var initial_velocity := horizontal_direction * horizontal_velocity
	initial_velocity.y = vertical_velocity * 1.4 # TODO: ammend formula so I don't need this weird multiplier
	
	return initial_velocity * fish.mass


func _finish_fishing() -> void:
	float_ui_viewport.visible = false
	trial_number = 0
	trial_timer.stop()
	catch_timer.stop()
	reel_timer.stop()
	distraction_timer.stop()
	current_state = FishingState.Sleeping
	on_state_changed.emit(current_state)


func _reset_distraction_timer() -> void:
	distraction_timer.wait_time = _get_time_until_distraction()
	distraction_timer.start()


func _reset_timers() -> void:
	trial_timer.wait_time = _get_time_until_next_trial()
	catch_timer.wait_time = catch_window
	trial_timer.start()


## Calculates the randomised time until next trial.
func _get_time_until_next_trial() -> float:
	var randomness := trial_time * trial_wait_time_randomness
	var time_until_next_trial := randf_range(trial_time - randomness, trial_time + randomness)
	return time_until_next_trial


func _get_time_until_distraction() -> float:
	var randomness := distraction_time * distraction_time_randomness
	var time := randf_range(distraction_time - randomness, distraction_time + randomness)
	return time


## Handles the entry of the fishable water. 
## Connected to the body entered signal of this node.
func _on_water_entered(body: Node3D) -> void:
	# Check if the body that landed in the water has a func for processing this event
	if body.has_method("on_water_entered"):
		# Call it if it does
		body.on_water_entered(global_position.y)
		if body == fishing_float:
			_start_fishing()
	else:
		print_verbose("An unrecognised body has entered the water: " + str(body))


## Handles the exit of the fishable water. 
## Connected to the body exited signal of this node.
func _on_water_exited(body: Node3D) -> void:
	# Check if the body that exited the water has a func for processing this event
	if body.has_method("on_water_exited"):
		# Call it if it does
		body.on_water_exited()
		if body == fishing_float:
			_finish_fishing()
	else:
		pass
		print("An unrecognised body has exited the water: " + str(body))


## Handles the fishing rod tug.
func _on_fishing_rod_tugged() -> void:
	# Exit early if not fishing
	if current_state == FishingState.Sleeping:
		return
	
	# TODO: match this with the lock distance
	if current_state == FishingState.Reeling and fishing_float.distance_to_target < 2.2:
		_catch_fish()
		_finish_fishing()
		fishing_float.reset()
	
	if current_state == FishingState.Baiting:
		if can_catch:
			catch_timer.stop()
			can_catch = false
			if _current_fish_interest < fish_interest_threshold:
				_complete_trial()
			else:
				fishing_float.emit_success_particles()
				current_state = FishingState.Reeling
				on_state_changed.emit(current_state)
				reel_timer.start()
		else:
			_current_fish_interest -= interest_loss_on_miss
			fishing_float.emit_fail_particles()


## Connected to the timeout of the trial timer - when the moment to catch comes.
func _on_trial_timer_timeout() -> void:
	var random := randi_range(0, 1)
	if random == 0:
		float_ui_viewport.scene_node.state = FishingFloatUI.State.DirectionArrowRight
	else:
		float_ui_viewport.scene_node.state = FishingFloatUI.State.DirectionArrowLeft
	float_ui_viewport.visible = true
	fishing_float.plunge()
	can_catch = true
	catch_timer.start()


## Connected to the timeout of the catch timer - when the moment to catch passes.
func _on_catch_timer_timeout() -> void:
	can_catch = false
	_fail_trial()


func _on_distraction_timer_timeout() -> void:
	if current_state != FishingState.Sleeping:
		_reset_distraction_timer()
		var available_distractions := distractions.filter(func(d: Distraction) -> bool: return not d.active)
		if available_distractions.size() > 0:
			var available_distraction: Distraction = available_distractions.pick_random()
			available_distraction.activate(_random_position_for_distraction(), fishing_rod)


func _on_reel_timer_timeout() -> void:
	# Change the reeling direction
	var random := randi_range(0, 2)
	match random:
		0:
			_current_reeling_direction = ReelingDirection.Forward
		1:
			_current_reeling_direction = ReelingDirection.Right
		2:
			_current_reeling_direction = ReelingDirection.Left


func _random_position_for_distraction() -> Vector3:
	var float_position := fishing_float.global_position
	# TODO: this can go beyond fishable water
	# Get random coords in circle around float
	var angle := randf() * TAU
	var radius := randf_range(min_distance, max_distance)
	var pos_x := float_position.x + cos(angle) * radius
	var pos_z := float_position.z + sin(angle) * radius
	var pos_y := global_position.y
	return Vector3(pos_x, pos_y, pos_z)
