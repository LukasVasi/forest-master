class_name SessionStatistics
extends Resource

## The date and time of this session's start.
@export var start_time : String

## The date and time of this session's end.
@export var end_time : String

## The time inbetween the start and end where the player wasn't playing.
@export var time_delta : int = 0

## This session's fishing statistics.
@export var fishing : FishingStatistics = FishingStatistics.new()

## This session's cooking statistics.
@export var cooking : CookingStatistics = CookingStatistics.new()

## This session's archery statistics.
@export var archery : ArcheryStatistics = ArcheryStatistics.new()

func _init() -> void:
	start_time = Time.get_datetime_string_from_system(true)


## Returns the session's play time in seconds.
func get_play_time() -> int:
	if not end_time.is_empty():
		# Calculate the play time from the start and end times while accounting time delta
		return Time.get_unix_time_from_datetime_string(end_time) - Time.get_unix_time_from_datetime_string(start_time) - time_delta
	else:
		# Calcualte the play time from the start time and current time while accounting time delta
		return roundi(Time.get_unix_time_from_system()) - Time.get_unix_time_from_datetime_string(start_time) - time_delta
