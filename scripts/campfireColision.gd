extends Node3D

var timer = 0
@export var stopTime = 10  # Stop emitting particles after 10 seconds
@export var fade_duration = 5  # Duration over which the particles fade out
var light_node: OmniLight3D
var cooking_area: Area3D
var fade_timer = 0.0  # Timer for fading out
var fading_out = false  # Indicates if fading out is in progress

func _ready():
	start_timer()
	light_node = $OmniLight3D
	cooking_area=$CookingArea

func start_timer():
	timer = stopTime

func _process(delta):
	if timer > 0:
		timer -= delta
		if timer <= 0:
			start_fade_out()

	if fading_out:
		update_fade(delta)

func start_fade_out():
	fading_out = true
	fade_timer = fade_duration

func update_fade(delta):
	var fire_particles = $Fire/GPUParticles3D
	if fire_particles:
		fade_timer -= delta
		var fade_ratio = fade_timer / fade_duration
		var new_size = fade_ratio  # Scale from 1 to 0 over fade duration
		if fire_particles.draw_pass_1 is Mesh:
			fire_particles.draw_pass_1.size = Vector2(new_size, new_size)
		if light_node:
			light_node.light_energy = new_size
		if fade_timer <= 0:
			fading_out = false
			fire_particles.emitting = false
			if light_node:
				light_node.visible = false
			cooking_area.monitoring = false
	else:
		print("Fire particles node not found!")

func _on_Campfire_body_entered(body):
	if body.is_in_group("fire_wood"):
		reset_timer()
		body.queue_free()  # Make the object disappear

func reset_timer():
	timer = stopTime
	var fire_particles = $Fire/GPUParticles3D
	if fire_particles:
		fading_out = false
		fade_timer = 0.0
		fire_particles.draw_pass_1.size = Vector2(1, 1)  # Reset size to full
		fire_particles.emitting = true  # Start emitting particles
		if light_node:
			light_node.light_energy = 2.616  # Reset energy to full
			light_node.visible = true
		cooking_area.monitoring = true
		print("Particles and light restarted")
	else:
		print("Fire particles node not found!")
	start_timer()
