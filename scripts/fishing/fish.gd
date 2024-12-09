@tool
class_name Fish
extends CookableObject

## The fish object.
##
## Extends [XRToolsPickable]. Is spawned by fishing water. Can be put on the wok.

## Signal emitted when the fish is stored (in the bucket).
signal stored

enum FishType {
	Raude,
	Kuoja,
	Lynas
}

@export var type : FishType

func store() -> void:
	# TODO: change this implementation
	stored.emit()
	queue_free()
