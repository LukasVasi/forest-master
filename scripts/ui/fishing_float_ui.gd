class_name FishingFloatUI
extends PanelContainer

## The direction (relative to the player) where the fish is swimming or biting.
@export var direction: FishingManager.FishDirection = FishingManager.FishDirection.Forward : set = _set_direction
## The tension of the string converted to a 0 to 1 ratio (based on maximum tension).
@export var tension_ratio: float = 0 : set = _set_tension_ratio

@onready var _fish_direction_texture: TextureRect = get_node("Control/FishDirectionTexture")
@onready var _tension_bar: TextureProgressBar = get_node("TensionBar")

func _ready() -> void:
	_update_direction()
	_update_tension_ratio()

func _set_direction(new_direction: FishingManager.FishDirection) -> void:
	direction = new_direction
	_update_direction()


func _update_direction() -> void:
	if not is_instance_valid(_fish_direction_texture):
		return # prevent update before ready
	
	match direction:
		FishingManager.FishDirection.Right:
			_fish_direction_texture.rotation = deg_to_rad(90)
			_fish_direction_texture.flip_v = false
		FishingManager.FishDirection.Left:
			_fish_direction_texture.flip_v = true
			_fish_direction_texture.rotation = deg_to_rad(90)
		FishingManager.FishDirection.Forward:
			_fish_direction_texture.flip_v = false
			_fish_direction_texture.rotation = 0


func _set_tension_ratio(new_tension_ratio: float) -> void:
	tension_ratio = new_tension_ratio
	_update_tension_ratio()


func _update_tension_ratio() -> void:
	if not is_instance_valid(_tension_bar):
		return # prevent update before ready
	
	if tension_ratio < 0:
		_tension_bar.visible = false
	else:
		_tension_bar.value = clamp(tension_ratio, 0.0, 1.0)
		_tension_bar.visible = true
