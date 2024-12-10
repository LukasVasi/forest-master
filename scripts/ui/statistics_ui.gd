class_name StatisticsUI
extends VBoxContainer


signal back_button_pressed

#region Current statistics

@onready var _current_time : Label = get_node("TabContainer/Current session/TabContainer/General/CurrentPlayTimeHBox/TimeLabel")
@export var _current_fishing_goal : CheckBox
@export var _current_cooking_goal : CheckBox
@export var _current_archery_goal : CheckBox

#region Fishing

@onready var _current_fishing_sessions : Label = get_node("TabContainer/Current session/TabContainer/Fishing/TotalFishingSessionsHBox/ValueLabel")
@onready var _fish_caught : Label = get_node("TabContainer/Current session/TabContainer/Fishing/FishCaughtHBox/ValueLabel")
@onready var _snaps : Label = get_node("TabContainer/Current session/TabContainer/Fishing/TimesRodSnappedHBox/ValueLabel")
@onready var _total_trials : Label = get_node("TabContainer/Current session/TabContainer/Fishing/TotalTrialsHBox/ValueLabel")
@onready var _completed_trials : Label = get_node("TabContainer/Current session/TabContainer/Fishing/CompletedTrialsHBox/ValueLabel")

#endregion

#region Archery

@export var _current_archery_sessions : Label
@export var _current_archery_shots : Label
@export var _current_archery_misses : Label
@export var _current_archery_hits : Label
@export var _current_archery_friendly_fire : Label

#endregion

#endregion

#region All time statistics

@onready var _total_time : Label = get_node("TabContainer/All time/TotalPlayTimeHBox/TimeLabel")
@onready var _total_fishing_sessions : Label = get_node("TabContainer/All time/TotalFishingSessionsHBox/ValueLabel")
@onready var _total_cooking_sessions : Label = get_node("TabContainer/All time/TotalCookingSessionsHBox/ValueLabel")
@onready var _total_archery_sessions : Label = get_node("TabContainer/All time/TotalArcherySessionsHBox/ValueLabel")

#endregion


func _process(_delta: float) -> void:
	if visible:
		_total_time.text = _get_time_string(StatisticsManager.user_statistics.get_total_play_time())
		_current_time.text = _get_time_string(StatisticsManager.user_statistics.get_current_play_time())


func _on_visibility_changed() -> void:
	# Update statistics when displayed
	if visible and is_node_ready():
		
		var fishing_statistics: FishingStatistics = StatisticsManager.user_statistics.get_current_fishing_statistics()
		_current_fishing_goal.button_pressed = fishing_statistics.total_fishing_sessions > 0
		_current_fishing_sessions.text = str(fishing_statistics.total_fishing_sessions)
		_fish_caught.text = str(fishing_statistics.fish_caught)
		_snaps.text = str(fishing_statistics.snaps)
		_total_trials.text = str(fishing_statistics.total_trials)
		_completed_trials.text = str(fishing_statistics.completed_trials)
		
		var archery_statistics : ArcheryStatistics = StatisticsManager.user_statistics.get_current_archery_statistics()
		_current_archery_goal.button_pressed = archery_statistics.total_archery_sessions > 0
		_current_archery_sessions.text = str(archery_statistics.total_archery_sessions)
		_current_archery_shots.text = str(archery_statistics.shots)
		_current_archery_misses.text = str(archery_statistics.misses)
		_current_archery_hits.text = str(archery_statistics.hits)
		_current_archery_friendly_fire.text = str(archery_statistics.friendly_fire)
		
		_total_fishing_sessions.text = str(StatisticsManager.user_statistics.get_total_fishing_sessions())
		_total_cooking_sessions.text = str(StatisticsManager.user_statistics.get_total_cooking_sessions())
		_total_archery_sessions.text = str(StatisticsManager.user_statistics.get_total_archery_sessions())


func _get_time_string(total_time: int) -> String:
	var time_string : String = ""
	var total_play_days := total_time / 86400
	total_time %= 86400
	var total_play_hours := total_time / 3600
	total_time %= 3600
	var total_play_minutes := total_time / 60
	total_time %= 60
	
	if total_play_days > 0: time_string += str(total_play_days, " d ")
	if total_play_hours > 0: time_string += str(total_play_hours, " h ")
	if total_play_minutes > 0: time_string += str(total_play_minutes, " m ")
	time_string += str(total_time, " s")
	
	return time_string


func _on_back_button_pressed() -> void:
	back_button_pressed.emit()
