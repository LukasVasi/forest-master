@tool
class_name CookableObject
extends PhysicalPickable


@export var max_cooking_level: float = 2.0
@export var cooking_levels: Array[float] = [0.0, 0.0]

@onready var _cookable_mesh: MeshInstance3D = get_node("MeshInstance3D")
@onready var _cooking_steam : GPUParticles3D = get_node("CookingSteam")
@onready var _cooking_smoke : GPUParticles3D = get_node("CookingSmoke")

var is_cooking : bool = false : 
	set(value):
		is_cooking = value
		if is_cooking:
			_cooking_steam.emitting = true
		else:
			_cooking_steam.emitting = false

var is_burning : bool = false : 
	set(value):
		is_burning = value
		if is_burning:
			_cooking_smoke.emitting = true
		else:
			_cooking_smoke.emitting = false

var is_raw: bool = true
var is_cooked : bool = false
var is_burned : bool = false
var _cooking_shader: Shader = preload("res://shaders/CookingShader.gdshader")


func _ready() -> void:
	super._ready()
	_prepare_cooking_shader()


func _prepare_cooking_shader() -> void:
	var shader_mat: ShaderMaterial = ShaderMaterial.new()
	shader_mat.shader = _cooking_shader
	
	# Determine the number of surfaces the cookable mesh has
	# each surface represents a side of the cookable object based on z rotation
	var cookable_surface_count: int = _cookable_mesh.mesh.get_surface_count()
	for i in range(cookable_surface_count):
			var cookable_mat: ShaderMaterial = shader_mat.duplicate()
			var existing_mat: StandardMaterial3D = _cookable_mesh.mesh.surface_get_material(i)
			if existing_mat:
				cookable_mat.set_shader_parameter("max_cooking_level", max_cooking_level)
				cookable_mat.set_shader_parameter("base_albedo_texture", existing_mat.albedo_texture)
				cookable_mat.set_shader_parameter("base_albedo", existing_mat.albedo_color)
				cookable_mat.set_shader_parameter("base_roughness_texture", existing_mat.roughness_texture)
				cookable_mat.set_shader_parameter("base_roughness", existing_mat.roughness)
			_cookable_mesh.set_surface_override_material(i, cookable_mat)


func add_cooking_level(value: float) -> void:
	if is_raw: is_raw = false
	
	if rotation.z > 0: # right side
		cooking_levels[0] = min(cooking_levels[0] + value, max_cooking_level)
		set_shader_cooking_level(0)
		if is_burning:
			cooking_levels[1] = min(cooking_levels[1] + value / 2, max_cooking_level)
			set_shader_cooking_level(1)
	else: # left side
		cooking_levels[1] = min(cooking_levels[1] + value, max_cooking_level)
		set_shader_cooking_level(1)
		if is_burning:
			cooking_levels[0] = min(cooking_levels[0] + value / 2, max_cooking_level)
			set_shader_cooking_level(0)
	
	if (
			not is_cooked and 
			(cooking_levels[0] > max_cooking_level / 2 and 
			cooking_levels[1] > max_cooking_level / 2)
	):
		is_cooked = true
		StatisticsManager.report_cooking_fully_cooked()
	
	if (
			not is_burned and 
			(cooking_levels[0] >= max_cooking_level or 
			cooking_levels[1] >= max_cooking_level)
	):
		is_burned = true
		StatisticsManager.report_cooking_burned()


func set_shader_cooking_level(index: int) -> void:
	_cookable_mesh.get_surface_override_material(index).set_shader_parameter("cooking_level", cooking_levels[index])
