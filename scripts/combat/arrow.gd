@tool
class_name Arrow
extends PhysicalPickable

@export var drag_force: float = 0.2
@export var speed_threshold: float = 0.8

@onready var fins: Node3D = get_node("Fins")


func _physics_process(_delta: float) -> void:
	if not is_picked_up() and freeze == false:
		var movement := linear_velocity
		if movement.length() > speed_threshold:
			var forward_direction: Vector3 = -global_basis.z.normalized()
			var movement_direction := movement.normalized()
			# The dot product is 0.0 if perpendcular and 1.0 or -1.0 if parallel
			var dot: float = forward_direction.dot(movement_direction)
			var dot_inv: float = 1.0 - abs(dot)
			var force := -movement * dot_inv * drag_force
			
			apply_force(force, fins.global_position - global_position)


func _on_arrow_body_entered(body: Node) -> void:
	# Check if fired and travelling fast enough
	if linear_velocity.length() > speed_threshold and body.has_method("on_hit_by_arrow"):
		body.on_hit_by_arrow()
		queue_free()
