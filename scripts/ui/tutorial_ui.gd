class_name TutorialUI
extends VBoxContainer


@onready var _main_menu_ui : MainMenuUI = get_node("../../")


func _on_basics_tutorial_button_pressed() -> void:
	pass # Replace with function body.


func _on_fishing_tutorial_button_pressed() -> void:
	_main_menu_ui.scene_base.load_scene("res://scenes/tutorials/fishing_tutorial.tscn")


func _on_archery_tutorial_button_pressed() -> void:
	_main_menu_ui.scene_base.load_scene("res://scenes/tutorials/archery_tutorial.tscn")


func _on_cooking_tutorial_button_pressed() -> void:
	pass # Replace with function body.
