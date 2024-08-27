class_name Puntukas
extends Node3D

signal toggle_creature_movement

## The maximum distance to player at which the mini game is active
@export var _max_distance_to_player: float = 15

@onready var _player: Player = get_node("/root/Staging/Scene/Main/XROrigin3D")
@onready var eye1: GPUParticles3D = $Fire/GPUParticles3D
@onready var eye2: GPUParticles3D = $Fire2/GPUParticles3D
@onready var sound_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _active: bool = false
var _curr_distance_to_player: float
var _on_fire: bool = false
var _interval: float = 5.0
var _time_accumulator: float = 0.0


func _process(delta: float) -> void:
	_curr_distance_to_player = global_position.distance_to(_player.global_position)
	if _curr_distance_to_player > _max_distance_to_player and _active:
		_active = false
		if _on_fire:
			_on_fire = false
			set_eyes_emitting(false)
			sound_player.stop()
		else:
			toggle_creature_movement.emit()
		_time_accumulator = 0.0
	
	if _curr_distance_to_player <= _max_distance_to_player and not _active:
		_active = true
	
	if _active:
		_time_accumulator += delta
		if _time_accumulator >= _interval:
			_time_accumulator = 0.0
			toggle_creature_movement.emit()
			_on_fire = !_on_fire
			if _on_fire:
				set_eyes_emitting(true)
				if _curr_distance_to_player <= _max_distance_to_player and not sound_player.playing:  # Play sound if within distance
					sound_player.play(0.2)
			else:
				set_eyes_emitting(false)
				sound_player.stop()  # Stop the sound when _on_fire is false


func set_eyes_emitting(to: bool) -> void:
	eye1.emitting = to
	eye2.emitting = to
