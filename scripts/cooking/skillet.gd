class_name Skillet
extends MeshInstance3D

# TODO: think about multiple cookables

@onready var _sound: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")
@onready var cooking_timer: Timer = get_node("CookingTimer")
@onready var outside_timer: Timer = get_node("OutsideTimer")
@onready var _steam_particles: GPUParticles3D = get_node("Steam")
@onready var _smoke_particles: GPUParticles3D = get_node("Smoke")
@onready var _fire_particles: GPUParticles3D = get_node("Fire")

var _cookable_in_skillet: Cookable

var in_heat_area: bool:
	get:
		return in_heat_area
	set(value):
		in_heat_area = value
		#print("Skillet: in_heat_area changed to ", in_heat_area)
		_update_cooking()


func _update_cooking() -> void:
	if in_heat_area and _cookable_in_skillet:
		#print("Skillet: in heat, enabling cooking")
		_cookable_in_skillet.start_cooking()
		_steam_particles.emitting = true
		cooking_timer.start()
	elif _cookable_in_skillet:
		#print("Skillet: not in heat, disabling cooking")
		_cookable_in_skillet.stop_cooking()
		_steam_particles.emitting = false
		cooking_timer.stop()
		outside_timer.start()


func _add_cookable(cookable: Cookable) -> void:
	_cookable_in_skillet = cookable
	_cookable_in_skillet.cooking_completed.connect(_on_cooking_completed)
	#print("Skillet: added cookable ", _cookable_in_skillet)
	_update_cooking()


func _remove_cookable() -> void:
	_cookable_in_skillet.stop_cooking()
	_cookable_in_skillet.cooking_completed.disconnect(_on_cooking_completed)
	#print("Skillet: removed cookable ", _cookable_in_skillet)
	_cookable_in_skillet = null
	_steam_particles.emitting = false
	_smoke_particles.emitting = false
	cooking_timer.stop()


func _on_cooking_area_body_entered(body: Node3D) -> void:
	# Check if the entering body is in the "Cookable" group
	# and there isn't anything else cooking
	#print("Skillet: body ", body, " entered cooking area")
	if body.is_in_group("Cookable") and not _cookable_in_skillet:
		body = body as RigidBody3D
		
		# Reset velocity
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		
		if body.rotation.z < 0:
			_add_cookable(body.get_node("MeshLeft"))
			#var left_side: Cookable = body.get_node("MeshLeft")
			#left_side.cooking_completed.connect(_on_cooking_completed)
			#left_side.start_cooking()
		else:
			_add_cookable(body.get_node("MeshRight"))
			#var right_side: Cookable = body.get_node("MeshRight")
			#right_side.cooking_completed.connect(_on_cooking_completed)
			#right_side.start_cooking()


func _on_cooking_area_body_exited(body: Node3D) -> void:
	#print("Skillet: body ", body, " exited cooking area")
	if body.is_in_group("Cookable"):
		var left_side: Cookable = body.get_node("MeshLeft")
		var right_side: Cookable = body.get_node("MeshRight")
		if _cookable_in_skillet == left_side || _cookable_in_skillet == right_side:
			_remove_cookable()


func _on_cooking_completed() -> void:
	#print("Skillet: cooking complete, emitting smoke")
	_steam_particles.emitting = false
	_smoke_particles.emitting = true

func _on_cooking_timer_timeout() -> void:
	#print("Skillet: cooking timer timedout, emitting fire")
	_fire_particles.emitting = true

func _on_outside_timer_timeout() -> void:
	#print("Skillet: outside timer timedout, stopping fire")
	if _fire_particles.emitting:
		_sound.playing = true
		_fire_particles.emitting = false
