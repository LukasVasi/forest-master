class_name MainMenuUI
extends Control


@export_file("*.tscn") var world_scene_path : String

@onready var scene_base : SceneBase = get_tree().get_first_node_in_group("scene_base")

@onready var _main_menu_ui : VBoxContainer = get_node("PanelContainer/MainMenuUI")
@onready var _tutorial_ui : TutorialUI = get_node("PanelContainer/TutorialUI")


func _ready() -> void:
	_main_menu_ui.visible = true
	_tutorial_ui.visible = false


func _on_play_button_pressed() -> void:
	#scene_base.load_scene("res://scenes/main.tscn")
	scene_base.load_scene("res://scenes/tutorials/fishing_tutorial.tscn")


func _on_tutorial_button_pressed() -> void:
	_main_menu_ui.visible = false
	_tutorial_ui.visible = true


func _on_back_button_pressed() -> void:
	_tutorial_ui.visible = false
	_main_menu_ui.visible = true
