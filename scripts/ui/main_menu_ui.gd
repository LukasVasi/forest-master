class_name MainMenuUI
extends Control


@export_file("*.tscn") var world_scene_path : String

@onready var scene_base : SceneBase = get_tree().get_first_node_in_group("scene_base")

@onready var _main_menu_ui : VBoxContainer = get_node("PanelContainer/MainMenuUI")
@onready var _tutorial_ui : TutorialUI = get_node("PanelContainer/TutorialUI")
@onready var _settings_ui : SettingsUI = get_node("PanelContainer/SettingsUI")


func _ready() -> void:
	_hide_all()
	_main_menu_ui.visible = true


func _hide_all() -> void:
	_main_menu_ui.visible = false
	_tutorial_ui.visible = false
	_settings_ui.visible = false


func _on_play_button_pressed() -> void:
	scene_base.load_scene("res://scenes/main.tscn")


func _on_tutorial_button_pressed() -> void:
	_hide_all()
	_tutorial_ui.visible = true


func _on_back_button_pressed() -> void:
	_hide_all()
	_main_menu_ui.visible = true


func _on_settings_button_pressed() -> void:
	_hide_all()
	_settings_ui.visible = true


func _on_quit_button_pressed() -> void:
	get_tree().quit()
