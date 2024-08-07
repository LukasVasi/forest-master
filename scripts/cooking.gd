extends MeshInstance3D

signal start_cooking
signal stop_cooking
signal cooking_completed

var cooking_level: float = 0.0
var max_cooking_level: float = 2.0
var cooking_rate: float = 0.2
var shader_mat: ShaderMaterial

func _ready():
	preload_shader()
	connect("start_cooking", Callable(self, "_start_cooking"))
	connect("stop_cooking", Callable(self, "_stop_cooking"))
	set_process(false)

func preload_shader():
	var shader = preload("res://shaders/CookingShader.gdshader")
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader

func _start_cooking():
	print("Cooking started")
	apply_shader_materials()
	set_process(true)

func apply_shader_materials():
	if !is_instance_valid(get_surface_override_material(0)):
		for i in range(get_surface_override_material_count()):
			var existing_mat = get_active_material(i)
			var mat = shader_mat.duplicate()
			if existing_mat:
				mat.set_shader_parameter("base_texture", existing_mat.albedo_texture)
				mat.set_shader_parameter("base_color", existing_mat.albedo_color)
			set_surface_override_material(i, mat)

func _process(delta):
	if cooking_level < max_cooking_level:
		cooking_level += cooking_rate * delta
		update_cooking_level()
	else:
		print("Cooking completed. Level:", cooking_level)
		emit_signal("cooking_completed")
		emit_signal("stop_cooking")

func update_cooking_level():
	for i in range(get_surface_override_material_count()):
		var mat = get_surface_override_material(i) as ShaderMaterial
		if mat:
			mat.set_shader_parameter("cooking_level", cooking_level)

func _stop_cooking():
	print("Cooking stopped at level:", cooking_level)
	set_process(false)
