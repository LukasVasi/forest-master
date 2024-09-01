class_name SettingsUI
extends MarginContainer

## I've not figured out what this is used for yet
signal player_height_changed(new_height)

@onready var snap_turning_button = get_node("SettingsVBox/SnapTurning/SnapTurningCB")
@onready var movement_direct_button = get_node("SettingsVBox/DirectMovement/DirectMovementCB")
@onready var y_deadzone_slider = get_node("SettingsVBox/yAxisDeadZone/yAxisDeadZoneSlider")
@onready var x_deadzone_slider = get_node("SettingsVBox/xAxisDeadZone/xAxisDeadZoneSlider")
@onready var player_height_slider = get_node("SettingsVBox/PlayerHeight/PlayerHeightSlider")


func _update():
	# Input
	snap_turning_button.button_pressed = XRToolsUserSettings.snap_turning
	movement_direct_button.button_pressed = XRToolsUserSettings.movement_direct
	y_deadzone_slider.value = XRToolsUserSettings.y_axis_dead_zone
	x_deadzone_slider.value = XRToolsUserSettings.x_axis_dead_zone

	# Player
	player_height_slider.value = XRToolsUserSettings.player_height


# Called when the node enters the scene tree for the first time.
func _ready():
	if XRToolsUserSettings:
		_update()
	else:
		$Save/Button.disabled = true


func _on_Save_pressed():
	if XRToolsUserSettings:
		# Save
		XRToolsUserSettings.save()


func _on_Reset_pressed():
	if XRToolsUserSettings:
		XRToolsUserSettings.reset_to_defaults()
		_update()
		emit_signal("player_height_changed", XRToolsUserSettings.player_height)


# Input settings changed
func _on_SnapTurningCB_pressed():
	XRToolsUserSettings.snap_turning = snap_turning_button.button_pressed


# Input settings changed
func _on_MovementDirectCB_pressed():
	XRToolsUserSettings.movement_direct = movement_direct_button.button_pressed


func _on_y_axis_dead_zone_slider_value_changed(value):
	XRToolsUserSettings.y_axis_dead_zone = y_deadzone_slider.value


func _on_x_axis_dead_zone_slider_value_changed(value):
	XRToolsUserSettings.x_axis_dead_zone = x_deadzone_slider.value


# Player settings changed
func _on_PlayerHeightSlider_drag_ended(_value_changed):
	XRToolsUserSettings.player_height = player_height_slider.value
	emit_signal("player_height_changed", XRToolsUserSettings.player_height)
