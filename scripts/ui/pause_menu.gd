class_name PauseMenu
extends Control

@onready var _settings_ui : SettingsUI = get_node("SettingsUI")

@onready var _pause_menu_ui : PanelContainer = get_node("PauseMenuUI")

## The player's camera. Only retrieves and works with the camera in main.
@onready var player_camera: XRCamera3D = get_tree().get_first_node_in_group("player").get_node("XRCamera3D")

## The player's body.
@onready var player_body: PlayerBody = get_tree().get_first_node_in_group("player").get_node("PlayerBody")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide all the UIs
	_pause_menu_ui.visible = false
	_settings_ui.visible = false
	
	# Connect to pause manager
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)


## Method that handles the pause state change singal from PauseManager
func _on_pause_state_changed(paused : bool) -> void:
	if paused:
		_pause_menu_ui.visible = true
	else:
		_pause_menu_ui.visible = false
		_settings_ui.visible = false

func _on_resume_button_pressed() -> void:
	PauseManager.set_pause(false)


func _on_settings_button_pressed() -> void:
	_pause_menu_ui.visible = false
	_settings_ui.visible = true


func _on_restart_game_button_pressed() -> void:
	# Unpause the game as it keeps the paused state
	PauseManager.set_pause(false)
	# Clear the rumble manager
	RumbleManager.clear()
	# Reload the game
	get_tree().reload_current_scene()


func _on_exit_game_button_pressed() -> void:
	get_tree().quit()


func _on_back_to_menu_button_pressed() -> void:
	_settings_ui.visible = false
	_pause_menu_ui.visible = true


func _player_height_changed(_new_height: float) -> void:
	player_body.calibrate_player_height()
