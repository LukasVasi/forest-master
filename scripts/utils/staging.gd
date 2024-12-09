@tool
class_name Staging
extends Node3D


## XR Tools Staging Class
##
## When creating a game with multiple levels where you want to
## make use of background loading and have some nice structure
## in place, the Staging scene can be used as a base to handle
## all the startup and scene switching code.
## Just inherit this scene, set it up and make the resulting
## scene your startup scene.
##
## As different XR runtimes need slightly different setups you'll
## need to add the appropriate ARVROrigin setup to your scene.
## When using the OpenXR plugin this is as simple as adding the
## FPController script as a child node.
##
## Furthermore this scene has our loading screen and an anchor
## point into which we load the actual scene we wish the user
## to interact with. You can configure the first scene to load
## and kick off your game by setting the Main Scene property.
##
## If you are creating a game with a single level you may wish to
## simplify things. Check out the demo included in the source
## repository for the OpenXR plugin and then use the techniques
## explained in individual demos found here.


## This signal is emitted when the current scene starts to be unloaded. The
## [param scene] parameter is the path of the current scene, and the
## [param user_data] parameter is the optional data passed from the
## current scene to the next.
signal scene_exiting(scene, user_data)

## This signal is emitted when the old scene has been unloaded and the user
## is fading into the loading scene. The [param user_data] parameter is the
## optional data provided by the old scene.
signal switching_to_loading_scene(user_data)

## This signal is emitted when the new scene has been loaded before it becomes
## visible. The [param scene] parameter is the path of the new scene, and the
## [param user_data] parameter is the optional data passed from the old scene
## to the new scene.
signal scene_loaded(scene, user_data)

## This signal is emitted when the new scene has become fully visible to the
## player. The [param scene] parameter is the path of the new scene, and the
## [param user_data] parameter is the optional data passed from the old scene
## to the new scene.
signal scene_visible(scene, user_data)

## This signal is invoked when the XR experience starts.
signal xr_started

## This signal is invoked when the XR experience ends. This usually occurs when
## the player removes the headset. The game may want to react by pausing until
## the player puts the headset back on and the [signal xr_started] signal is
## emitted.
signal xr_ended


## Main scene file
@export_file('*.tscn') var main_menu_scene : String

## If true, the player is prompted to continue
@export var prompt_for_continue : bool = true


## The current scene
var current_scene : SceneBase

## The current scene path
var current_scene_path : String

var xr_interface : XRInterface

# Tween for fading
var _tween : Tween

## The [XROrigin3D] node used while staging
@onready var xr_origin : XROrigin3D = XRHelpers.get_xr_origin(self)

## The [XRCamera3D] node used while staging
@onready var xr_camera : XRCamera3D = XRHelpers.get_xr_camera(self)


func _ready() -> void:
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return
	
	# Specify the camera to track
	if xr_camera:
		$LoadingScreen.set_camera(xr_camera)
	
	# Start loading the main menu scene
	load_scene(main_menu_scene)


# Verifies our staging has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Report missing XR Origin
	var test_origin : XROrigin3D = XRHelpers.get_xr_origin(self)
	if !test_origin:
		warnings.append("No XROrigin3D node found, please add one")

	# Report missing XR Camera
	var test_camera : XRCamera3D = XRHelpers.get_xr_camera(self)
	if !test_camera:
		warnings.append("No XRCamera3D node found, please add one to your XROrigin3D node")

	# Report main scene not specified
	if main_menu_scene == "":
		warnings.append("No main scene selected")

	# Report main scene invalid
	if !FileAccess.file_exists(main_menu_scene):
		warnings.append("Main scene doesn't exist")

	# Return warnings
	return warnings


func _notification(what: int) -> void:
	# Mark close requests to be handled explicitly
	if (
		what == NOTIFICATION_WM_CLOSE_REQUEST or
		what == NOTIFICATION_APPLICATION_PAUSED
	):
		if is_instance_valid(current_scene):
			current_scene.handle_close_request()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsStaging"


