class_name UserStatistics
extends Resource

## All saved session statistics. Private but @export is needed to save in resource.
@export var _session_statistics_history : Array[SessionStatistics] = []

var _current_session : SessionStatistics

#region Session management
func start_session() -> void:
	# New session if no history
	if _session_statistics_history.is_empty():
		_current_session = SessionStatistics.new()
		_session_statistics_history.append(_current_session)
		return
	
	# Get last session from history
	var last_session: SessionStatistics = _session_statistics_history.back()
	
	# Get the last session's end time in unix
	var last_end_time := Time.get_unix_time_from_datetime_string(last_session.end_time)
	
	# Get the time difference between last session's end and now (in seconds)
	var time_delta: int = roundi(Time.get_unix_time_from_system()) - last_end_time
	
	# If more than an hour has passed since the last session - start a new one
	# Otherwise use the last session
	if time_delta > 3600:
		_current_session = SessionStatistics.new()
		_session_statistics_history.append(_current_session)
	else:
		_current_session = last_session
		last_session.end_time = ""
		last_session.time_delta += time_delta


func end_session() -> void:
	_current_session.end_time = Time.get_datetime_string_from_system(true)
#endregion

#region Play time
## Returns the play time of current session.
func get_current_play_time() -> int:
	return _current_session.get_play_time()


## Returns the total play time of all sessions.
func get_total_play_time() -> int:
	var total_play_time: int = 0
	for session: SessionStatistics in _session_statistics_history:
		total_play_time += session.get_play_time()
	return total_play_time
#endregion

#region Fishing
## Adds the details of a fishing session to the statistics.
func add_fishing_session(fish_caught: bool, rod_snapped: bool, total_trials: int, completed_trials: int) -> void:
	_current_session.fishing.total_fishing_sessions += 1
	
	if fish_caught:
		_current_session.fishing.fish_caught += 1
	if rod_snapped:
		_current_session.fishing.snaps += 1
	
	_current_session.fishing.total_trials += total_trials
	_current_session.fishing.completed_trials += completed_trials

## Returns a copy of the current fishing statistics.
func get_current_fishing_statistics() -> FishingStatistics:
	return _current_session.fishing.duplicate(true)
#endregion