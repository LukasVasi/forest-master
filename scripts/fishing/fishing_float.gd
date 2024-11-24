class_name FishingFloat
extends RigidBody3D

## The float of the fishing rod.
##
## Handles the float's positioning at the rod, disconnecting from the rod,
## resetting back to it and its behaviour in water.


enum State {
	Attached,
	Detached,
	Floating,
}


## The current state of the fishing float.
@export var state : State = State.Attached : set = _set_state

## The force that pushes the float upwards when plunging under water.
@export var float_force: float = 1

## The torque that rotates the float upwards when in water.
@export var float_torque: float = 0.2

## The force that is applied downwards during a fishing trial.
@export var plunge_force: float = 0.4

## The maximum distance the float can go from the fishing rod before it is reset.
@export var max_distance: float = 10.0

## The maximum distance the float can go from the fishing rod before it is reset during fishing.
## This should be higher so that it doesn't reset upon plunging.
@export var max_fishing_distance: float = 12.0

## The minimum scale of the float mesh. It will be at this scale while on the rod.
@export var min_mesh_scale: float = 0.02

## The maximum scale of the float mesh. It will reach this scale at max distance or upon reaching water. 
@export var max_mesh_scale: float = 0.6


## The current distance from the rod to the float.
var distance_to_target: float = 0.0


## The mesh of the float, used for changing the visual scale.
@onready var _mesh: MeshInstance3D = get_node("FloatMesh")

## The float target that the float is attached to when connected.
@onready var target: FishingFloatTarget = get_node("../FloatTarget")

## The particle system of the float, used for emitting success particles.
@onready var _success_particles: GPUParticles3D = get_node("SuccessParticles")

## The particle system of the float, used for emitting fail particles.
@onready var _fail_particles: GPUParticles3D = get_node("FailParticles")

@onready var _splash_particles: GPUParticles3D = get_node("SplashParticles")

## The y coordinate of the fishing water.
@onready var _water_height: float = get_tree().get_first_node_in_group("water").global_position.y

@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	target.yanked.connect(_on_fishing_rod_yanked)
	
	_update_state()


func _process(_delta: float) -> void:
	if state == State.Detached:
		_adjust_mesh_scale()


func _physics_process(_delta: float) -> void:
	if not state == State.Attached:
		_update_distance_to_rod()
	if state == State.Floating:
		_float()


func _float() -> void:
	if global_position.y < _water_height:
		apply_central_force(Vector3.UP * (mass * _gravity + float_force))
	
	# TODO: ignore spin
	var quat_delta: Quaternion = Quaternion.IDENTITY * (global_basis.get_rotation_quaternion().inverse())
	var rotation_delta: Vector3 = Vector3(quat_delta.x, quat_delta.y, quat_delta.z) * quat_delta.w
	apply_torque(rotation_delta * 0.2)	


## Updates the horizontal distance from the float to the float target.
func _update_distance_to_rod() -> void:
	var delta_to_target := global_position - target.global_position
	delta_to_target.y = 0 # ingore the height difference
	distance_to_target = delta_to_target.length()
	
	# TODO: very yucky
	if state == State.Detached and distance_to_target > max_distance:
		state = State.Attached
	if state == State.Floating and distance_to_target > max_fishing_distance:
		state = State.Attached


## Used to calculate the scale the float mesh should be at the current distance.
func _adjust_mesh_scale() -> void:
	_mesh.scale = Vector3.ONE * (distance_to_target / max_distance * (max_mesh_scale - min_mesh_scale) + min_mesh_scale)


## Called by water on fishing trial to plunge float.
func plunge() -> void:
	apply_central_impulse(Vector3.DOWN * plunge_force)
	_splash_particles.set_emitting(true)


## Called by water upon successful fishing trial.
func emit_success_particles() -> void:
	_success_particles.set_emitting(true)


## Called by water upon failed fishing trial.
func emit_fail_particles() -> void:
	_fail_particles.set_emitting(true)


## Detects collisions with other bodies and resets the float upon touching something.
func _on_body_entered(body: Node) -> void:
	var layer: int = body.get_collision_layer()
	if layer and layer != pow(2,9): 
		state = State.Attached


func _on_fishing_rod_yanked(yank_velocity: Vector3) -> void:
	apply_central_impulse(
		global_position.direction_to(target.global_position) * 0.05 \
		+ yank_velocity.normalized() * 0.05
		)


func _set_state(new_state : State) -> void:
	state = new_state
	_update_state()


func _update_state() -> void:
	match state:
		State.Attached:
			# Attach the fishing float
			freeze = true
			top_level = false
			_mesh.scale = Vector3.ONE * min_mesh_scale
			call_deferred("_set_position_to_target")
		State.Detached:
			# Detach the fishing float
			top_level = true
			freeze = false
			linear_velocity = target.estimated_velocity
		State.Floating:
			# Process transition to floating
			_mesh.scale = Vector3.ONE * max_mesh_scale # increase the scale of the mesh to max
			_splash_particles.set_emitting(true)


## This is required because setting top level and position in same frame doesn't work.
func _set_position_to_target() -> void:
	global_transform = target.global_transform


## Function that handles the entry into water. Called by the water.
func on_water_entered(_todo: float) -> void:
	state = State.Floating
