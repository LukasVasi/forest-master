extends Control


@export_file("*.tscn") var world_scene_path : String

@onready var scene_base : SceneBase = get_tree().get_first_node_in_group("scene_base")


func _on_play_button_pressed() -> void:
	scene_base.load_scene("res://scenes/main.tscn")
