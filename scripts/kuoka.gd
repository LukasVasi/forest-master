extends XRToolsPickable

# Called when the node enters the scene tree for the first time.
func _ready():
	super()

func _on_Kuoka_body_entered(body):
	if is_picked_up()==true and body.name=="BezdukasDissapearingBody":
		print("pataike KUOKA i dissapearing bezduka :D")
		if body.get_parent():
			body.get_parent().queue_free()  # This will remove the parent of the BezdukasDissapearing node from the scene
		# Spawn a new Steak node at the same position as the arrow
		var steak_instance = load("res://scenes/steak.tscn").instantiate()
		steak_instance.global_transform.origin = global_transform.origin 
		get_tree().get_root().add_child(steak_instance)  # Add the new Steak node to the scene tree

