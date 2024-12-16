class_name ArcheryTutorialUI
extends Control


@onready var _tutorial_content_label : RichTextLabel = get_node("PanelContainer/VBoxContainer/TutorialContentLabel")
@onready var _bow : Bow = get_tree().get_first_node_in_group("bow")
@onready var _puntukas : Puntukas = get_tree().get_first_node_in_group("puntukas")
@onready var _creature_manager : CreatureManager = _puntukas.get_node("../Creatures")
@onready var _panel : PanelContainer = get_node("PanelContainer")
@onready var _show_button : Button = get_node("ShowButton")
@onready var _audio : AudioStreamPlayer = get_node("AudioStreamPlayer")

## The text contents of the tutorial. Key is stage name. Value is the text content.
var _contents : TutorialContent = ResourceLoader.load("res://scripts/tutorial_content/archery_tutorial_content.tres")

func _ready() -> void:
	_tutorial_content_label.text = _contents.contents["pick_up_bow"]
	_panel.visible = true
	_show_button.visible = false
	_bow.picked_up.connect(_on_bow_picked_up)
	_bow.get_node("PullPivot/ArrowSnapZone").has_picked_up.connect(_on_arrow_nocked)
	_creature_manager.automatic_respawn = false
	_puntukas.enabled = false


func _on_bow_picked_up(_pickable : PhysicalPickable) -> void:
	_audio.play()
	_tutorial_content_label.text = _contents.contents["arrow"]
	_panel.visible = true
	_show_button.visible = false


func _on_arrow_nocked(_what: Node3D) -> void:
	_audio.play()
	_bow.get_node("PullPivot/ArrowSnapZone").has_picked_up.disconnect(_on_arrow_nocked)
	_tutorial_content_label.text = _contents.contents["shooting_at_stationary"]
	_creature_manager.bezdukas_count = 0
	_creature_manager.kipsas_count = 1
	_creature_manager.animation_playback_speed = 0
	_creature_manager.move_speed = 0
	_creature_manager.all_kipsas_dead.connect(_on_stationary_complete)
	_creature_manager.respawn_creatures()
	_puntukas.toggle_creature_movement.emit()
	_panel.visible = true
	_show_button.visible = false


func _on_stationary_complete() -> void:
	_audio.play()
	_creature_manager.all_kipsas_dead.disconnect(_on_stationary_complete)
	_tutorial_content_label.text = _contents.contents["shooting_at_different"]
	_creature_manager.bezdukas_count = 1
	_creature_manager.kipsas_count = 2
	_creature_manager.all_kipsas_dead.connect(_on_different_complete)
	_creature_manager.respawn_creatures()
	_puntukas.toggle_creature_movement.emit()
	_panel.visible = true
	_show_button.visible = false


func _on_different_complete() -> void:
	_audio.play()
	_creature_manager.all_kipsas_dead.disconnect(_on_different_complete)
	_tutorial_content_label.text = _contents.contents["shooting_at_moving"]
	_creature_manager.bezdukas_count = 2
	_creature_manager.kipsas_count = 3
	_creature_manager.animation_playback_speed = 2
	_creature_manager.move_speed = 4
	_creature_manager.all_kipsas_dead.connect(_on_moving_complete)
	_creature_manager.respawn_creatures()
	_puntukas.toggle_creature_movement.emit()
	_panel.visible = true
	_show_button.visible = false


func _on_moving_complete() -> void:
	_audio.play()
	_creature_manager.all_kipsas_dead.disconnect(_on_moving_complete)
	_tutorial_content_label.text = _contents.contents["final"]
	_creature_manager.bezdukas_count = 2
	_creature_manager.kipsas_count = 4
	_creature_manager.animation_playback_speed = 2
	_creature_manager.move_speed = 4
	_creature_manager.all_kipsas_dead.connect(_on_tutorial_complete)
	_creature_manager.respawn_creatures()
	_puntukas.toggle_creature_movement.emit()
	_puntukas.enabled = true
	_panel.visible = true
	_show_button.visible = false


func _on_tutorial_complete() -> void:
	_audio.play()
	_creature_manager.all_kipsas_dead.disconnect(_on_tutorial_complete)
	_tutorial_content_label.text = _contents.contents["finished"]
	_creature_manager.automatic_respawn = true
	_creature_manager.respawn_creatures()
	_panel.visible = true
	_show_button.visible = false


func _on_hide_button_pressed() -> void:
	_panel.visible = false
	_show_button.visible = true


func _on_show_button_pressed() -> void:
	_panel.visible = true
	_show_button.visible = false
