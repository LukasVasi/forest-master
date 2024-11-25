class_name FishingStatistics
extends Resource

## The current session's statistics for the fishing mingame/

## Number of fishing sessions.
@export var total_fishing_sessions : int = 0

## Number of fish caught (successful fishing sessions).
@export var fish_caught : int = 0

## Number of snaps (failed fishing sessions).
@export var snaps : int = 0

## Total number of trials.
@export var total_trials : int = 0

## Number of successful trials.
@export var completed_trials : int = 0

## Number of failed trials.
var failed_trials : int : get = _get_failed_trials

func _get_failed_trials() -> int:
	return total_trials - completed_trials
