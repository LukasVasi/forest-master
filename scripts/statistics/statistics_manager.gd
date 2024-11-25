extends Node

const STATISTICS_FILE_NAME : String = "user://user_statistics.tres"

var user_statistics : UserStatistics = UserStatistics.new()

func _ready() -> void:
	_load()
	user_statistics.start_session()


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
