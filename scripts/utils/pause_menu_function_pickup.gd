class_name PauseMenuFunctionPickup
extends Node3D

## Pickup enabled property.
@export var enabled : bool = false

## Grip controller axis for picking up.
@export var pickup_axis_action : String = "grip"

## Grip controller axis for resetting the menu.
@export var reset_action : String = "by_button"

## The joystick action for changing the container's offset.
@export var joystick_action : String = "primary"

## Controller of this function pickup.
@onready var _controller := XRHelpers.get_xr_controller(self)

## Grip threshold (from configuration) for pickup and reset buttons.
@onready var _grip_threshold : float = XRTools.get_grip_threshold()

## Find the pause menu container.
@onready var _pause_menu_container : PauseMenuContainer = get_tree().get_first_node_in_group("pause_menu_container")

var _grip_pressed : bool = false

func _ready() -> void:
	enabled = PauseManager.paused
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)
	_controller.button_pressed.connect(_on_button_pressed)


func _physics_process(delta: float) -> void:
	# Skip if disabled, or the controller isn't active
	if !enabled or !_controller.get_is_active():
		return

	# Handle our grip
	var grip_value := _controller.get_float(pickup_axis_action)
	if (_grip_pressed and grip_value < (_grip_threshold - 0.1)):
		_grip_pressed = false
		_on_grip_release()
	elif (!_grip_pressed and grip_value > (_grip_threshold + 0.1)):
		_grip_pressed = true
		_on_grip_pressed()
	
	# Handle thumb stick
	var thumb_stick_value := _controller.get_vector2(joystick_action)
	_pause_menu_container.move_grab(delta, thumb_stick_value)


func _on_pause_state_changed(paused: bool) -> void:
	enabled = paused


func _on_button_pressed(p_button: String) -> void:
	if p_button == reset_action:
		_pause_menu_container.reset_offset()


func _on_grip_pressed() -> void:
	_pause_menu_container.pick_up(self)


func _on_grip_release() -> void:
	_pause_menu_container.let_go()
