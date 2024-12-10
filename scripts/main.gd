@tool
class_name MainScene
extends SceneBase


func _ready() -> void:
	# Start the session once loaded into the main scene
	StatisticsManager.user_statistics.start_session()


# Override the close request method to save the session.
func handle_close_request() -> void:
	StatisticsManager.save()
