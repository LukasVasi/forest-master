class_name SettingsUI
extends PanelContainer


## Used to notify the pause menu about a change to player height
signal player_height_changed(new_height: float)


@onready var _snap_turning_button: CheckBox = get_node("SettingsVBox/TabContainer/Movement/SnapTurning/SnapTurningCB")
@onready var _movement_direct_button: CheckBox = get_node("SettingsVBox/TabContainer/Movement/DirectMovement/DirectMovementCB")
@onready var _x_deadzone_slider: HSlider = get_node("SettingsVBox/TabContainer/Input/xAxisDeadZone/xAxisDeadZoneSlider")
@onready var _y_deadzone_slider: HSlider = get_node("SettingsVBox/TabContainer/Input/yAxisDeadZone/yAxisDeadZoneSlider")
@onready var _sfx_volume: HSlider = get_node("SettingsVBox/TabContainer/Volume/SFXVolume/SFXVolumeSlider")
@onready var _music_volume: HSlider = get_node("SettingsVBox/TabContainer/Volume/MusicVolume/MusicVolumeSlider")
@onready var _player_height_slider: HSlider = get_node("SettingsVBox/TabContainer/Additional/PlayerHeight/PlayerHeightSlider")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if UserSettings:
		_update()
	else:
		$Save/Button.disabled = true


func _update() -> void:
	# Movement
	_snap_turning_button.button_pressed = UserSettings.snap_turning
	_movement_direct_button.button_pressed = UserSettings.movement_direct
	
	# Input
	_y_deadzone_slider.value = UserSettings.y_axis_dead_zone
	_x_deadzone_slider.value = UserSettings.x_axis_dead_zone

	# Volume
	_sfx_volume.value = UserSettings.sfx_volume
	_music_volume.value = UserSettings.music_volume

	# Player
	_player_height_slider.value = UserSettings.player_height


func _on_Save_pressed() -> void:
	if UserSettings:
		# Save
		UserSettings.save()


func _on_Reset_pressed() -> void:
	if UserSettings:
		UserSettings.reset_to_defaults()
		_update()
		player_height_changed.emit(UserSettings.player_height)


# Input settings changed
func _on_SnapTurningCB_pressed() -> void:
	UserSettings.snap_turning = _snap_turning_button.button_pressed


# Input settings changed
func _on_MovementDirectCB_pressed() -> void:
	UserSettings.movement_direct = _movement_direct_button.button_pressed


func _on_y_axis_dead_zone_slider_value_changed(value: float) -> void:
	UserSettings.y_axis_dead_zone = _y_deadzone_slider.value


func _on_x_axis_dead_zone_slider_value_changed(value: float) -> void:
	UserSettings.x_axis_dead_zone = _x_deadzone_slider.value


# Player settings changed
func _on_PlayerHeightSlider_drag_ended(_value_changed: float) -> void:
	UserSettings.player_height = _player_height_slider.value
	player_height_changed.emit(UserSettings.player_height)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	UserSettings.sfx_volume = value


func _on_music_volume_slider_value_changed(value: float) -> void:
	UserSettings.music_volume = value
