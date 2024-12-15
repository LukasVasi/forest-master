class_name GhostFishingRod
extends MeshInstance3D

@export var fishing_rod : FishingRod

@onready var animation_player : AnimationPlayer = get_node("AnimationPlayer")
@onready var positionator : Node3D = get_node("../")


func visualize(direction : FishingManager.FishDirection) -> void:
	if not is_instance_valid(fishing_rod):
		print_verbose("FIshing rod not found in ", self)
		return
	
	if animation_player.is_playing():
		return
	
	var animation_name : String
	match direction:
		FishingManager.FishDirection.Forward:
			animation_name = "yank_forward"
		FishingManager.FishDirection.Right:
			animation_name = "yank_right"
		_:
			animation_name = "yank_left"
	
	# Teleport to fishing rod and show animation
	positionator.global_transform = fishing_rod.global_transform
	visible = true
	animation_player.play(animation_name)
	await animation_player.animation_finished
	visible = false
	animation_player.play("RESET")
