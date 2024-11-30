@tool
class_name PlayerBody
extends XRToolsPlayerBody

## XRToolsPlayerBody just with additional water related functionality

@export_group("Water physics")

## The acceleration that determines how fast the player reaches the max emergence speed in water.
@export var water_emergence_acceleration : float = 5.0

## The max speed that the player will be raised from the water.
@export var water_max_emergence_velocity : float = 2.0

## The maximum velocity that bobbing in water will reach.
@export var water_bobbing_amplitude : float = 0.2

## The frequency of the bobbing in water.
@export var _water_bobbing_frequency := 0.8


var current_player_height : float : get = _get_player_height


# In water mode
var _in_water : bool = false

# Bobbing in water mode
var _bobbing : bool = false

# The current time of the bobbing oscillation
var _water_bobbing_time : float  = 0.0

# The global height (y coordinate) of the water surface
var _water_global_height : float = 0.0


func _physics_process(delta: float) -> void:
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# If disabled then turn of physics processing and bail out
	if !enabled:
		set_physics_process(false)
		return

	# Calculate the players "up" direction and plane
	up_player = origin_node.global_transform.basis.y

	# Determine environmental gravity
	var gravity_state := PhysicsServer3D.body_get_direct_state(get_rid())
	gravity = gravity_state.total_gravity

	# Update the kinematic body to be under the camera
	_update_body_under_camera(delta)

	# Allow the movement providers a chance to perform pre-movement updates. The providers can:
	# - Adjust the gravity direction
	for p : XRToolsMovementProvider in _movement_providers:
		if p.enabled:
			p.physics_pre_movement(delta, self)

	# Determine the gravity "up" direction and plane
	if gravity.is_equal_approx(Vector3.ZERO):
		# Gravity too weak - use player
		up_gravity = up_player
	else:
		# Use gravity direction
		up_gravity = -gravity.normalized()

	# Update the ground information
	_update_ground_information(delta)

	# Get the player body location before movement occurs
	var position_before_movement := global_transform.origin

	# Run the movement providers in order. The providers can:
	# - Move the kinematic node around (to move the player)
	# - Rotate the XROrigin3D around the camera (to rotate the player)
	# - Read and modify the player velocity
	# - Read and modify the ground-control velocity
	# - Perform exclusive updating of the player (bypassing other movement providers)
	# - Request a jump
	# - Modify gravity direction
	ground_control_velocity = Vector2.ZERO
	var exclusive := false
	for p : XRToolsMovementProvider in _movement_providers:
		if p.is_active or (p.enabled and not exclusive):
			if p.physics_movement(delta, self, exclusive):
				exclusive = true

	# NOTE: this is the changed part
	# If no controller has performed an exclusive-update then apply gravity and
	# perform any ground-control or handle bobbing in water
	if !exclusive:
		if on_ground and ground_physics.stop_on_slope and ground_angle < ground_physics.move_max_slope:
			# Apply gravity towards slope to prevent sliding
			velocity += -ground_vector * gravity.length() * delta
		elif _in_water:
			# If the player is bobbing on the surface
			if _bobbing:
				# Apply velocity to keep them bobbing
				_water_bobbing_time += delta
				velocity.y = _get_bob_velocity(_water_bobbing_time)
			else:
				# If the player has emerged to the surface
				if velocity.y > 0 and global_position.y > _water_global_height - _collision_node.shape.height / 2:
					# Start bobbing
					_bobbing = true
				else:
					# If the player is falling in water, push them upwards but not too much
					velocity.y = min(velocity.y + water_emergence_acceleration * delta, water_max_emergence_velocity)
		else:
			# Apply gravity
			velocity += gravity * delta
		_apply_velocity_and_control(delta)

	# Apply the player-body movement to the XR origin
	var movement := global_transform.origin - position_before_movement
	origin_node.global_transform.origin += movement

	# Orient the player towards (potentially modified) gravity
	slew_up(-gravity.normalized(), 5.0 * delta)


# This method updates the information about the ground under the players feet
# Overriden so that not ground is found if in water.
func _update_ground_information(delta: float) -> void:
	# Test how close we are to the ground
	var ground_collision := move_and_collide(
			up_gravity * -NEAR_GROUND_DISTANCE, true)

	# Handle no collision (or too far away to care about)
	if !ground_collision or _in_water:
		near_ground = false
		on_ground = false
		ground_vector = up_gravity
		ground_angle = 0.0
		ground_node = null
		ground_physics = null
		_previous_ground_node = null
		return

	# Categorize the type of ground contact
	near_ground = true
	on_ground = ground_collision.get_travel().length() <= ON_GROUND_DISTANCE

	# Save the ground information from the collision
	ground_vector = ground_collision.get_normal()
	ground_angle = rad_to_deg(ground_collision.get_angle(0, up_gravity))
	ground_node = ground_collision.get_collider()

	# Select the ground physics
	var physics_node := ground_node.get_node_or_null("GroundPhysics") as XRToolsGroundPhysics
	ground_physics = XRToolsGroundPhysics.get_physics(physics_node, default_physics)

	# Detect if we're sliding on a wall
	# TODO: consider reworking this magic angle
	if ground_angle > 85:
		on_ground = false

	# Detect ground velocity under players feet
	if _previous_ground_node == ground_node:
		var pos_old := _previous_ground_global
		var pos_new := ground_node.to_global(_previous_ground_local)
		ground_velocity = (pos_new - pos_old) / delta

	# Update ground velocity information
	_previous_ground_node = ground_node
	_previous_ground_global = ground_collision.get_position()
	_previous_ground_local = ground_node.to_local(_previous_ground_global)


