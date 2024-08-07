class_name Creature
extends Node3D

signal died

@export_category("Creature")

## The scene used as the creature
@export var creature_scene : PackedScene 

## The scale of the creature scene
@export var creature_scale : Vector3 = Vector3(1, 1, 1)

## The playback speed of the walking animation
@export_range(1, 5) var animation_playback_speed : float = 1.0 : set = _set_animation_playback_speed

@export_category("Creature movement")

## The path that the creature follows
@export var movement_path_curve : Curve3D 

## The speed at which the kipsas moves
@export var move_speed : float = 4.0

@export_category("Object")

## The scene used as the object
@export var object_scene : PackedScene

## The scale of the object scene
@export var object_scale : Vector3 = Vector3(1, 1, 1)

# Variables contained in this scene
@onready var creature_container : Node3D = get_node("MovementPath/PathFollow3D/CreatureContainer")

@onready var particles = get_node("MovementPath/PathFollow3D/CreatureContainer/GPUParticles3D")

@onready var path_follow = get_node("MovementPath/PathFollow3D")

# Vriables contained in the creature scene
@onready var animation_player: AnimationPlayer

var is_dead : bool = false
var is_moving : bool = false
var creature : Node3D
var object : Node3D

func _ready() -> void:
	if !creature_scene or !creature_scene.can_instantiate():
		push_error("A valid creature scene must be provided")
		set_process(false)
		return
		
	if !object_scene or !object_scene.can_instantiate():
		push_error("A valid object scene must be provided")
		set_process(false)
		return
		
	if !movement_path_curve:
		push_error("A valid movement path curve must be provided")
		set_process(false)
		return
	
	# Add the creature to the scene
	creature = creature_scene.instantiate()
	creature.scale = creature_scale
	creature_container.add_child(creature)
	particles.emitting = true
	
	var creature_hitbox = creature.get_node("StaticBody3D")
	if not creature_hitbox or creature_hitbox == null or not creature_hitbox is CreatureHitbox:
		#push_warning("A hitbox for the creature should be provided")
		pass
	else:
		creature_hitbox.hit_by_arrow.connect(_on_hit)
	
	# Add the object to the scene
	object = object_scene.instantiate()
	object.scale = object_scale
	creature_container.add_child(object)
	object.visible = false
	
	# Connect to the toggle movement signal
	var puntukas = get_node("/root/Staging/Scene/Main/Combat/Puntukass")
	puntukas.toggle_creature_movement.connect(_on_toggle_movement)
	
	# Set the movement path
	var movement_path : Path3D = get_node("MovementPath")
	movement_path.curve = movement_path_curve
	path_follow.progress = randf_range(0, 1)
	
	
	animation_player = creature.get_node("AnimationPlayer")
	animation_player.speed_scale = animation_playback_speed
	
	## Ensure the walking animation is set to loop
	#var walking_animation = animation_player.get_animation("Walking")
	#if walking_animation:
		#walking_animation.loop = true
	#else:
		#push_warning("A creature should have a walking animation")
	
	# Start the walking animation
	animation_player.play("Walking")
	
	is_moving = true


func _physics_process(delta: float) -> void:
	if not is_dead and is_moving:
		path_follow.progress -= move_speed * delta
	if is_dead and particles.emitting == false:
		died.emit()
		queue_free()

## Called when the movement state is toggled
func _on_toggle_movement():
	if is_dead:
		return
	
	is_moving = !is_moving  # Toggle the movement state
	
	particles.emitting = true # emit the particles
	
	if !is_moving:
		# Pause the walking animation
		animation_player.pause()
		
		# Hide the creature (along with all of its children)
		creature.visible = false
		
		# Unhide the object
		object.visible = true
	else:
		# Hide the object
		object.visible = false
		
		# Unhide the creature
		creature.visible = true
		
		# Resume the walking animation
		animation_player.play("Walking")


func _set_animation_playback_speed(new_value : float):
	animation_playback_speed = new_value
	if animation_player:
		animation_player.speed_scale = new_value


func _on_hit():
	# Just despawn everythig when hit
	particles.emitting = true
	is_dead = true
	creature.queue_free()
	object.queue_free()
