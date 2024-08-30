extends MeshInstance3D

signal start_cooking
signal stop_cooking

enum FishState {
	NORMAL,
	ON_BLIUDAS
}

var fish_state = FishState.NORMAL

func _ready():
	# Connect the body_entered signal of the Area3D to the "_on_area_body_entered" function
	var area = $Area3D
	if area:
		area.connect("body_entered", Callable(self, "_on_area_body_entered"))
		area.connect("body_exited", Callable(self, "_on_area_body_exited"))

func _on_area_body_entered(body):
	# Check if the entering body is in the "Cookable" group
	if body.is_in_group("Cookable"):
		# Set fish state to ON_BLIUDAS
		fish_state = FishState.ON_BLIUDAS
		
		# Disable gravity for the entering body
		if body.has_method("set_gravity_scale"):
			body.set_gravity_scale(0)
		
		# Calculate the midpoint of the "bliudas" object
		var midpoint = global_transform.origin
		
		# Move the entering body to the adjusted position
		body.global_transform.origin = midpoint + Vector3(0.05, 0.475, 0.25)
		
		# Rotate the entering body 90 degrees on the X axis
		body.global_transform.basis = Basis(Vector3(0, 0, 1), deg_to_rad(90))

		# Remove linear velocity
		body.linear_velocity = Vector3.ZERO
		
		# Remove angular velocity
		body.angular_velocity = Vector3.ZERO
		
		body.get_node("Mesh")._start_cooking()
		
		print("Fish placed on the bliudas")
		print("Starting Cooking script")
		emit_signal("start_cooking")
		
		
func _on_area_body_exited(body):
	if body.is_in_group("Cookable"):
		body.get_node("Mesh")._stop_cooking()
		fish_state = FishState.NORMAL
		print("Cooking stopped")
		emit_signal("stop_cooking")
