class_name FishingFloatUI
extends Control

@export var state: State = State.DirectionArrowRight: set = _set_state

@onready var direction_arrow_texture: TextureRect = get_node("DirectionArrowTexture")

enum State {
	DirectionArrowRight,
	DirectionArrowLeft,
	DirectionArrowUp
}

func _ready() -> void:
	_update_state()

func _set_state(new_state: State) -> void:
	state = new_state
	_update_state()


func _update_state() -> void:
	if not is_instance_valid(direction_arrow_texture):
		return # prevent update before ready
	
	match state:
		State.DirectionArrowRight:
			direction_arrow_texture.flip_h = false
		State.DirectionArrowLeft:
			direction_arrow_texture.flip_h = true
		State.DirectionArrowUp:
			# TODO
			pass
