@tool
class_name Arrow
extends XRToolsPickable

#const FORCE_FACTOR = 1.0

# TODO: fix this
#func _physics_process(delta: float) -> void:
	#if freeze == false:
		#var forward_direction: Vector3 = -global_transform.basis.z
		#var forward_motion = linear_velocity
	#
		#var speed: float = forward_motion.length()
		#if speed > 0.5:
			#forward_motion = forward_motion.normalized()
			#var dot = 1.0 - max(0.0,forward_motion.dot(forward_direction))
			#var sideways = forward_motion.cross(forward_direction).normalized()
			#var force_vector = sideways.cross(forward_direction).normalized()
			#
			#var impulse_position: Vector3 = global_transform.basis * $ArrowMesh.position
			#apply_impulse(impulse_position, force_vector * dot * FORCE_FACTOR * speed)


func _on_arrow_body_entered(body: Node) -> void:
	if body.has_method("on_hit_by_arrow"):
		body.on_hit_by_arrow()
		queue_free()
