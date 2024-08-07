extends MeshInstance3D

signal start_cooking
signal stop_cooking
signal cooking_completed

enum FishState {
	NORMAL,
	ON_BLIUDAS
}

var skillet_in_cooking_area = false  # Track if skillet is in cooking area
@onready var steam_particles: GPUParticles3D = get_node("Steam")
@onready var smoke_particles: GPUParticles3D = get_node("Smoke")
@onready var sound: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")
@onready var fire_particles: GPUParticles3D = get_node("Fire")
@onready var cooking_timer: Timer = Timer.new()
@onready var outside_timer: Timer = Timer.new()
var fish_state = FishState.NORMAL

func _ready():
	# Connect the body_entered signal of the Area3D to the "_on_area_body_entered" function
	var area = $Area3D
	if area:
		area.connect("body_entered", Callable(self, "_on_area_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_body_exited"))
		
	# Initialize timers
	add_child(cooking_timer)
	cooking_timer.wait_time = 25.0
	cooking_timer.one_shot = true
	cooking_timer.connect("timeout", Callable(self, "_on_cooking_timer_timeout"))
	
	add_child(outside_timer)
	outside_timer.wait_time = 10.0
	outside_timer.one_shot = true
	outside_timer.connect("timeout", Callable(self, "_on_outside_timer_timeout"))

func _on_area_body_entered(body):
	# Check if the entering body is in the "Cookable" group
	if skillet_in_cooking_area == true:
		if body.is_in_group("Cookable"):
			# Set fish state to ON_BLIUDAS
			fish_state = FishState.ON_BLIUDAS
			# Remove linear velocity
			body.linear_velocity = Vector3.ZERO
			# Remove angular velocity
			body.angular_velocity = Vector3.ZERO
			if body.rotation.z < 0:
				body.get_node("Mesh2")._start_cooking()
				body.get_node("Mesh2").connect("cooking_completed", Callable(self, "_on_cooking_completed"))
			else:
				body.get_node("Mesh")._start_cooking()
				body.get_node("Mesh").connect("cooking_completed", Callable(self, "_on_cooking_completed"))
				
			if steam_particles:
				steam_particles.emitting = true    
			print("Fish placed on the bliudas")
			print("Starting Cooking script")
			emit_signal("start_cooking")
			
			# Start cooking timer
			if !cooking_timer.is_stopped():
				cooking_timer.start()

func _on_area_body_exited(body):
	if body.is_in_group("Cookable"):
		if body.rotation.z < 0:
			body.get_node("Mesh2")._stop_cooking()
		else:
			body.get_node("Mesh")._stop_cooking()
			
		steam_particles.emitting = false
		smoke_particles.emitting = false
		fish_state = FishState.NORMAL
		print("Cooking stopped")
		emit_signal("stop_cooking")

func _on_cooking_area_area_entered(area):
	skillet_in_cooking_area = true
	cooking_timer.start()
	outside_timer.stop()
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Cookable"):
			# Set fish state to ON_BLIUDAS
			fish_state = FishState.ON_BLIUDAS
			# Remove linear velocity
			body.linear_velocity = Vector3.ZERO
			# Remove angular velocity
			body.angular_velocity = Vector3.ZERO
			if body.rotation.z < 0:
				body.get_node("Mesh2")._start_cooking()
				body.get_node("Mesh2").connect("cooking_completed", Callable(self, "_on_cooking_completed"))
			else:
				body.get_node("Mesh")._start_cooking()
				body.get_node("Mesh").connect("cooking_completed", Callable(self, "_on_cooking_completed"))
				
			if steam_particles:
				steam_particles.emitting = true    
			print("Fish placed on the bliudas")
			print("Starting Cooking script")
			emit_signal("start_cooking")

func _on_cooking_area_area_exited(area):
	skillet_in_cooking_area = false
	cooking_timer.stop()
	outside_timer.start()
	smoke_particles.emitting = false
	for body in area.get_overlapping_bodies():
		if body.is_in_group("Cookable"):
			if body.rotation.z < 0:
				body.get_node("Mesh2")._stop_cooking()
			else:
				body.get_node("Mesh")._stop_cooking()
				
			steam_particles.emitting = false
			print("Cooking stopped due to skillet exiting cooking area")
			emit_signal("stop_cooking")

func _on_cooking_completed():
	steam_particles.emitting = false
	smoke_particles.emitting = true

func _on_cooking_timer_timeout():
	print("The skillet has been in the cooking area for 25 seconds.")
	fire_particles.emitting = true

func _on_outside_timer_timeout():
	print("The skillet has been outside the cooking area for 10 seconds.")
	if fire_particles.emitting == true:
			sound.playing= true;
	fire_particles.emitting = false
	outside_timer.stop()
