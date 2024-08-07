class_name DistractionFish
extends Distraction

@onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")

func activate(spawn_position: Vector3, _fishing_rod: FishingRod):
	print("Fish distraction activated")
	active = true
	global_position = spawn_position
	var random_angle = randf_range(0, TAU)
	rotation.y = random_angle
	set_process(true)
	visible = true
	animation_player.play("jump")
	

func _on_animation_finished(anim_name: StringName):
	if anim_name == "jump":
		deactivate()
