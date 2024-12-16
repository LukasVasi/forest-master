class_name Skillet
extends MeshInstance3D

signal fish_cooked

@export_category("Cooking")

## The rate at which the cookable is cooked when at full heat.
@export var cooking_rate : float = 0.3

## The extra cooking rate added when the skillet starts burning.
@export var burning_rate : float = 0.3

## The rate at which the heat of the skillet disapates.
@export var heat_dissipation : float = 0.1

## The rate at which the heat is gained.
@export var heat_gain : float = 0.3

@export var tutorial : bool = false

@onready var _sound: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")
@onready var _session_timeout_timer : Timer = get_node("SessionTimeoutTimer")
@onready var _fire_particles: GPUParticles3D = get_node("Fire")
@onready var _heat_ui_viewport : Node3D = get_node("../UIViewport")
@onready var _heat_ui : TextureProgressBar = _heat_ui_viewport.scene_node

var _cookables_in_skillet: Array[CookableObject]

var in_heat_area: bool:
	get:
		return in_heat_area
	set(value):
		in_heat_area = value
		if in_heat_area:
			_session_timeout_timer.stop()
			StatisticsManager.start_cooking_session()
		else:
			_session_timeout_timer.start()


var heat_ratio: float = 0.0

var _current_heat : float = 0.0

var _is_burning : bool = false

func _ready() -> void:
	_heat_ui_viewport.visible = false


func _process(delta: float) -> void:
	_update_skillet_heat(delta)
	# Check if we are cooking
	if _current_heat > 0.0:
		if not _sound.playing and not _cookables_in_skillet.is_empty():
			_sound.play()
		
		# Determine if we are burning
		if not _is_burning and _current_heat > 0.9:
			_is_burning = true
			_fire_particles.emitting = true
		if _is_burning and _current_heat <= 0.7:
			_is_burning = false
			_fire_particles.emitting = false
		
		# Display the heat ui
		_heat_ui_viewport.visible = true
		_heat_ui_viewport.update()
		_heat_ui.value = _current_heat
		
		# Update the cookables state to display particles
		_cookables_in_skillet.all(func(cookable : CookableObject) -> void: 
			cookable.is_cooking = true
			cookable.is_burning = _is_burning
		)
		
		# Update the cooking progress
		_cookables_in_skillet.all(func(cookable : CookableObject) -> void: 
			var current_cooking_rate : float = cooking_rate + burning_rate if _is_burning else cooking_rate
			cookable.add_cooking_level(current_cooking_rate * _current_heat * delta)
		)
		
		if tutorial and _cookables_in_skillet.any(func(cookable : CookableObject) -> bool: return cookable.is_cooked):
			fish_cooked.emit()
	else:
		if _sound.playing:
			_sound.stop()
		
		_is_burning = false
		_heat_ui_viewport.visible = false
		_cookables_in_skillet.all(func(cookable : CookableObject) -> void: 
			cookable.is_cooking = false
			cookable.is_burning = false
		)


func _update_skillet_heat(delta : float) -> void:
	_current_heat += heat_ratio * heat_gain * delta
	_current_heat -= heat_dissipation * delta
	_current_heat = clampf(_current_heat, 0.0, 1.0)


func _on_cooking_area_body_entered(body: Node3D) -> void:
	# Check if the entering body is in the "Cookable" group
	# and there isn't anything else cooking
	if body is CookableObject:
		_cookables_in_skillet.append(body)


func _on_cooking_area_body_exited(body: Node3D) -> void:
	if body is CookableObject:
		if body in _cookables_in_skillet :
			_cookables_in_skillet.erase(body)
			body.is_cooking = false
			body.is_burning = false


func _on_session_timeout_timer_timeout() -> void:
	StatisticsManager.end_cooking_session()
