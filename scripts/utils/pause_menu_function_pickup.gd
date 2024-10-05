class_name PauseMenuFunctionPickup
extends Node3D

## Pickup enabled property
@export var enabled : bool = true

## Grip controller axis
@export var pickup_axis_action : String = "grip"

@export var reset_axis_action : String = "trigger"

@export var joystick_action : String = "primary"

## Controller
@onready var _controller := XRHelpers.get_xr_controller(self)

## Grip threshold (from configuration)
@onready var _grip_threshold : float = XRTools.get_grip_threshold()

@onready var _pause_menu_container : PickablePauseMenuContainer = get_tree().get_first_node_in_group("pause_menu_container")

var grip_pressed : bool = false

var reset_pressed : bool = false

func _process(delta: float) -> void:
	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	# Skip if disabled, or the controller isn't active
	if !enabled or !_controller.get_is_active():
		return

	# Handle our grip
	var grip_value := _controller.get_float(pickup_axis_action)
	if (grip_pressed and grip_value < (_grip_threshold - 0.1)):
		grip_pressed = false
		_on_grip_release()
	elif (!grip_pressed and grip_value > (_grip_threshold + 0.1)):
		grip_pressed = true
		_on_grip_pressed()
	
	# Handle reset
	var reset_value := _controller.get_float(reset_axis_action)
	if (reset_pressed and reset_value < (_grip_threshold - 0.1)):
		reset_pressed = false
	elif (!reset_pressed and reset_value > (_grip_threshold + 0.1)):
		reset_pressed = true
		_reset_offset()
	
	# Handle thumb stick
	var thumb_stick_value := _controller.get_vector2(joystick_action)
	_pause_menu_container.move_grab(delta, thumb_stick_value)


func _reset_offset() -> void:
	_pause_menu_container.reset_offset()


func _on_grip_pressed() -> void:
	_pause_menu_container.pick_up(self)


func _on_grip_release() -> void:
	_pause_menu_container.let_go()
