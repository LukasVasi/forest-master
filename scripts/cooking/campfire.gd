class_name Campfire
extends StaticBody3D

## The time the fire burns before fulling extinguishing
@export var fire_duration: float = 4.0

## The curve that defines how the fire ratio changes over the fire duration
@export var fire_curve: Curve

@onready var _fire: Fire = $Fire
# TODO: I mean this has to go
@onready var _skillet: Skillet = get_tree().get_first_node_in_group("Skillet").get_node("Skillet")

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
			_fire.fire_ratio = fire_curve.sample(_fire_curve_progress)
		else:
			_fire.fire_ratio = 0.0
			_burning = false


func _on_fuel_area_entered(body: Node3D) -> void:
	if body.is_in_group("fire_wood"):
		body.queue_free()
		_fire_curve_progress = 0.0
		_burning = true


func _on_heat_area_entered(body: Node3D) -> void:
	if body.is_in_group("Skillet"):
		_skillet_in_heat_area = true
		_skillet.in_heat_area = _burning


func _on_heat_area_exited(body: Node3D) -> void:
	if body.is_in_group("Skillet"):
		_skillet_in_heat_area = false
		_skillet.in_heat_area = false
