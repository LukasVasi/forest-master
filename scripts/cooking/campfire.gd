class_name Campfire
extends StaticBody3D


signal started_burning


## The time the fire burns before fulling extinguishing
@export var fire_duration : float = 4.0

## The curve that defines how the fire ratio changes over the fire duration
@export var fire_ratio_curve : Curve


@onready var _fire : Fire = get_node("Fire")
@onready var _heat_collision : CollisionShape3D = get_node("HeatArea/HeatAreaCollisionShape")
# TODO: I mean this has to go
@onready var _skillet : Skillet = get_tree().get_first_node_in_group("Skillet").get_node("Skillet")


var _burning: bool = false:
	get:
		return _burning
	set(value):
		_burning = value
		if _skillet_in_heat_area and _skillet:
			_skillet.in_heat_area = _burning

var _fire_curve_progress: float = 0.0

var _skillet_in_heat_area: bool = false


func _process(delta: float) -> void:
	if _burning:
		_fire_curve_progress += delta / fire_duration
		if _fire_curve_progress < 1.0:
			var fire_ratio : float = fire_ratio_curve.sample(_fire_curve_progress)
			_skillet.heat_ratio = fire_ratio * _get_heat_height_ratio() if _skillet_in_heat_area else 0.0
			_fire.fire_ratio = fire_ratio
		else:
			_burning = false
			_skillet.heat_ratio = 0.0
			_fire.fire_ratio = 0.0


## Returns a multiplier 0 to 1 based on ow far above the heat source the skillet is.
func _get_heat_height_ratio() -> float:
	var heat_area_bottom_y : float = _heat_collision.global_position.y - _heat_collision.shape.height / 2
	var heat_area_top_y : float = _heat_collision.global_position.y + _heat_collision.shape.height / 2
	var skillet_y : float = _skillet.global_position.y
	var ratio : float = (skillet_y - heat_area_top_y) / (heat_area_bottom_y - heat_area_top_y)
	return clampf(ratio, 0.0, 1.0)


func _on_fuel_area_entered(body: Node3D) -> void:
	if body.is_in_group("fire_wood"):
		body.queue_free()
		_fire_curve_progress = 0.0
		_burning = true
		started_burning.emit()


func _on_heat_area_entered(body: Node3D) -> void:
	if body.is_in_group("Skillet"):
		_skillet_in_heat_area = true
		_skillet.in_heat_area = _burning


func _on_heat_area_exited(body: Node3D) -> void:
	if body.is_in_group("Skillet"):
		_skillet_in_heat_area = false
		_skillet.in_heat_area = false
