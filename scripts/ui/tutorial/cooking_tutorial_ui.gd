class_name CookingTutorialUI
extends Control


@onready var _tutorial_content_label : RichTextLabel = get_node("PanelContainer/VBoxContainer/TutorialContentLabel")
@onready var _fish_dispenser : BucketDispenser = get_tree().get_first_node_in_group("fish_dispenser")
@onready var _campfire : Campfire = get_tree().get_first_node_in_group("campfire")
@onready var _skillet : Skillet = get_tree().get_first_node_in_group("Skillet").get_node("Skillet")
@onready var _audio : AudioStreamPlayer = get_node("AudioStreamPlayer")

## The text contents of the tutorial. Key is stage name. Value is the text content.
var _contents : TutorialContent = ResourceLoader.load("res://scripts/tutorial_content/cooking_tutorial_content.tres")


func _ready() -> void:
	_tutorial_content_label.text = _contents.contents["fish"]
	_fish_dispenser.dispensed.connect(_on_fish_dispenser_dispensed)
	_skillet.tutorial = true
	_skillet.fish_cooked.connect(_on_cooked)


func _on_fish_dispenser_dispensed(pickable : Variant) -> void:
	_audio.play()
	_fish_dispenser.dispensed.disconnect(_on_fish_dispenser_dispensed)
	_tutorial_content_label.text = _contents.contents["fire"]
	_campfire.started_burning.connect(_on_fire_started_burning)


func _on_fire_started_burning() -> void:
	_audio.play()
	_campfire.started_burning.disconnect(_on_fire_started_burning)
	_tutorial_content_label.text = _contents.contents["cooking"]


func _on_cooked() -> void:
	_audio.play()
	# TODO: I mean this whole part of logic is coded in a way that is just abismal
	_skillet.fish_cooked.disconnect(_on_cooked)
	_tutorial_content_label.text = _contents.contents["finish"]
