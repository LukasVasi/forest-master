class_name Camp_fire
extends StaticBody3D

## The time the fire burns before fulling extinguishing
@export var fire_duration: float = 4.0

## The curve that defines how the fire ratio changes over the fire duration
@export var fire_curve: Curve

@onready var _fire: Fire = $Fire
@onready var _cooking_area: Area3D = $CookingArea

var _burning: bool = true
var _fire_curve_progress: float = 0.0


func _process(delta: float) -> void:
	if _burning:
		_fire_curve_progress += delta / fire_duration
		if _fire_curve_progress < 1.0:
			_fire.fire_ratio = fire_curve.sample(_fire_curve_progress)
		else:
			_fire.fire_ratio = 0.0
			_burning = false
			_cooking_area.monitoring = false


func _on_fuel_area_entered(body: Node3D) -> void:
	if body.is_in_group("fire_wood"):
		body.queue_free()
		_fire_curve_progress = 0.0
		_burning = true
		_cooking_area.monitoring = true
