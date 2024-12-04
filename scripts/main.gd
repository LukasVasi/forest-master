@tool
class_name MainScene
extends SceneBase


# Override the close request method to save the session.
func handle_close_request() -> void:
	StatisticsManager.save()
