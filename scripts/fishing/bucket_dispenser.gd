class_name BucketDispenser
extends PickableDispenser

@export var infinite : bool = false

@onready var mesh_material : StandardMaterial3D = get_node("../Bucket").get_active_material(0)
@onready var pour_particles : GPUParticles3D = get_node("../WaterPourParticles")
@onready var splash_particles : GPUParticles3D = get_node("../WaterSplashParticles")

## The queue containing the types of fish in the order they've been added
var _fish_queue : Array[Fish.FishType] = []

var _fish : Fish = null

func _process(_delta: float) -> void:
	if _is_upside_down():
		pour_particles.emitting = true
	else:
		pour_particles.emitting = false
		
	if _fish and not _fish.is_picked_up():
		if _fish.is_raw:
			_enable_glow()
			_fish_queue.append(_fish.type)
			_fish.store()
			splash_particles.emitting = true
		else:
			_fish.apply_impulse(global_transform.basis.y * 0.1)


## Test if this object can dispense a pickup
func can_pick_up(_by: Node3D) -> bool:
	return infinite or _fish_queue.size() > 0


## Instantiate the scene with the last fish type
func _get_dispensable_instance() -> Fish:
	_enable_glow()
	splash_particles.emitting = true
	var fish_type: Fish.FishType
	if infinite:
		fish_type = Fish.FishType.Raude
	else:
		fish_type = _fish_queue.pop_back()
	# NOTE: very manual matching of type to index in the array of dispensed scenes
	match fish_type:
		Fish.FishType.Kuoja:
			return dispensed_scenes[0].instantiate()
		Fish.FishType.Lynas:
			return dispensed_scenes[1].instantiate()
		Fish.FishType.Raude:
			return dispensed_scenes[2].instantiate()
		_:
			return null

func _enable_glow() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(mesh_material, "emission_energy_multiplier", 8, 0.5)
	tween.tween_callback(_disable_glow)

func _disable_glow() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(mesh_material, "emission_energy_multiplier", 0, 0.5)

func _is_upside_down() -> bool:
	var up_vector: Vector3 = global_transform.basis.y
	var dot_product: float = up_vector.dot(Vector3.UP)
	return dot_product < 0


## Save a ref to a fish that enters the bucket
func _on_body_entered(body: Node3D) -> void:
	if body is Fish:
		_fish = body as Fish


## Remove the ref
func _on_body_exited(body: Node3D) -> void:
	if body == _fish:
		_fish = null
