@tool
class_name FishingRod
extends PhysicalPickable


## The fishing rod object.
##
## This extends the XRToolsPickable script that allows a [RigidBody3D] to be picked up by an
## [XRToolsFunctionPickup] attached to a players controller.
##
## The fishing rod contains (as its children) the [FishingFloat] and [Line] objects.


## Signal emitted when fishing rod reaches max tension and snaps.
signal snapped


## The amount of force exerted in pulling float for full handle rotation (2π radians). 
@export var reel_in_force: float = 8

# TODO: replace this with ray cast to check collisions with objects
## The distance at which the float is reset when reeling in
@export var float_reset_distance: float = 2

@export_category("Tension")

@export var max_tension: float = 100.0 : set = _set_max_tension

## The amount of tension added for full handle rotation (2π radians). 
@export var reeling_tension_gain: float = 5.0

## The amount of tension that decays per second 
## when fishing rod is aimed against the fish swimming direction.
@export var passive_tension_decay: float = 25

## The amount of tension that is gainer per second 
## when fishing rod is aimed wrong relative to the fish swimming direction.
@export var passive_tension_gain: float = 10

@export_group("Rumble feedback")

## The maximum rumble magnitude that will be used at max tension.
@export_range(0.0, 1.0) var max_rumble_magnitude : float = 0.2

## The rumble event used to provide rumble feedback when the hand gets too far.
@export var rumble_event : XRToolsRumbleEvent

#region Public variables
## The fishing float.
@onready var fishing_float: FishingFloat = get_node("FishingFloat")

## The physical snap zone used to snap fish upon catching.
@onready var fish_snap_zone : PhysicalSnapZone = get_node("FloatTarget/FishSnapZone")

var tension: float = 0.0 : set = _set_tension
#region endregion

#region Private variables
@onready var _fishing_rod_skeleton: Skeleton3D = get_node("FishingRodArmature/Skeleton3D")
@onready var _center_of_spinner: Node3D = get_node("CenterOfSpinner")
@onready var _handle_origin: Node3D = get_node("CenterOfSpinner/HandleOrigin")
@onready var _handle: PhysicalInteractableHandle = get_node("CenterOfSpinner/HandleOrigin/SpinnerHandle")
@onready var _holding_stick_snap: PhysicalSnapZone = get_tree().get_first_node_in_group("holding_stick").get_node("PhysicalSnapZone")
@onready var _fishing_manager: FishingManager = get_tree().get_first_node_in_group("fishing")
@onready var _mesh: MeshInstance3D = get_node("FishingRodArmature/Skeleton3D/FishingRod")

var _material_override: StandardMaterial3D
var _moved: bool = false
var _previous_direction_to_handle: Vector3
var _rumbling: bool = false
#endregion

func _ready() -> void:
	super()
	
	if Engine.is_editor_hint():
		return
	
	_setup_tension_material()
	
	fishing_float.target.enabled = false
	_handle.enabled = false
	_previous_direction_to_handle = _get_direction_to_handle()


func _physics_process(delta: float) -> void:
	if is_picked_up():
		_update_handle_rotation()
		if _fishing_manager.state == FishingManager.State.Reeling:
			_update_tension(delta)
		
		_process_rumbling()


func _update_tension(delta: float) -> void:
	# TODO: Check if rod is aimed properly and add or reduce tension based on that
	tension -= passive_tension_decay * delta


func _process_rumbling() -> void:
	if get_tension_ratio() > 0.0:
		rumble_event.magnitude = get_tension_ratio() * max_rumble_magnitude
		if not _rumbling:
			_rumbling = true
			if is_picked_up():
				var hand := get_picked_up_by_hand()
				if is_instance_valid(hand):
					var rumble_trackers := hand.rumble_trackers
					RumbleManager.add(self, rumble_event, rumble_trackers)
	elif _rumbling:
		_rumbling = false
		RumbleManager.remove(self)


func pick_up(by: Node3D) -> PhysicalGrab:
	_moved = true
	_handle.enabled = true
	var grab := super.pick_up(by) # Run the parent pick up function
	if grab.hand: # enable velocity estimation if picked up by player
		fishing_float.target.enabled = true
	return grab


