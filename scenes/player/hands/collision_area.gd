class_name HandCollisionArea
extends Area3D


@onready var physical_hand : PhysicalHand = get_node("../")

var _preserved_collision_exceptions : Array[Node]


func _physics_process(_delta: float) -> void:
	var overlapping_bodies := get_overlapping_bodies()
	for preserved_exception : Node in _preserved_collision_exceptions:
		if preserved_exception not in overlapping_bodies:
			# No longer colliding with the object, can remove the exception
			physical_hand.remove_collision_exception_with(preserved_exception)
			_preserved_collision_exceptions.erase(preserved_exception)


func preserve_collision_exception_with(body: Node) -> void:
	if get_overlapping_bodies().has(body):
		# The dropped object is still in the collision area, add an exception
		physical_hand.add_collision_exception_with(body)
		if body not in _preserved_collision_exceptions:
			_preserved_collision_exceptions.append(body)
