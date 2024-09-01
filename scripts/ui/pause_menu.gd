class_name PauseMenu
extends Control

# The viewoport 2d in 3d that contains the pause menu.
# It should be the grandparent (2din3dviewport/viewport/menu)
@onready var pause_menu_viewport : Node3D = get_node("../../")

@onready var settings_ui : SettingsUI = get_node("Background/SettingsUI")

@onready var pause_menu_ui : MarginContainer = get_node("Background/PauseMenuUI")

## The player's camera. Only retrieves and works with the camera in main.
@onready var player_camera: XRCamera3D = get_node("/root/Staging/Scene/Main/XROrigin3D/XRCamera3D")

## Distance from camera to the menu when displayed.
@export var distance: float = 1.0

var _paused : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Hide the viewport
	pause_menu_viewport.visible = false
	pause_menu_viewport.enabled = false
	
	# Hide all the UIs
	pause_menu_ui.visible = false
	settings_ui.visible = false
	
	# Connect to pause manager
	PauseManager.pause_state_changed.connect(_on_pause_state_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if _paused:
		_position_menu()


func _position_menu():
	# Get the forward direction of the player's camera
	var forward_dir: Vector3 = player_camera.global_transform.basis.z.normalized()
	
	# Position the menu in front of the player
	var new_position: Vector3 = player_camera.global_transform.origin - forward_dir * distance
	pause_menu_viewport.position = new_position
	
	# Rotate the viewport to face the player
	pause_menu_viewport.look_at(player_camera.global_transform.origin, Vector3.UP, true)


## Method that handles the pause state change singal from PauseManager
func _on_pause_state_changed(paused : bool):
	if paused:
		_paused = true
		pause_menu_viewport.visible = true
		pause_menu_viewport.set_enabled(true)
		pause_menu_ui.visible = true
	else:
		_paused = false
		pause_menu_viewport.visible = false
		pause_menu_viewport.set_enabled(false)
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
