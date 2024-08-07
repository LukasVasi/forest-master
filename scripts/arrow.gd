extends XRToolsPickable

#const STAKE = preload("res://scenes/steak.tscn") 
const force_factor = 0.1
@onready var combat_node = get_node("../../")

#cia krc funkcija skirta kad graziai skristu strele, bet neisejo tai velesniem bandymam nes sjp visai graziai ir db skrenda
#func _physics_process(delta):
#	if freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC:
#		var forward_direction = -global_transform.basis.x
#		var forward_motion = linear_velocity
#	
#		var speed = forward_motion.length()
#		if speed > 1.0:
#			forward_motion = forward_motion.normalized()
#			var dot = 1.0 - max(0.0,forward_motion.dot(forward_direction))
#			var sideways = forward_motion.cross(forward_direction).normalized()
#			var force_vector = sideways.cross(forward_direction).normalized()
#			
#			var position = global_transform.basis *$ArrowMesh.transform.origin
#			apply_impulse(position,force_vector * dot * force_factor * speed)


func _on_Arrow_body_entered(body):
	if body.has_method("on_hit_by_arrow"):
		body.on_hit_by_arrow()
		#var steak_instance = STAKE.instantiate()
		#steak_instance.global_transform.origin = global_transform.origin 
		#combat_node.add_child(steak_instance)  # Add the new Steak node to the scene tree
		queue_free()
