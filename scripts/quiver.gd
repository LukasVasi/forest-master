extends Node3D

var arrow_instances := []
var arrow_counter := 0
var amount = 4

func _ready():
	pass

func _process(delta):
	pass

func _on_quiver_area_exited(area):
	if area.is_in_group("inf_Arrows"):
		if arrow_instances.size() > amount:
			var oldest_instance: Node = arrow_instances.pop_at(amount)
			oldest_instance.queue_free()
			print("Oldest arrow was deleted. ID: " + str(oldest_instance.get_instance_id()))
		
		# Remove from group so it doesn't cause issues later on
		area.remove_from_group("inf_Arrows")

		var new_arrow_instance = preload("res://scenes/arrow.tscn").instantiate()
		if new_arrow_instance:
			add_child(new_arrow_instance)
			arrow_instances.push_front(new_arrow_instance)
			
			# Change this value if you want a different starting position
			new_arrow_instance.transform.origin = Vector3(0, 0.8, 0)
			
			arrow_counter += 1
			print("New arrow was spawned. ID: " + str(arrow_counter))
