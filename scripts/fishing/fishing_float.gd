class_name FishingFloat
extends RigidBody3D

## The float of the fishing rod.
##
## Handles the float's positioning at the rod, disconnecting from the rod,
## resetting back to it and its behaviour in water.

@export_category("Floating and bobbing")

## The force that pushes the float upwards when plunging under water.
@export var float_force: float = 1

## The force that is applied downwards during a fishing trial.
@export var plunge_force: float = 0.4

## The amplitude of the bobbing - max height / depth from water surface the float will reach.
@export var bobbing_amplitude: float = 0.1 

## The period of the bobbing. Increase to make bobbing slower.
@export var bobbing_period: float = 1.0

## The period of the float rotation during bobbing. Increase to make rotation slower.
@export var rotation_period: float = 3.0

## The amplitude of the rotation (in radians).
@export var rotation_amplitude : float = 0.2

@export_category("Distance from fishing rod")

## The maximum distance the float can go from the fishing rod before it is reset.
@export var max_distance: float = 10.0

## The maximum distance the float can go from the fishing rod before it is reset during fishing.
## This should be higher so that it doesn't reset upon plunging.
@export var max_fishing_distance: float = 12.0

## The minimum scale of the float mesh. It will be at this scale while on the rod.
@export var min_mesh_scale: float = 0.02

## The maximum scale of the float mesh. It will reach this scale at max distance or upon reaching water. 
@export var max_mesh_scale: float = 0.6

## Determines if the float is connected to the fishing rod
var connected: bool = true

## Determines if the float is in water.
var in_water: bool = false

## Determines if the float is plunging into water and enables float force.
var _plunging: bool = false

## Determines if the float is bobbing at the water surface.
var _bobbing: bool = false

## Variable that keeps track of the bobbing oscillation time.
var _bobbing_time: float = 0.0

## Variable that keeps track of the rotation oscillation time.
var _rotation_time: float = 0.0

## The current distance from the rod to the float.
var _distance: float = 0.0

## The mesh of the float, used for changing the visual scale.
@onready var mesh: MeshInstance3D = get_node("FloatMesh")

## The fishing rod.
@onready var fishing_rod: FishingRod = get_node("../")

## The float target that the float is attached to when connected.
@onready var target: Node3D = fishing_rod.get_node("FloatTarget") if fishing_rod else null

## The particle system of the float, used for emitting success particles.
@onready var particles: GPUParticles3D = get_node("SuccessParticles")

@onready var splash_particles: GPUParticles3D = get_node("SplashParticles")

## The fishing water.
@onready var water: FishingWater = get_tree().get_first_node_in_group("water")

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_instance_valid(fishing_rod):
		set_process(false)
		set_physics_process(false)
		return
	
	# Set the top level in code for better editor representation
	top_level = true
	
	fishing_rod.action_pressed.connect(_on_action_pressed)
	
	# Make sure the float is reset
	_reset()


# Called every frame
func _process(_delta: float) -> void:
	if not connected and not in_water:
		_adjust_mesh_scale()


# Called every physics frame
func _physics_process(_delta: float) -> void:
	if connected:
		set_position_at_target()
	
	if not connected:
		_update_distance_to_rod()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if in_water:
		if _plunging:
			_control_plunging(state)
			return
		
		if _bobbing:
			_bob_in_water(state)


## Controls the float's bobbing when it is on the water surface.
func _bob_in_water(state: PhysicsDirectBodyState3D) -> void:
	# Increment time variables by the physics frame duration
	_bobbing_time += state.step  
	_rotation_time += state.step
	
	var target_y := water.global_position.y + bobbing_amplitude * sin(TAU / bobbing_period * _bobbing_time)  # Calculate the target y using a sine wave
	
	# Calculate the angles for rotation based on sine and cosine waves
	var angle_x := rotation_amplitude * cos(TAU / rotation_period * _rotation_time)
	var angle_z := rotation_amplitude * sin(TAU / rotation_period * _rotation_time)
	
	# Create quaternions for rotations around X and Z axes
	var quat_x := Quaternion(Vector3(1, 0, 0), angle_x)
	var quat_z := Quaternion(Vector3(0, 0, 1), angle_z)
	
	# Combine the two quaternions
	var combined_quat := quat_x * quat_z
	
	# Apply the new position and combined quaternion to the rigid body's transform
	var current_transform := state.transform
	current_transform.origin.y = target_y
	current_transform.basis = Basis(combined_quat)
	state.set_transform(current_transform)


## Controls the plunging into water - applies float force until float reaches surface.
func _control_plunging(state: PhysicsDirectBodyState3D) -> void:
	if state.linear_velocity.y < 0 or global_position.y < water.global_position.y:
		apply_force(Vector3.UP * (mass * gravity + float_force))
	else:
		_plunging = false
		_bobbing_time = 0.0
		_bobbing = true


## Updates the current distance from the float to the fishing rod.
func _update_distance_to_rod() -> void:
	_distance = global_position.distance_to(target.global_position)
	if not in_water and _distance > max_distance:
		_reset()
	if in_water and _distance > max_fishing_distance:
		_reset()


## Used to calculate the scale the float mesh should be at the current distance.
func _adjust_mesh_scale() -> void:
	mesh.scale = Vector3.ONE * (_distance / max_distance * (max_mesh_scale - min_mesh_scale) + min_mesh_scale)


## Resets the float back to the fishing rod.
func _reset() -> void:
	freeze = true
	connected = true
	# Reset the mesh scale
	mesh.scale = Vector3.ONE * min_mesh_scale
	global_rotation = Vector3.ZERO


## Releases the float from the fishing rod.
func _release() -> void:
	connected = false
	freeze = false
	linear_velocity = target.estimated_velocity


## Sets the position of the float at the position of the float target
func set_position_at_target() -> void:
	global_position = target.global_position


## Called by water on fishing trial to plunge float.
func plunge() -> void:
	_bobbing = false
	apply_central_impulse(Vector3.DOWN * plunge_force)
	_plunging = true
	splash_particles.set_emitting(true)


## Called by water upon successful fishing trial.
func emit_particles() -> void:
	particles.set_emitting(true)


## Handles the interaction signal from the fishing rod.
func _on_action_pressed(_pickable: Variant) -> void:	
	if not connected:
		_reset()
	else:
		_release()


## Detects collisions with other bodies and resets the float upon touching something.
func _on_body_entered(body: Node) -> void:
	var layer: int = body.get_collision_layer()
	if layer and layer != pow(2,9): 
		_reset()


## Func that handles the entry into water - sets bools and maxes out the mesh scale.
## Called by the water.
func on_water_entered(_water_height: float) -> void:
	print_verbose("Fishing float entered water at: ", global_position)
	in_water = true
	_plunging = true
	mesh.scale = Vector3.ONE * max_mesh_scale # increase the scale of the float mesh to max
	splash_particles.set_emitting(true)


## Handles the exit from water - resets all bools and variables related to water.
## Called by the water.
func on_water_exited() -> void:
	in_water = false
	_plunging = false
	_bobbing = false
	_bobbing_time = 0.0
	_rotation_time = 0.0
