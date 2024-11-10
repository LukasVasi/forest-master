@tool
class_name FishingRod
extends PhysicalPickable


## The fishing rod object.
##
## This extends the XRToolsPickable script that allows a [RigidBody3D] to be picked up by an
## [XRToolsFunctionPickup] attached to a players controller.
##
## The fishing rod contains (as its children) the [FishingFloat] and [Line] objects.

## Signal emittted when the fishing rod is tugged. 
signal tugged

## The amount of meters that the fishing float is reeled in per full turn of the spinner
@export var reel_in_amount: float = 0.6

## The distance at which the float is reset when reeling in
@export var float_reset_distance: float = 1.0

## The fishing float.
@onready var fishing_float: FishingFloat = get_node("FishingFloat")

## The float target.
@onready var float_target: FishingFloatTarget = get_node("FloatTarget")

@onready var fishing_rod_skeleton: Skeleton3D = get_node("FishingRodArmature/Skeleton3D")

@onready var center_of_spinner: Node3D = get_node("CenterOfSpinner")

@onready var handle_origin: Node3D = get_node("CenterOfSpinner/HandleOrigin")

@onready var handle: PhysicalInteractableHandle = get_node("CenterOfSpinner/HandleOrigin/SpinnerHandle")

@onready var holding_stick_snap: PhysicalSnapZone = get_tree().get_first_node_in_group("holding_stick").get_node("PhysicalSnapZone")

var player_body: XRToolsPlayerBody

var _moved: bool = false

var previous_direction_to_handle: Vector3

func _ready() -> void:
	super()
	
	handle.enabled = false
	previous_direction_to_handle = _get_direction_to_handle()
	
	if Engine.is_editor_hint():
		return
	
	player_body = get_tree().get_first_node_in_group("player").get_node("PlayerBody")

func _process(delta: float) -> void:
	if is_picked_up():
		_update_spinner_bone_rotation(delta)
	
	if (
			_moved and not is_picked_up() and player_body 
			and global_position.distance_to(player_body.global_position) > 10.0
	):
		reset()


func pick_up(by: Node3D) -> PhysicalGrab:
	_moved = true
	float_target.set_picked_up(true) # Tell the target to start calculating velocity
	handle.enabled = true
	return super.pick_up(by) # Run the parent pick up function


func let_go(by: Node3D) -> void:
	super.let_go(by) # Run the parent function
	float_target.set_picked_up(false) # Tell the target to stop calculating velocity
	handle.drop()
	handle.enabled = false


func handle_tug() -> void:
	tugged.emit()


func reset() -> void:
	if not fishing_float.connected:
		emit_signal("action_pressed", self) # resets the float
	holding_stick_snap.pick_up_object(self)
	_moved = false


func _update_spinner_bone_rotation(delta: float) -> void:
	# Get the direction to the handle
	var current_direction_to_handle := _get_direction_to_handle()
	
	# Calculate the target rotation of the bone and apply it
	var target_rotation := Quaternion(Vector3.RIGHT, deg_to_rad(90) + atan2(current_direction_to_handle.z, current_direction_to_handle.y))
	fishing_rod_skeleton.set_bone_pose_rotation(1, target_rotation)
	
	# Move the handle origin to the appropriate position
	var offset_to_handle := 0.03 * current_direction_to_handle # 0.03 - spinner radius
	handle_origin.position = Vector3(-0.165, offset_to_handle.y, offset_to_handle.z)
	
	if fishing_float.in_water:
		# Calculate the signed angle difference from previous rotation
		var rotation_angle_delta := current_direction_to_handle.signed_angle_to(previous_direction_to_handle, Vector3.RIGHT)
		# Check if reeling IN
		if rotation_angle_delta > 0:
			# Convert angle difference (radians) to reel in amount: each full turn (2π radians) should move the float by reel_in_amount meters
			var reel_in_delta := rotation_angle_delta / (2 * PI) * reel_in_amount
			# Get the float's XZ direction to fishing rod's tip
			var float_direction_to_target := fishing_float.global_position.direction_to(float_target.global_position)
			float_direction_to_target.y = 0
			float_direction_to_target = float_direction_to_target.normalized()
			# Move the float
			fishing_float.translate(float_direction_to_target * reel_in_delta)
			# Reset the float if it gets close enough (ignore vertical distance)
			var delta_to_rod := fishing_float.global_position - float_target.global_position
			delta_to_rod.y = 0
			if delta_to_rod.length() < float_reset_distance:
				emit_signal("action_pressed", self)
	
	previous_direction_to_handle = current_direction_to_handle

func _get_direction_to_handle() -> Vector3:
	var direction_to_handle := center_of_spinner.to_local(handle.global_position) #handle_origin.position + handle.position
	direction_to_handle.x = 0
	direction_to_handle = direction_to_handle.normalized()
	return direction_to_handle

func on_water_entered(_water_height: float) -> void:
	drop()
	reset()
