@tool
class_name Fish
extends XRToolsPickable

## The fish object.
##
## Extends [XRToolsPickable]. Is spawned by fishing water. Can be put on the wok.

enum FishType {
	Raude,
	Kuoja,
	Lynas
}

@export var type : FishType

func pick_up(by: Node3D) -> void:
	super.pick_up(by)
	if gravity_scale < 1:
		set_gravity_scale(1)

func is_cooked() -> bool:
	return get_node("Mesh").cooking_level > 0
