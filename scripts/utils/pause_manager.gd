extends Node

## PauseManager (added to autoload)
## Middle man for handling pausing and unpausing between the pause menu and player

## Singal emmited when the game pause state changes
signal pause_state_changed(paused : bool)

## Varaible that stores current paused state of the game
var paused : bool = false : set = set_pause


## Sets a specific pause state
func set_pause(new_value: bool) -> void:
	paused = new_value
	get_tree().paused = paused
	pause_state_changed.emit(paused)


## Changes the current pause state
func toggle_pause() -> void:
	set_pause(not paused)
