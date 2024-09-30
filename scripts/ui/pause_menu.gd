class_name PauseMenu
extends Control

@onready var settings_ui : SettingsUI = get_node("Background/SettingsUI")

@onready var pause_menu_ui : MarginContainer = get_node("Background/PauseMenuUI")

## The player's camera. Only retrieves and works with the camera in main.
@onready var player_camera: XRCamera3D = get_tree().get_first_node_in_group("player").get_node("XRCamera3D")

## Distance from camera to the menu when displayed.
@export var distance: float = 1.0

var _paused : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Hide all the UIs
	pause_menu_ui.visible = false
	settings_ui.visible = false
	
	# Connect to pause manager
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)


## Method that handles the pause state change singal from PauseManager
func _on_pause_state_changed(paused : bool):
	if paused:
		_paused = true
		pause_menu_ui.visible = true
	else:
		_paused = false
		pause_menu_ui.visible = false
		settings_ui.visible = false

func _on_resume_button_pressed():
	PauseManager.set_pause(false)


func _on_settings_button_pressed():
	pause_menu_ui.visible = false
	settings_ui.visible = true


func _on_restart_game_button_pressed():
	# Unpause the game as it keeps the paused state
	PauseManager.set_pause(false)
	# Reload the game
	get_tree().reload_current_scene()


func _on_exit_game_button_pressed():
	get_tree().quit()


func _on_back_to_menu_button_pressed():
	settings_ui.visible = false
	pause_menu_ui.visible = true
