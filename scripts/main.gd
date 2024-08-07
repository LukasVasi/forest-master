@tool
class_name MainSceneBase
extends XRToolsSceneBase

## Override of the [XRToolsSceneBase] function with the right path to player origin
func center_player_on(p_transform : Transform3D):
	# In order to center our player so the players feet are at the location
	# indicated by p_transform, and having our player looking in the required
	# direction, we must offset this transform using the cameras transform.

	# So we get our current camera transform in local space
	var camera_transform = $PlayerOrigin/XRCamera3D.transform

	# We obtain our view direction and zero out our height
	var view_direction = camera_transform.basis.z
	view_direction.y = 0

	# Now create the transform that we will use to offset our input with
	var transform : Transform3D
	transform = transform.looking_at(-view_direction, Vector3.UP)
	transform.origin = camera_transform.origin
	transform.origin.y = 0

	# And now update our origin point
	$XROrigin3D.global_transform = (p_transform * transform.inverse()).orthonormalized()


## This method is called when the scene is loaded, but before it becomes visible.
##
## The [param user_data] parameter is an optional parameter passed in when the
## scene is loaded - usually from the previous scene. By default the
## user_data can be a [String] spawn-point node-name, [Vector3], [Transform3D],
## an object with a 'get_spawn_position' method, or null to spawn at the scenes
## [XROrigin3D] location.
##
## Advanced scene-transition functionality can be implemented by overriding this
## method and calling the super() with any desired spawn transform. This could
## come from a field of an advanced user_data class-object, or from a game-state
## singleton.
func scene_loaded(user_data = null):
	# Called after scene is loaded

	# Make sure our camera becomes the current camera
	$XROrigin3D/XRCamera3D.current = true
	$XROrigin3D.current = true

	# Start by assuming the user_data contains spawn position information.
	var spawn_position = user_data

	# If the user_data is an object with a 'get_spawn_position' method then
	# call it (with this [XRToolsSceneBase] allowing it to inspect the scene
	# if necessary) and use the return value as the spawn position information.
	if typeof(user_data) == TYPE_OBJECT and user_data.has_method("get_spawn_position"):
		spawn_position = user_data.get_spawn_position(self)

	# Get the spawn [Transform3D] by inspecting the spawn position value for
	# standard types of spawn position information:
	# - null to use the standard XROrigin3D location
	# - String name of a Node3D to spawn at
	# - Vector3 to spawn at
	# - Transform3D to spawn at
	var spawn_transform : Transform3D = $XROrigin3D.global_transform
	match typeof(spawn_position):
		TYPE_STRING: # Name of Node3D to spawn at
			var node = find_child(spawn_position)
			if node is Node3D:
				spawn_transform = node.global_transform

		TYPE_VECTOR3: # Vector3 to spawn at (rotation comes from XROrigin3D)
			spawn_transform.origin = spawn_position

		TYPE_TRANSFORM3D: # Transform3D spawn location
			spawn_transform = spawn_position

	# Center the player on the spawn location
	center_player_on(spawn_transform)
