@tool
class_name ArrowSnapZone
extends PhysicalSnapZone

@export var bow : Bow

func pick_up_object(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	
	if target is Arrow and target.is_fired:
		return
	
	super(target)
	
	if is_instance_valid(picked_up_object):
		picked_up_object.add_collision_exception_with(bow)
		picked_up_object.add_collision_exception_with(bow.get_picked_up_by_hand())
