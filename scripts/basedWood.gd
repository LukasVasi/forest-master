extends Node3D

var wood_instances := []
var wood_counter := 0
var amount = 4

func _ready():
	pass

func _process(delta):
	pass

func _on_pile_area_exited(area):
	if area.is_in_group("wood"):
		if wood_instances.size() > amount:
			var oldest_instance: Node = wood_instances.pop_at(amount)
			oldest_instance.queue_free()
			print("Oldest log was deleted. ID: " + str(oldest_instance.get_instance_id()))
		
		# Remove from group so it doesn't cause issues later on
		area.remove_from_group("wood")

		var new_wood_instance = preload("res://scenes/pickable_wood.tscn").instantiate()
		if new_wood_instance:
			add_child(new_wood_instance)
			wood_instances.push_front(new_wood_instance)
			
			# Change this value if you want a different starting position
			new_wood_instance.transform.origin = Vector3(0.0, 0.65, 0.0)
			
			wood_counter += 1
			print("New log was spawned. ID: " + str(wood_counter))
