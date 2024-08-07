@tool
class_name FishingRod
extends XRToolsPickable


## The fishing rod object.
##
## This extends the XRToolsPickable script that allows a [RigidBody3D] to be picked up by an
## [XRToolsFunctionPickup] attached to a players controller.
##
## The fishing rod contains (as its children) the [FishingFloat] and [Line] objects.

## Signal emittted when the fishing rod is tugged. 
signal tugged

## The fishing float.
@onready var fishing_float: FishingFloat = get_node("../FishingFloat")

## The float target.
@onready var float_target: FishingFloatTarget = get_node("FloatTarget")

var player_body: XRToolsPlayerBody

var _moved: bool = false

func _ready():
	super._ready()
	
	if Engine.is_editor_hint():
		return
		
	player_body = get_node("../../XROrigin3D/PlayerBody")

func _process(_delta):
	if (
			_moved and not is_picked_up() and player_body 
			and global_position.distance_to(player_body.global_position) > 10.0
	):
		reset()


func pick_up(by: Node3D) -> void:
	super.pick_up(by) # Run the parent pick up function
	_moved = true
	float_target.set_picked_up(true) # Tell the target to start calculating velocity


func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	super.let_go(by, p_linear_velocity, p_angular_velocity) # Run the parent function
	float_target.set_picked_up(false) # Tell the target to stop calculating velocity


func handle_tug():
	tugged.emit()


func reset():
	#print("Resetting")
	emit_signal("action_pressed", self) # resets the float
	_moved = false


func trigger_haptic(duration: float, delay: float):
	var controller: XRController3D = get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.5, 0.2, duration, delay) # vibrate on wind
