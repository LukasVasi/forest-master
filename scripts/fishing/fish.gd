@tool
class_name Fish
extends CookableObject

## The fish object.
##
## Extends [XRToolsPickable]. Is spawned by fishing water. Can be put on the wok.

enum FishType {
	Raude,
	Kuoja,
	Lynas
}

@export var type : FishType
