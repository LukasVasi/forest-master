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

func let_go(by: Node3D, p_linear_velocity: Vector3, p_angular_velocity: Vector3) -> void:
	super.let_go(by, p_linear_velocity, p_angular_velocity)

func is_cooked():
	return get_node("Mesh").cooking_level > 0
