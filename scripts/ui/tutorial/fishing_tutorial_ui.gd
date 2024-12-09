class_name FishingTutorialUI
extends Control


@onready var _tutorial_content_label : RichTextLabel = get_node("PanelContainer/VBoxContainer/TutorialContentLabel")
@onready var _fishing_rod : FishingRod = get_tree().get_first_node_in_group("fishing_rod")
@onready var _fishing : FishingManager = get_tree().get_first_node_in_group("fishing")

## The text contents of the tutorial. Key is stage name. Value is the text content.
var _contents : TutorialContent = ResourceLoader.load("res://scripts/tutorial_content/fishing_tutorial_content.tres")

var _fish : Fish


func _ready() -> void:
	_tutorial_content_label.text = _contents.contents["pick_up_fishing_rod"]
	_fishing.on_state_changed.connect(_on_fishing_state_changed)
	_fishing.fish_caught.connect(_on_fish_caught)
	_fishing_rod.picked_up.connect(_on_fishing_rod_picked_up)
	_fishing_rod.dropped.connect(_on_fishing_rod_dropped)
	await _fishing_rod.ready # wait for fishing rod to be fully initialized
	_fishing_rod.fishing_float.water_entered.connect(_on_float_entered_water)


func _on_fishing_rod_picked_up(_pickable: PhysicalPickable) -> void:
	# Check if picked up by hand and not snap zone
	if is_instance_valid(_fishing_rod.get_picked_up_by_hand()):
		_tutorial_content_label.text = _contents.contents["cast_fishing_rod"]


func _on_fishing_rod_dropped(_pickable: PhysicalPickable) -> void:
	_tutorial_content_label.text = _contents.contents["pick_up_fishing_rod_again"]


func _on_float_entered_water() -> void:
	_tutorial_content_label.text = _contents.contents["pass_trials"]


func _on_fishing_state_changed(new_state : FishingManager.State) -> void:
	if new_state == FishingManager.State.Reeling:
		_tutorial_content_label.text = _contents.contents["reeling"]


func _on_fish_caught(fish : Fish) -> void:
	_tutorial_content_label.text = _contents.contents["catch_fish"]
	if is_instance_valid(_fish):
		_fish.stored.disconnect(_on_fish_stored)
	_fish = fish
	_fish.stored.connect(_on_fish_stored)


func _on_fish_stored() -> void:
	_tutorial_content_label.text = _contents.contents["finished"]
	
	# Disconnect all used signals
	_fishing.on_state_changed.disconnect(_on_fishing_state_changed)
	_fishing.fish_caught.disconnect(_on_fish_caught)
	_fishing_rod.picked_up.disconnect(_on_fishing_rod_picked_up)
	_fishing_rod.dropped.disconnect(_on_fishing_rod_dropped)
	_fish.stored.disconnect(_on_fish_stored)
	
