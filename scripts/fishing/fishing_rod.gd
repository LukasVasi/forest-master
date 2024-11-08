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

func _ready() -> void:
	super()
	
	handle.enabled = false
	
	if Engine.is_editor_hint():
		return
	
	player_body = get_tree().get_first_node_in_group("player").get_node("PlayerBody")

func _process(_delta: float) -> void:
	_update_spinner_bone_rotation()
	
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


func _update_spinner_bone_rotation() -> void:
	# Get the direction to the handle
	var direction_to_handle := center_of_spinner.to_local(handle.global_position) #handle_origin.position + handle.position
	direction_to_handle.x = 0
	direction_to_handle = direction_to_handle.normalized()
	
	# Calculate the target rotation of the bone and apply it
	var target_rotation := Quaternion(Vector3.RIGHT, deg_to_rad(90) + atan2(direction_to_handle.z, direction_to_handle.y))
	fishing_rod_skeleton.set_bone_pose_rotation(1, target_rotation)
	
	# Move the handle origin to the appropriate position
	var offset_to_handle := 0.03 * direction_to_handle # 0.03 - spinner radius
	handle_origin.position = Vector3(-0.165, offset_to_handle.y, offset_to_handle.z)


func on_water_entered(_water_height: float) -> void:
	drop()
	reset()