func let_go(by: Node3D) -> void:
	super.let_go(by) # Run the parent function
	_handle.drop()
	_handle.enabled = false
	fishing_float.target.enabled = false
	if _rumbling:
		_rumbling = false
		RumbleManager.remove(self)


func action() -> void:
	super()
	
	if fishing_float.state != FishingFloat.State.Attached:
		fishing_float.state = FishingFloat.State.Attached
	else:
		fishing_float.state = FishingFloat.State.Detached


func reset() -> void:
	fishing_float.state = FishingFloat.State.Attached
	tension = 0.0
	_holding_stick_snap.pick_up_object(self)
	_moved = false


func _update_handle_rotation() -> void:
	# If we reeled the float close enough, exit early (locks the _handle from rotating)
	if (
		_fishing_manager and _fishing_manager.state == FishingManager.State.Reeling
		and fishing_float.distance_to_target < float_reset_distance
	):
		return 
	
	# Get the direction to the handle
	var current_direction_to_handle := _get_direction_to_handle()
	
	# Calculate the target rotation of the bone and apply it
	var target_rotation := Quaternion(Vector3.RIGHT, deg_to_rad(90) + atan2(current_direction_to_handle.z, current_direction_to_handle.y))
	_fishing_rod_skeleton.set_bone_pose_rotation(1, target_rotation)
	
	# Move the handle origin to the appropriate position
	var offset_to_handle := 0.03 * current_direction_to_handle # 0.03 - spinner radius
	_handle_origin.position = Vector3(-0.165, offset_to_handle.y, offset_to_handle.z)
	
	if fishing_float.state != FishingFloat.State.Attached:
		# Calculate the signed angle difference from previous rotation
		var rotation_angle_delta := current_direction_to_handle.signed_angle_to(_previous_direction_to_handle, Vector3.RIGHT)
		
		# Check if reeling IN
		if rotation_angle_delta > 0:
			# Convert angle difference (radians) to reel in amount: each full turn (2π radians) should move the float by reel_in_force meters
			var reel_in_delta := rotation_angle_delta / (2 * PI) * reel_in_force
			
			# Get the float's XZ direction to fishing rod's tip
			var float_direction_to_target := fishing_float.global_position.direction_to(fishing_float.target.global_position)
			float_direction_to_target.y = 0
			float_direction_to_target = float_direction_to_target.normalized()
			
			# Move the float
			fishing_float.apply_central_force(float_direction_to_target * reel_in_delta)
			
			# Reset the float if it gets close enough when not reeling in
			#if fishing_float.distance_to_target < float_reset_distance:
				#fishing_float.state = FishingFloat.State.Attached
			
			# Update tension if reeling in
			if _fishing_manager.state == FishingManager.State.Reeling:
				tension += rotation_angle_delta / (2 * PI) * reeling_tension_gain
	
	_previous_direction_to_handle = current_direction_to_handle


func _get_direction_to_handle() -> Vector3:
	var direction_to_handle := _center_of_spinner.to_local(_handle.global_position)
	direction_to_handle.x = 0
	direction_to_handle = direction_to_handle.normalized()
	return direction_to_handle


func get_tension_ratio() -> float:
	return tension / max_tension


func on_water_entered(_water_height: float) -> void:
	drop()
	reset()


func _snap() -> void:
	fishing_float.state = FishingFloat.State.Attached
	snapped.emit()


## Sets up the surface material override for changing color based on tension.
func _setup_tension_material() -> void:
	var mesh_material : StandardMaterial3D = _mesh.get_active_material(0)
	_material_override = mesh_material.duplicate()
	_mesh.set_surface_override_material(0, _material_override)


func _update_tension_material() -> void:
	_material_override.albedo_color = lerp(Color.WHITE, Color.RED, tension / max_tension)


func _set_tension(new_value : float) -> void:
	if new_value > max_tension:
		print("Tension: ", new_value, " - snapping")
		tension = 0.0
		_snap()
	else:
		tension = max(0.0, new_value)
		print("Tension: ", tension)
	_update_tension_material()


func _set_max_tension(new_value : float) -> void:
	max_tension = max(1.0, new_value) # can't have zero
