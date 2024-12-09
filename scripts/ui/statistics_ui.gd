class_name StatisticsUI
extends VBoxContainer


@onready var _total_time : Label = get_node("StatisticsVBox/TotalPlayTimeHBox/TimeLabel")
@onready var _current_time : Label = get_node("StatisticsVBox/CurrentPlayTimeHBox/TimeLabel")
@onready var _total_fishing_sessions : Label = get_node("StatisticsVBox/TotalFishingSessionsHBox/ValueLabel")
@onready var _fish_caught : Label = get_node("StatisticsVBox/FishCaughtHBox/ValueLabel")
@onready var _snaps : Label = get_node("StatisticsVBox/TimesRodSnappedHBox/ValueLabel")
@onready var _total_trials : Label = get_node("StatisticsVBox/TotalTrialsHBox/ValueLabel")
@onready var _completed_trials : Label = get_node("StatisticsVBox/CompletedTrialsHBox/ValueLabel")


func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		_total_time.text = str(StatisticsManager.user_statistics.get_total_play_time(), " s")
		_current_time.text = str(StatisticsManager.user_statistics.get_current_play_time(), " s")
		var fishing_statistics: FishingStatistics = StatisticsManager.user_statistics.get_current_fishing_statistics()
		_total_fishing_sessions.text = str(fishing_statistics.total_fishing_sessions)
		_fish_caught.text = str(fishing_statistics.fish_caught)
		_snaps.text = str(fishing_statistics.snaps)
		_total_trials.text = str(fishing_statistics.total_trials)
		_completed_trials.text = str(fishing_statistics.completed_trials)
