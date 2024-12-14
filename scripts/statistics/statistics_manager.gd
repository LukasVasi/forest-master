extends Node

const STATISTICS_FILE_NAME : String = "user://user_statistics.tres"

var user_statistics : UserStatistics = UserStatistics.new()

#region Activity sessions

var _archery_session : ArcherySession

#endregion

func _ready() -> void:
	_load()


## Load the user statistics from file.
func _load() -> void:
	# Exit early if no statistics file is found
	if !FileAccess.file_exists(STATISTICS_FILE_NAME):
		return
	
	# Attempt to load the statistics resource
	var saved_user_statistics: UserStatistics = ResourceLoader.load(STATISTICS_FILE_NAME, "UserStatistics")
	if is_instance_valid(saved_user_statistics):
		user_statistics = saved_user_statistics


## Save the user statistics to file.
func save() -> void:
	user_statistics.end_session()
	ResourceSaver.save(user_statistics, STATISTICS_FILE_NAME)


func first_time_playing() -> bool:
	return not user_statistics.has_previous_session()


#region Archery

func start_archery_session() -> void:
	_archery_session = ArcherySession.new()


func end_archery_session() -> void:
	if is_instance_valid(_archery_session):
		user_statistics.add_archery_session(
			_archery_session.shots,
			_archery_session.hits,
			_archery_session.friendly_fire
			)


func report_archery_shot() -> void:
	if not is_instance_valid(_archery_session): _archery_session = ArcherySession.new()
	_archery_session.shots += 1


func report_archery_hit() -> void:
	if not is_instance_valid(_archery_session): _archery_session = ArcherySession.new()
	_archery_session.hits += 1


func report_archery_friendly_fire() -> void:
	if not is_instance_valid(_archery_session): _archery_session = ArcherySession.new()
	_archery_session.friendly_fire += 1


class ArcherySession:
	var shots : int = 0
	var hits : int = 0
	var friendly_fire : int = 0

#endregion
