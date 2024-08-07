extends Node3D

signal toggle_creature_movement

@onready var player = get_node("/root/Staging/Scene/Main/XROrigin3D")
@onready var eye1 = $Fire/GPUParticles3D
@onready var eye2 = $Fire2/GPUParticles3D
@onready var sound_player = $AudioStreamPlayer3D


var time_accumulator = 0.0
var interval = 5.0
var degam=false
var max_distance = 12  # Maximum distance to play sound
var distance_to_player : float


func _process(delta):
	distance_to_player = global_position.distance_to(player.global_transform.origin)
	
	time_accumulator += delta
	if time_accumulator >= interval:
		time_accumulator = 0.0
		toggle_creature_movement.emit()
		degam = !degam
		if degam:
			eye1.emitting = true
			eye2.emitting = true
			if distance_to_player <= max_distance and not sound_player.playing:  # Play sound if within distance
				sound_player.play(0.2)
		else:
			eye1.emitting = false
			eye2.emitting = false
			sound_player.stop()  # Stop the sound when degam is false
