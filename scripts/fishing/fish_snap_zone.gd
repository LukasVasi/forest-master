extends PhysicalSnapZone

var _original_mass : float = 0.0

# Pickup Method: Drop the currently picked up object
func drop_object() -> void:
	if not is_instance_valid(picked_up_object):
		return
	
	# let go of this object
	picked_up_object.let_go(self)

	# Reset the grab joint
	grab_joint.set_node_a("")
	grab_joint.set_node_b("")
	picked_up_object.mass = _original_mass

	picked_up_object = null
	has_dropped.emit()
	highlight_updated.emit(self, enabled)

func pick_up_object(target: Node3D) -> void:
	# check if already holding an object
	if is_instance_valid(picked_up_object):
		# skip if holding the target object
		if picked_up_object == target:
			print_verbose("Physical snap zone ", self, " tried picking up object it already holds ", target)
			return
		# holding something else? drop it
		drop_object()

	# Skip if target null or freed
	if not is_instance_valid(target):
		print_verbose("Physical snap zone ", self, " tried picking up a non valid instance ", target)
		return
	
	# Skip if not pickable
	if target is not PhysicalPickable:
		print_verbose("Physical snap zone ", self, " tried picking up non PhysicalPickable object ", target)
		return
	
	var pickable_target : PhysicalPickable = target
	var grab := pickable_target.pick_up(self)
	
	# Check if succeded in picking up, fail if not
	if not is_instance_valid(grab):
		print_verbose("Physical snap zone ", self, " failed to pick up ", target)
		return
	
	# Pick up our target
	picked_up_object = pickable_target
	
	# Snap target to snap zone
	picked_up_object.freeze = true
	picked_up_object.global_transform = global_transform.orthonormalized()
	
	# Reduce mass
	_original_mass = picked_up_object.mass
	picked_up_object.mass = 0.1
	
	# Set joint between hand and grabbed object
	grab_joint.set_node_a(snap_object.get_path())
	grab_joint.set_node_b(picked_up_object.get_path())
	grab_joint.set_flag_y(grab_joint.FLAG_ENABLE_ANGULAR_LIMIT, true) # FLAG_ENABLE_ANGULAR_LIMIT = 1
	
	# Unfreeze object
	picked_up_object.freeze = false
	grab.set_arrived()
	
	var player: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")
	if is_instance_valid(player):
		if player.playing:
			player.stop()
		player.stream = stash_sound
		player.play()
