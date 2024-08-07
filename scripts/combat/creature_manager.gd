class_name CreatureManager
extends Node

@export_category("Creatures")

## The generic scene used as any the creature
@export var creature_scene : PackedScene 

## The scene used as the bezdukas
@export var bezdukas_scene : PackedScene 

@export var bezdukas_count : int = 2

## The scene used as the kipsas
@export var kipsas_scene : PackedScene 

@export var kipsas_count : int = 4

## The scale applied to the creature scenes
@export var creature_scale : Vector3 = Vector3(0.8, 0.8, 0.8)

## The playback speed of the creatures' walking animations
@export_range(1, 5) var animation_playback_speed : float = 2.0

@export_category("Creature movement")

## The path that the creature follows
@export var movement_path_curves : Array[Curve3D]

## The speed at which the kipsas moves
@export var move_speed : float = 4.0

@export_category("Object")

## The scenes used as the objects
@export var object_scenes : Array[PackedScene]

## The scale of the object scenes
@export var object_scale : Vector3 = Vector3(0.4, 0.4, 0.4)

## The randmonsess of the object scenes' scales
@export var object_scale_randomness : Vector3 = Vector3(0.1, 0.1, 0.1)

var _dead_kipsas_count : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if bezdukas_count == 0 and kipsas_count == 0:
		set_process(false)
		return
		
	if movement_path_curves.size() < bezdukas_count + kipsas_count:
		push_error("Need more paths")
		set_process(false)
		return
		
	_respawn_creatures()


func _respawn_creatures():
	# Remove existing children
	for child in get_children():
		child.queue_free()
		
	for i in bezdukas_count:
		var bezdukas : Creature = creature_scene.instantiate()
		bezdukas.creature_scene = bezdukas_scene
		bezdukas.creature_scale = creature_scale
		bezdukas.animation_playback_speed = animation_playback_speed
		bezdukas.movement_path_curve = movement_path_curves[i]
		bezdukas.move_speed = move_speed
		bezdukas.object_scene = object_scenes.pick_random()
		bezdukas.object_scale = _get_random_object_scale()
		add_child(bezdukas)
		
	for i in kipsas_count:
		var kipsas : Creature = creature_scene.instantiate()
		kipsas.creature_scene = kipsas_scene
		kipsas.creature_scale = creature_scale
		kipsas.animation_playback_speed = animation_playback_speed
		kipsas.movement_path_curve = movement_path_curves[bezdukas_count + i]
		kipsas.move_speed = move_speed
		kipsas.object_scene = object_scenes.pick_random()
		kipsas.object_scale = _get_random_object_scale()
		kipsas.died.connect(on_death)
		add_child(kipsas)


func on_death():
	_dead_kipsas_count += 1
	if _dead_kipsas_count >= kipsas_count:
		_dead_kipsas_count = 0
		_respawn_creatures()


func _get_random_object_scale() -> Vector3:
	if object_scale_randomness.length() == 0:
		return object_scale
	else:
		var min_scale = object_scale - object_scale * object_scale_randomness
		var max_scale = object_scale + object_scale * object_scale_randomness
		return Vector3(randf_range(min_scale.x, max_scale.x), randf_range(min_scale.y, max_scale.y), randf_range(min_scale.z, max_scale.z))
