class_name SettingsUI
extends VBoxContainer


@onready var _snap_turning_button: CheckBox = get_node("TabContainer/Movement/SnapTurning/SnapTurningCB")
@onready var _movement_direct_button: CheckBox = get_node("TabContainer/Movement/DirectMovement/DirectMovementCB")
@onready var _x_deadzone_slider: HSlider = get_node("TabContainer/Input/xAxisDeadZone/xAxisDeadZoneSlider")
@onready var _y_deadzone_slider: HSlider = get_node("TabContainer/Input/yAxisDeadZone/yAxisDeadZoneSlider")
@onready var _sfx_volume: HSlider = get_node("TabContainer/Volume/SFXVolume/SFXVolumeSlider")
@onready var _music_volume: HSlider = get_node("TabContainer/Volume/MusicVolume/MusicVolumeSlider")
@onready var _player_height_slider: HSlider = get_node("TabContainer/Additional/PlayerHeight/PlayerHeightSlider")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if UserSettings:
		_update()
	else:
		$Buttons/Save.disabled = true


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


func _on_save_pressed() -> void:
	if UserSettings:
		# Save
		UserSettings.save()


func _on_reset_pressed() -> void:
	if UserSettings:
		UserSettings.reset_to_defaults()
		_update()


# Input settings changed
func _on_snap_turning_cb_pressed() -> void:
	UserSettings.snap_turning = _snap_turning_button.button_pressed


# Input settings changed
func _on_direct_movement_cb_pressed() -> void:
	UserSettings.movement_direct = _movement_direct_button.button_pressed


func _on_y_axis_dead_zone_slider_value_changed(value: float) -> void:
	UserSettings.y_axis_dead_zone = _y_deadzone_slider.value


func _on_x_axis_dead_zone_slider_value_changed(value: float) -> void:
	UserSettings.x_axis_dead_zone = _x_deadzone_slider.value


func _on_player_height_slider_drag_ended(_value_changed: float) -> void:
	UserSettings.player_height = _player_height_slider.value


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	UserSettings.sfx_volume = value


func _on_music_volume_slider_value_changed(value: float) -> void:
	UserSettings.music_volume = value
