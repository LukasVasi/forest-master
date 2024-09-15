class_name Skillet
extends MeshInstance3D

@export var cooking_speed: float = 0.1

@onready var _sound: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")
@onready var cooking_timer: Timer = get_node("CookingTimer")
@onready var outside_timer: Timer = get_node("OutsideTimer")
@onready var _steam_particles: GPUParticles3D = get_node("Steam")
@onready var _smoke_particles: GPUParticles3D = get_node("Smoke")
@onready var _fire_particles: GPUParticles3D = get_node("Fire")

var _cookables_in_skillet: Array[CookableObject]

var in_heat_area: bool:
	get:
		return in_heat_area
	set(value):
		in_heat_area = value
		#print("Skillet: in_heat_area changed to ", in_heat_area)
		_update_cooking()


func _update_cooking() -> void:
	if in_heat_area and _cookables_in_skillet.size() > 0:
		#print("Skillet: in heat, enabling cooking")
		_steam_particles.emitting = true
		cooking_timer.start()
	elif _cookables_in_skillet.size() > 0:
		#print("Skillet: not in heat, disabling cooking")
		_steam_particles.emitting = false
		cooking_timer.stop()
		outside_timer.start()
	else: # no more cookables present
		_steam_particles.emitting = false
		_smoke_particles.emitting = false
		cooking_timer.stop()
		outside_timer.stop()

func _process(delta: float) -> void:
	if in_heat_area:
		var cookable_count: int = _cookables_in_skillet.size()
		if cookable_count > 0:
			for i in range(cookable_count):
				_cookables_in_skillet[i].add_cooking_level(cooking_speed * delta)


func _on_cooking_area_body_entered(body: Node3D) -> void:
	# Check if the entering body is in the "Cookable" group
	# and there isn't anything else cooking
	#print("Skillet: body ", body, " entered cooking area")
	if body.is_in_group("Cookable"):
		body = body as CookableObject
		
		# Reset velocity
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		
		_cookables_in_skillet.append(body)
		_update_cooking()


func _on_cooking_area_body_exited(body: Node3D) -> void:
	#print("Skillet: body ", body, " exited cooking area")
	if _cookables_in_skillet.has(body):
		_cookables_in_skillet.erase(body)
		_update_cooking()


func _on_cooking_timer_timeout() -> void:
	#print("Skillet: cooking timer timedout, emitting fire")
	_fire_particles.emitting = true

func _on_outside_timer_timeout() -> void:
	#print("Skillet: outside timer timedout, stopping fire")
	if _fire_particles.emitting:
		_sound.playing = true
		_fire_particles.emitting = false
