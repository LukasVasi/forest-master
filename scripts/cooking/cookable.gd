class_name Cookable
extends MeshInstance3D

## Signal emitted when the cookable is fully cooked. Used in Skillet logic.
signal cooking_completed

@export var cooking_level: float = 0.0
@export var max_cooking_level: float = 2.0
@export var cooking_rate: float = 0.2

var _shader_mat: ShaderMaterial

func _ready() -> void:
	preload_shader()
	set_process(false)


func preload_shader() -> void:
	var shader: Shader = preload("res://shaders/CookingShader.gdshader")
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader


func start_cooking() -> void:
	print("Cooking started in cookable script")
	apply_shader_materials()
	set_process(true)


func apply_shader_materials() -> void:
	if !is_instance_valid(get_surface_override_material(0)):
		for i in range(get_surface_override_material_count()):
			var existing_mat: Material = get_active_material(i)
			var mat: ShaderMaterial = _shader_mat.duplicate()
			if existing_mat:
				mat.set_shader_parameter("base_texture", existing_mat.albedo_texture)
				mat.set_shader_parameter("base_color", existing_mat.albedo_color)
			set_surface_override_material(i, mat)


func _process(delta: float) -> void:
	if cooking_level < max_cooking_level:
		cooking_level += cooking_rate * delta
		update_cooking_level()
	else:
		print("Cooking completed. Level: ", cooking_level)
		cooking_completed.emit()


func update_cooking_level() -> void:
	for i in range(get_surface_override_material_count()):
		var mat: ShaderMaterial = get_surface_override_material(i)
		if mat:
			mat.set_shader_parameter("cooking_level", cooking_level)


func stop_cooking() -> void:
	print("Cooking stopped at level: ", cooking_level)
	set_process(false)
