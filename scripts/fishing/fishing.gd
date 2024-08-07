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

@export_category("Fishing")

## Number of times the player needs to correctly click to catch the fish.
@export var number_of_trials: int = 3

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
@export var catch_windown: float = 1.0

@export_category("Distractions")

## The maximum distance a distraction can spawn from the float
@export var max_distance: float = 6.0

## The minimum distance a distraction can spawn from the float
@export var min_distance: float = 2.0

var can_catch: bool = false

var trial_number: int = 0

var fishing_in_progress: bool = false

@onready var trial_timer: Timer = get_node("TrialTimer")

@onready var catch_timer: Timer = get_node("CatchTimer")

@onready var distraction_timer: Timer = get_node("DistractionTimer");

## The fishing rod container.
@onready var fishing_rod: FishingRod = get_node("../../FishingRod/FishingRod")

## The fishing float.
@onready var fishing_float: FishingFloat = get_node("../../FishingRod/FishingFloat")

## The player (needed to target the fish).
@onready var player: XROrigin3D = get_node("../../XROrigin3D")

@onready var water_mesh: MeshInstance3D = get_node("../")

@onready var water_shader: ShaderMaterial

@onready var distraction_kuoja: DistractionFish = get_node("DistractionKuoja")

@onready var distraction_raude: DistractionFish = get_node("DistractionRaude")

@onready var distraction_lynas: DistractionFish = get_node("DistractionLynas")

@onready var distraction_wind: DistractionWind = get_node("DistractionWind")

var wind_distraction: bool = false
var wind_transition_speed: float = 0.2
var wind_transition_time: float = 0.0

var distractions: Array[Distraction] = []

var fish_scenes: Array[PackedScene] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	#fishing_rod.action_pressed.connect(_on_fishing_rod_action)
	fishing_rod.tugged.connect(_on_fishing_rod_tugged)
	
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


func _start_fishing():
	trial_number = 1
	_reset_timers()
	_reset_distraction_timer()
	fishing_in_progress = true

func _complete_trial():
	fishing_float.emit_particles()
	trial_number += 1
	_reset_timers()
	
func _fail_trial():
	_reset_timers()

func _catch_fish():
	var fish_spawn_position = fishing_float.global_position
	var fish_scene = fish_scenes.pick_random()
	
	if fish_scene:
		# Create a new instance of the fish
		var fish_instance = fish_scene.instantiate()
		
		if fish_instance:
			# Add the fish and set it up
			add_child(fish_instance)
			#fish_instance.set_mesh_scale(Vector3(10, 10, 10))
			fish_instance.global_position = fish_spawn_position

			# Calculate initial velocity to hit the target with an arched trajectory
			var displacement = player.global_position - fish_spawn_position
			var time_to_reach_target = displacement.y / gravity
			var horizontal_velocity = Vector3(displacement.x / (time_to_reach_target * 10), 0, displacement.z / (time_to_reach_target * 10)) # Slower horizontal velocity
			var vertical_velocity = Vector3(0, gravity * (time_to_reach_target * 6), 0) # Higher vertical velocity
			# TODO: the linear velocity should be set in _integrate_forces(), not in a wholy different script
			fish_instance.linear_velocity = horizontal_velocity + vertical_velocity
			# TODO: implement a cap on the fish impulse so it wouldn't fly out of the map


func _finish_fishing():
	fishing_in_progress = false
	trial_number = 0
	trial_timer.stop()
	catch_timer.stop()
	distraction_timer.stop()

func _reset_distraction_timer():
	distraction_timer.wait_time = _get_time_until_distraction()
	distraction_timer.start()

func _reset_timers():
	trial_timer.wait_time = _get_time_until_next_trial()
	catch_timer.wait_time = catch_windown
	trial_timer.start()


## Calculates the randomised time until next trial.
func _get_time_until_next_trial() -> float:
	var randomness = trial_time * trial_wait_time_randomness
	var time_until_next_trial = randf_range(trial_time - randomness, trial_time + randomness)
	return time_until_next_trial

func _get_time_until_distraction() -> float:
	var randomness = distraction_time * distraction_time_randomness
	var time = randf_range(distraction_time - randomness, distraction_time + randomness)
	return time

## Handles the entry of the fishable water. 
## Connected to the body entered signal of this node.
func _on_water_entered(body: Node3D):
	# Check if the body that landed in the water has a func for processing this event
	if body.has_method("on_water_entered"):
		# Call it if it does
		body.on_water_entered(global_position.y)
		if body == fishing_float:
			_start_fishing()
	else:
		pass
		print("An unrecognised body has entered the water: " + str(body))


## Handles the exit of the fishable water. 
## Connected to the body exited signal of this node.
func _on_water_exited(body: Node3D):
	# Check if the body that exited the water has a func for processing this event
	if body.has_method("on_water_exited"):
		# Call it if it does
		body.on_water_exited()
		if body == fishing_float:
			_finish_fishing()
	else:
		pass
		print("An unrecognised body has exited the water: " + str(body))


## Handles the logic upon fishing rod action. 
## Connected to the action_pressed signal of the fishing rod container.
#func _on_fishing_rod_action(_pickable: Variant):
	#pass


## Handles the fishing rod tug.
func _on_fishing_rod_tugged():
	if can_catch:
		catch_timer.stop()
		can_catch = false
		if trial_number < number_of_trials:
			_complete_trial()
		else:
			_catch_fish()
			_finish_fishing()
			fishing_float._reset()


## Connected to the timeout of the trial timer - when the moment to catch comes.
func _on_trial_timer_timeout():
	fishing_float.plunge()
	can_catch = true
	catch_timer.start()


## Connected to the timeout of the catch timer - when the moment to catch passes.
func _on_catch_timer_timeout():
	can_catch = false
	_fail_trial()


func _on_distraction_timer_timeout():
	if fishing_in_progress:
		_reset_distraction_timer()
		var available_distractions = distractions.filter(func(d: Distraction): return not d.active)
		if available_distractions.size() > 0:
			var available_distraction: Distraction = available_distractions.pick_random()
			available_distraction.activate(_random_position_for_distraction(), fishing_rod)
		else:
			print("No available distractions were found") # TODO: get rid of this, only for debug

func _random_position_for_distraction() -> Vector3:
	var float_position = fishing_float.global_position
	# TODO: this can go beyond fishable water
	# Get random coords in circle around float
	var angle = randf() * TAU
	var radius = randf_range(min_distance, max_distance)
	var pos_x = float_position.x + cos(angle) * radius
	var pos_z = float_position.z + sin(angle) * radius
	var pos_y = global_position.y
	return Vector3(pos_x, pos_y, pos_z)
