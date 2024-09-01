@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name FunctionPickup
extends XRToolsFunctionPickup


func _pick_up_object(target: Node3D) -> void:
	# check if already holding an object
	if is_instance_valid(picked_up_object):
		# skip if holding the target object
		if picked_up_object == target:
			return
		# holding something else? drop it
		drop_object()

	# skip if target null or freed
	if not is_instance_valid(target):
		return

	# Handle snap-zone
	var snap := target as XRToolsSnapZone
	if snap:
		target = snap.picked_up_object
		snap.drop_object()

	# Handle pickable dispenser
	var dispenser := target as PickableDispenser
	if dispenser:
		target = dispenser.pick_up()

	# Pick up our target. Note, target may do instant drop_and_free
	picked_up_ranged = not _object_in_grab_area.has(target)
	picked_up_object = target
	target.pick_up(self)

	# If object picked up then emit signal
	if is_instance_valid(picked_up_object):
		picked_up_object.request_highlight(self, false)
		emit_signal("has_picked_up", picked_up_object)
