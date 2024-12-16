class_name BasicsTutorialUI
extends Control


@onready var _tutorial_content_label : RichTextLabel = get_node("PanelContainer/VBoxContainer/TutorialContentLabel")
@onready var _tutorial_container : Node = get_tree().get_first_node_in_group("tutorial")
@onready var _movement_test_1 : Area3D = _tutorial_container.get_node("MovementTest1")
@onready var _movement_test_2 : Area3D = _tutorial_container.get_node("MovementTest2")
@onready var _movement_test_3 : Area3D = _tutorial_container.get_node("MovementTest3")
@onready var _test_cube : PhysicalPickable = _tutorial_container.get_node("TestCube")
@onready var _drop_test : Area3D = _tutorial_container.get_node("DropTest")
@onready var _audio : AudioStreamPlayer = get_node("AudioStreamPlayer")

## The text contents of the tutorial. Key is stage name. Value is the text content.
var _contents : TutorialContent = ResourceLoader.load("res://scripts/tutorial_content/basics_tutorial_content.tres")


func _ready() -> void:
	_tutorial_content_label.text = _contents.contents["pointer"]
	_test_cube.visible = false
	_test_cube.enabled = false


func _on_button_pressed() -> void:
	_audio.play()
	$PanelContainer/VBoxContainer/Button.visible = false
	_tutorial_content_label.text = _contents.contents["movement"]
	_movement_test_1.body_entered.connect(_on_area_1_entered)
	_movement_test_1.visible = true


func _on_area_1_entered(_body : Node3D) -> void:
	_audio.play()
	_movement_test_1.body_entered.disconnect(_on_area_1_entered)
	_movement_test_1.visible = false
	_movement_test_2.body_entered.connect(_on_area_2_entered)
	_movement_test_2.visible = true


func _on_area_2_entered(_body : Node3D) -> void:
	_audio.play()
	_movement_test_2.body_entered.disconnect(_on_area_2_entered)
	_movement_test_2.visible = false
	_movement_test_3.body_entered.connect(_on_area_3_entered)
	_movement_test_3.visible = true


func _on_area_3_entered(_body : Node3D) -> void:
	_audio.play()
	_movement_test_3.body_entered.disconnect(_on_area_2_entered)
	_movement_test_3.visible = false
	_tutorial_content_label.text = _contents.contents["picking_up"]
	_test_cube.picked_up.connect(_on_picked_up)
	_test_cube.visible = true
	_test_cube.enabled = true


func _on_picked_up(_pickable : PhysicalPickable) -> void:
	_audio.play()
	_tutorial_content_label.text = _contents.contents["carrying"]
	_drop_test.body_entered.connect(_on_cube_moved)
	_drop_test.visible = true


func _on_cube_moved(_body : Node3D) -> void:
	_audio.play()
	_drop_test.body_entered.disconnect(_on_cube_moved)
	_drop_test.visible = false
	_tutorial_content_label.text = _contents.contents["finished"]
