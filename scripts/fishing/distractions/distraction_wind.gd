class_name DistractionWind
extends Distraction

@onready var audio_player: AudioStreamPlayer3D = get_node("AudioStreamPlayer3D")

## The time it takes to fade in from silent to full volume
@export var fade_in_duration: float = 4.0

## The time it stays at full volume.
@export var middle_duration: float = 1.0

## The time it takes to fade out.
@export var fade_out_duration: float = 3.0

## The maximum volume the wind audio will reach.
@export var max_volume_db: float = -8

## The rumble event used to provide rumble feedback when the wind is active.
@export var rumble_event : XRToolsRumbleEvent

## The minimum volume - cant hear it or anything lower.
var min_volume_db: float = -30

func activate(spawn_position: Vector3, fishing_rod: FishingRod):
	print("Wind distraction activated")
	active = true
	global_position = spawn_position
	var tween = create_tween()
	set_process(true)
	visible = true
	audio_player.volume_db = -min_volume_db
	audio_player.play(0.0)
	if fishing_rod.is_picked_up():
		var hand := fishing_rod.get_picked_up_by_hand()
		if is_instance_valid(hand):
			var rumble_trackers := hand.rumble_trackers
			rumble_event.duration_ms = fade_in_duration + middle_duration + fade_out_duration / 2
			RumbleManager.add(self, rumble_event, rumble_trackers)
	tween.tween_property(audio_player, "volume_db", max_volume_db, fade_in_duration).set_ease(Tween.EASE_IN) # fade in
	tween.tween_property(audio_player, "volume_db", -80, fade_out_duration).set_ease(Tween.EASE_OUT).set_delay(middle_duration) # fade out
	tween.tween_callback(deactivate)

func deactivate():
	audio_player.stop()
	super.deactivate()