## This function loads the [param p_scene_path] scene file.
##
## The [param user_data] parameter contains optional data passed from the old
## scene to the new scene.
##
## See [method XRToolsSceneBase.scene_loaded] for details on how to implement
## advanced scene-switching.
func load_scene(p_scene_path : String, user_data = null) -> void:
	# Do not load if in the editor
	if Engine.is_editor_hint():
		return

	if !xr_origin:
		return

	if !xr_camera:
		return

	# Start the threaded loading of the scene. If the scene is already cached
	# then this will finish immediately with THREAD_LOAD_LOADED
	ResourceLoader.load_threaded_request(p_scene_path)

	# If a current scene is visible then fade it out and unload it.
	if current_scene:
		# Report pre-exiting and remove the scene signals
		current_scene.scene_pre_exiting(user_data)
		_remove_signals(current_scene)

		# Fade to black
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_method(set_fade, 0.0, 1.0, 1.0)
		await _tween.finished

		# Now we remove our scene
		emit_signal("scene_exiting", current_scene, user_data)
		current_scene.scene_exiting(user_data)
		$Scene.remove_child(current_scene)
		current_scene.queue_free()
		current_scene = null
		PauseManager.paused = false # make sure we unpause

	# If a continue-prompt is desired or the new scene has not finished
	# loading, then switch to the loading screen.
	if prompt_for_continue or \
		ResourceLoader.load_threaded_get_status(p_scene_path) != ResourceLoader.THREAD_LOAD_LOADED:

		# Make our loading screen visible again and reset some stuff
		xr_origin.set_process_internal(true)
		xr_origin.current = true
		xr_camera.current = true
		$LoadingScreen.progress = 0.0
		$LoadingScreen.enable_press_to_continue = false
		$LoadingScreen.follow_camera = true
		$LoadingScreen.visible = true
		switching_to_loading_scene.emit(user_data)

		# Fade to visible
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_method(set_fade, 1.0, 0.0, 1.0)
		await _tween.finished

	# If the loading screen is visible then show the progress and optionally
	# wait for the continue. Once done fade out the loading screen.
	if $LoadingScreen.visible:
		# Loop waiting for the scene to load
		var res : ResourceLoader.ThreadLoadStatus
		while true:
			var progress := []
			res = ResourceLoader.load_threaded_get_status(p_scene_path, progress)
			if res != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break;

			$LoadingScreen.progress = progress[0]
			await get_tree().create_timer(0.1).timeout

		# Handle load error
		if res != ResourceLoader.THREAD_LOAD_LOADED:
			# Report the error to the log and console
			push_error("Error ", res, " loading resource ", p_scene_path)

			# Halt if running in the debugger
			# gdlint:ignore=expression-not-assigned
			breakpoint

			# Terminate with a non-zero error code to indicate failure
			get_tree().quit(1)

		# Wait for user to be ready
		if prompt_for_continue:
			$LoadingScreen.enable_press_to_continue = true
			await $LoadingScreen.continue_pressed

		# Fade to black
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_method(set_fade, 0.0, 1.0, 1.0)
		await _tween.finished

		# Hide our loading screen
		$LoadingScreen.follow_camera = false
		$LoadingScreen.visible = false
		xr_origin.set_process_internal(false)

	# Get the loaded scene
	var new_scene : PackedScene = ResourceLoader.load_threaded_get(p_scene_path)

	# Setup our new scene
	current_scene = new_scene.instantiate()
	current_scene_path = p_scene_path
	$Scene.add_child(current_scene)
	_add_signals(current_scene)

	# We create a small delay here to give tracking some time to update our nodes...
	await get_tree().create_timer(0.1).timeout
	current_scene.scene_loaded(user_data)
	scene_loaded.emit(current_scene, user_data)

	# Fade to visible
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_method(set_fade, 1.0, 0.0, 1.0)
	await _tween.finished

	# Report new scene visible
	current_scene.scene_visible(user_data)
	scene_visible.emit(current_scene, user_data)


## This method sets the fade-alpha for scene transitions. The [param p_value]
## parameter must be in the range [0.0 - 1.0].
##
## Our fade object allows us to black out the screen for transitions.
## Note that our AABB is set to HUGE so it should always be rendered
## unless hidden.
func set_fade(p_value : float) -> void:
	XRToolsFade.set_fade("staging", Color(0, 0, 0, p_value))


func _add_signals(p_scene : SceneBase) -> void:
	p_scene.request_exit_to_main_menu.connect(_on_exit_to_main_menu)
	p_scene.request_load_scene.connect(_on_load_scene)
	p_scene.request_reset_scene.connect(_on_reset_scene)


func _remove_signals(p_scene : SceneBase) -> void:
	p_scene.request_exit_to_main_menu.disconnect(_on_exit_to_main_menu)
	p_scene.request_load_scene.disconnect(_on_load_scene)
	p_scene.request_reset_scene.disconnect(_on_reset_scene)


func _on_exit_to_main_menu() -> void:
	print("This called")
	load_scene(main_menu_scene)


func _on_load_scene(p_scene_path : String, user_data) -> void:
	load_scene(p_scene_path, user_data)


func _on_reset_scene(user_data) -> void:
	load_scene(current_scene_path, user_data)


func _on_StartXR_xr_started() -> void:
	xr_started.emit()


func _on_StartXR_xr_ended() -> void:
	xr_ended.emit()
