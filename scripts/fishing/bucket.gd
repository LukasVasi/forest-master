class_name Bucket
extends RigidBody3D

@onready var handle : XRToolsPickable = get_node("../Handle")

# Remember some state so we can return to it when the user drops the object
@onready var original_collision_mask : int = collision_mask
@onready var original_collision_layer : int = collision_layer


func _ready():
	handle.picked_up.connect(_on_picked_up)
	handle.dropped.connect(_on_dropped)


func _on_picked_up(by: Node3D):
	collision_layer = 0b0000_0000_0000_0001_0000_0000_0000_0000 #held object
	collision_mask = 0 # collisions disabled


func _on_dropped(by: Node3D):
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
