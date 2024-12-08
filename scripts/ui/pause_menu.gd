class_name PauseMenu
extends Control

@onready var _pause_menu_ui : VBoxContainer = get_node("PanelContainer/PauseMenuUI")
@onready var _statistics_ui : VBoxContainer = get_node("PanelContainer/StatisticsUI")
@onready var _settings_ui : SettingsUI = get_node("PanelContainer/SettingsUI")
@onready var _tutorial_ui : VBoxContainer =get_node("PanelContainer/TutorialUI")


## The player's camera. Only retrieves and works with the camera in main.
@onready var player_camera: XRCamera3D = get_tree().get_first_node_in_group("player").get_node("XRCamera3D")

## The player's body.
@onready var player_body: PlayerBody = get_tree().get_first_node_in_group("player").get_node("PlayerBody")

## Get the base of the current scene.
@onready var scene_base : SceneBase = get_tree().get_first_node_in_group("scene_base")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide all the UIs
	_hide_all()
	
	# Connect to pause manager
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)


func _hide_all() -> void:
	_pause_menu_ui.visible = false
	_settings_ui.visible = false
	_statistics_ui.visible = false
	_tutorial_ui.visible = false


## Method that handles the pause state change singal from PauseManager
func _on_pause_state_changed(paused : bool) -> void:
	if paused:
		_pause_menu_ui.visible = true
	else:
		_hide_all()

func _on_resume_button_pressed() -> void:
	PauseManager.set_pause(false)


func _on_settings_button_pressed() -> void:
	_hide_all()
	_settings_ui.visible = true


func _on_exit_to_main_menu_button_pressed() -> void:
	scene_base.exit_to_main_menu()


func _on_exit_game_button_pressed() -> void:
	scene_base.handle_close_request()
	get_tree().quit()


func _on_back_to_menu_button_pressed() -> void:
	_hide_all()
	_pause_menu_ui.visible = true


func _on_statistics_button_pressed() -> void:
	_hide_all()
	_statistics_ui.visible = true


func _on_tutorial_button_pressed() -> void:
	_hide_all()
	_tutorial_ui.visible = true
	
