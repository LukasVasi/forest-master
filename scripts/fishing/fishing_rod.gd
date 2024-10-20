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

var player_body: XRToolsPlayerBody

var _moved: bool = false

func _ready() -> void:
	super._ready()
	
	if Engine.is_editor_hint():
		return
		
	player_body = get_tree().get_first_node_in_group("player").get_node("PlayerBody")

func _process(_delta: float) -> void:
	if (
			_moved and not is_picked_up() and player_body 
			and global_position.distance_to(player_body.global_position) > 10.0
	):
		reset()


func pick_up(by: PhysicalHand) -> PhysicalGrab:
	_moved = true
	float_target.set_picked_up(true) # Tell the target to start calculating velocity
	return super.pick_up(by) # Run the parent pick up function


func let_go(by: PhysicalHand) -> void:
	super.let_go(by) # Run the parent function
	float_target.set_picked_up(false) # Tell the target to stop calculating velocity


func handle_tug() -> void:
	tugged.emit()


func reset() -> void:
	#print("Resetting")
	emit_signal("action_pressed", self) # resets the float
	_moved = false


func trigger_haptic(duration: float, delay: float) -> void:
	var controller: XRController3D = get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0.5, 0.2, duration, delay) # vibrate on wind
