extends Node3D

var _wood_instances := []
var _wood_counter := 0
var _amount: int = 4

func _on_pile_area_exited(area: Area3D) -> void:
	if area.is_in_group("wood"):
		if _wood_instances.size() > _amount:
			var oldest_instance: Node = _wood_instances.pop_at(_amount)
			oldest_instance.queue_free()
			#print("Oldest log was deleted. ID: " + str(oldest_instance.get_instance_id()))
		
		# Remove from group so it doesn't cause issues later on
		area.remove_from_group("wood")

		var new_wood_instance: XRToolsPickable = preload("res://scenes/cooking/pickable_wood.tscn").instantiate()
		if new_wood_instance:
			add_child(new_wood_instance)
			_wood_instances.push_front(new_wood_instance)
			
			# Change this value if you want a different starting position
			new_wood_instance.position = Vector3(0.0, 0.65, 0.0)
			
			_wood_counter += 1
			#print("New log was spawned. ID: " + str(_wood_counter))
