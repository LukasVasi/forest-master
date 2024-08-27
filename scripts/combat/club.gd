class_name Club
extends XRToolsPickable

func _on_body_entered(body: Node) -> void:
	if is_picked_up() and body.name == "BezdukasDissapearingBody":
		if body.get_parent():
			body.get_parent().queue_free()  # This will remove the parent of the BezdukasDissapearing node from the scene