# This method applies the player velocity and ground-control velocity to the physical body
func _apply_velocity_and_control(delta: float) -> void:
	# Calculate local velocity
	var local_velocity := velocity - ground_velocity

	# Split the velocity into horizontal and vertical components
	var horizontal_velocity := local_velocity.slide(up_gravity)
	var vertical_velocity := local_velocity - horizontal_velocity

	# NOTE: this if is changed
	# If the player is on the ground or in water then give them control
	if (_can_apply_ground_control() or _in_water) and ground_control_velocity.length() >= 0.1:
		# If ground control is being supplied then update the horizontal velocity
		var control_velocity := Vector3.ZERO
		var camera_transform := camera_node.global_transform
		var dir_forward := camera_transform.basis.z.slide(up_gravity).normalized()
		var dir_right := camera_transform.basis.x.slide(up_gravity).normalized()
		control_velocity = (
				dir_forward * -ground_control_velocity.y +
				dir_right * ground_control_velocity.x
		) * XRServer.world_scale

		# Apply control velocity to horizontal velocity based on traction
		var current_traction := XRToolsGroundPhysicsSettings.get_move_traction(
				ground_physics, default_physics)
		var traction_factor: float = clamp(current_traction * delta, 0.0, 1.0)
		horizontal_velocity = horizontal_velocity.lerp(control_velocity, traction_factor)

	# Prevent the player from moving up steep slopes
	if on_ground:
		var current_max_slope := XRToolsGroundPhysicsSettings.get_move_max_slope(
				ground_physics, default_physics)
		if ground_angle > current_max_slope:
			# Get a vector in the down-hill direction
			var down_direction := ground_vector.slide(up_gravity).normalized()
			var vdot: float = down_direction.dot(horizontal_velocity)
			if vdot < 0:
				horizontal_velocity -= down_direction * vdot

	# Combine the velocities back to a 3-space velocity
	local_velocity = horizontal_velocity + vertical_velocity

	# Move the player body with the desired velocity
	velocity = move_body(local_velocity + ground_velocity)

	# Apply ground-friction after the move
	if _can_apply_ground_control() and ground_control_velocity.length() < 0.1:
		# User is not trying to move, so apply the ground drag
		var current_drag := XRToolsGroundPhysicsSettings.get_move_drag(
				ground_physics, default_physics)
		var drag_factor: float = clamp(current_drag * delta, 0, 1)

		# Apply drag to horizontal velocity relative to ground
		local_velocity = velocity - ground_velocity
		horizontal_velocity = local_velocity.slide(up_gravity)
		vertical_velocity = local_velocity - horizontal_velocity
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, drag_factor)
		velocity = horizontal_velocity + vertical_velocity + ground_velocity

	# Perform bounce test if a collision occurred
	if get_slide_collision_count():
		# Get the collider the player collided with
		var collision := get_slide_collision(0)
		var collision_node := collision.get_collider()

		# Check for a GroundPhysics node attached to the collider
		var collision_physics_node := \
				collision_node.get_node_or_null("GroundPhysics") as XRToolsGroundPhysics

		# Get the collision physics associated with the collider
		var collision_physics := XRToolsGroundPhysics.get_physics(
				collision_physics_node, default_physics)

		# Get the bounce parameters associated with the collider
		var bounce_threshold := XRToolsGroundPhysicsSettings.get_bounce_threshold(
				collision_physics, default_physics)
		var bounciness := XRToolsGroundPhysicsSettings.get_bounciness(
				collision_physics, default_physics)
		var magnitude := -collision.get_normal().dot(local_velocity)

		# Detect if bounce should be performed
		if bounciness > 0.0 and magnitude >= bounce_threshold:
			local_velocity += 2 * collision.get_normal() * magnitude * bounciness
			velocity = local_velocity + ground_velocity
			emit_signal("player_bounced", collision_node, magnitude)


func on_water_entered(water_height: float) -> void:
	_water_global_height = water_height # set the water height for floating logic
	_in_water = true
	#gravity_scale = 0  # This will make the player ignore gravity

func on_water_exited() -> void:
	_in_water = false
	_bobbing = false
	_water_bobbing_time = 0.0
	#gravity_scale = 1  # Reset gravity scaling
	#linear_velocity.y = 0  # Reset vertical velocity
	#bobbing_time = 0  # Reset bobbing time

func _get_bob_velocity(time: float) -> float:
	var omega := TAU * _water_bobbing_frequency
	# Calculate the velocity as the derivative of the sine function
	var bob_velocity := water_bobbing_amplitude * omega * cos(omega * time)

	return bob_velocity


func _get_player_height() -> float:
	return _collision_node.shape.height if is_instance_valid(_collision_node) else 0.0
