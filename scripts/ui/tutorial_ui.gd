class_name TutorialUI
extends VBoxContainer


@export_file("*.tscn") var fishing_tutorial_scene_path : String = ""
@export_file("*.tscn") var archery_tutorial_scene_path : String = ""

@onready var _main_menu_ui : MainMenuUI = get_node("../../")


func _on_basics_tutorial_button_pressed() -> void:
	pass # Replace with function body.


func _on_fishing_tutorial_button_pressed() -> void:
	if (
			not fishing_tutorial_scene_path.is_empty() and 
			FileAccess.file_exists(fishing_tutorial_scene_path)
	):
		_main_menu_ui.scene_base.load_scene(fishing_tutorial_scene_path)
	else:
		push_error("Invalid fishing tutorial path provided")


func _on_combat_tutorial_button_pressed() -> void:
	if (
			not archery_tutorial_scene_path.is_empty() and 
			FileAccess.file_exists(archery_tutorial_scene_path)
	):
		_main_menu_ui.scene_base.load_scene(archery_tutorial_scene_path)
	else:
		push_error("Invalid archery tutorial path provided")


func _on_cooking_tutorial_button_pressed() -> void:
	pass # Replace with function body.
