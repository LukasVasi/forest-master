class_name Fire
extends Node3D

## The factor of the fire particles' visibility. 0 - particles disabled. 1 - particles at full scale.
@export_range(0.0, 1.0) var fire_ratio: float = 1.0

@onready var _fire_particles: GPUParticles3D = $FireParticles
@onready var _fire_light: OmniLight3D = $FireLight
@onready var _fire_sound: AudioStreamPlayer3D = $FireSound

var _fire_particle_process_material: ParticleProcessMaterial
var _original_scale_min: float = 0.0
var _original_scale_max: float = 0.0
var _original_light_energy: float = 0.0

func _ready() -> void:
	if fire_ratio <= 0.0:
		_fire_particles.emitting = false
		_fire_light.visible = false
		_fire_sound.playing = false
	
	_fire_particle_process_material = _fire_particles.get_process_material().duplicate()
	_fire_particles.set_process_material(_fire_particle_process_material)
	_original_scale_min = max(_fire_particle_process_material.get_param_min(ParticleProcessMaterial.PARAM_SCALE), 0.1)
	_original_scale_max = max(_fire_particle_process_material.get_param_max(ParticleProcessMaterial.PARAM_SCALE), 0.1)
	_original_light_energy = _fire_light.light_energy

func _process(_delta: float) -> void:
	if fire_ratio <= 0.0:
		_fire_particles.emitting = false
		_fire_light.visible = false
		_fire_sound.playing = false
	else:
		_fire_particles.emitting = true
		_fire_particle_process_material.set_param_min(ParticleProcessMaterial.PARAM_SCALE, _original_scale_min * fire_ratio) 
		_fire_particle_process_material.set_param_max(ParticleProcessMaterial.PARAM_SCALE, _original_scale_max * fire_ratio) 
		
		_fire_light.visible = true
		_fire_light.light_energy = _original_light_energy * fire_ratio
		
		if not _fire_sound.playing:
			_fire_sound.play()
