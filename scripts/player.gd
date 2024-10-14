class_name Player
extends XROrigin3D

var xr_interface: XRInterface

# Right controller variables
var xr_controller_right: XRController3D
var movement_turn_right: XRToolsMovementTurn
var function_pickup_right: PhysicalFunctionPickup
var function_pointer_right: XRToolsFunctionPointer

# Left controller variables
var xr_controller_left: XRController3D
var movement_jump_left: XRToolsMovementJump
var movement_direct_left: XRToolsMovementDirect
var function_teleport_left: XRToolsFunctionTeleport
var function_pickup_left: PhysicalFunctionPickup
var function_pointer_left: XRToolsFunctionPointer
var function_pointer_collision_left: CollisionShape3D


func _ready() -> void:
	init_xr_interface()
	init_controllers()
	
	if PauseManager:
		PauseManager.pause_state_changed.connect(_on_pause_state_changed)


func init_xr_interface() -> void:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR failed to initialize, please check if your headset is connected")


func init_controllers() -> void:
	# Initialise the right controller and its children
	xr_controller_right = XRHelpers.get_right_controller(self)
	if not xr_controller_right:
		push_error("Right controller could not be found.")
	else:
		xr_controller_right.button_pressed.connect(_on_right_controller_button_pressed)
		xr_controller_right.button_released.connect(_on_right_controller_button_released)
		movement_turn_right = XRTools.find_xr_child(xr_controller_right, "*", "XRToolsMovementTurn", true)
		function_pickup_right = xr_controller_right.get_node("RightPhysicsHand/FunctionPickupRight")
		function_pointer_right = XRTools.find_xr_child(xr_controller_right, "*", "XRToolsFunctionPointer", true)
		
		if not function_pointer_right:
			push_error("The right function pointer was not found")
		else:
			disable_right_pointer()
	
	# Initialise the left controller and its children
	xr_controller_left = XRHelpers.get_left_controller(self)
	if not xr_controller_left:
		push_error("Left controller could not be found.")
	else:
		xr_controller_left.button_pressed.connect(_on_left_controller_button_pressed)
		xr_controller_left.button_released.connect(_on_left_controller_button_released)
		
		movement_jump_left = XRTools.find_xr_child(xr_controller_left, "*", "XRToolsMovementJump", true)
		movement_direct_left = XRTools.find_xr_child(xr_controller_left, "*", "XRToolsMovementDirect", true)
		function_teleport_left = XRTools.find_xr_child(xr_controller_left, "*", "XRToolsFunctionTeleport", true)
		
		# Enable one based on user settings
		if XRToolsUserSettings.movement_direct:
			movement_direct_left.enabled = true
			function_teleport_left.enabled = false
		else:
			movement_direct_left.enabled = false
			function_teleport_left.enabled = true
		
		function_pickup_left = xr_controller_left.get_node("LeftPhysicsHand/FunctionPickupLeft")
		function_pointer_left = XRTools.find_xr_child(xr_controller_left, "*", "XRToolsFunctionPointer", true)
		
		if not function_pointer_left:
			push_error("The left function pointer was not found")
		else:
			disable_left_pointer()


func enable_right_pointer() -> void:
	function_pointer_right.set_enabled(true)
	function_pointer_right.set_show_laser(XRToolsFunctionPointer.LaserShow.SHOW)
	#function_pickup_right.ranged_enable = true


func disable_right_pointer() -> void:
	function_pointer_right.set_enabled(false)
	function_pointer_right.set_show_laser(XRToolsFunctionPointer.LaserShow.HIDE)
	#function_pickup_right.ranged_enable = false
	
	
func enable_left_pointer() -> void:
	function_pointer_left.set_enabled(true)
	function_pointer_left.set_show_laser(XRToolsFunctionPointer.LaserShow.SHOW)
	#function_pickup_left.ranged_enable = true


func disable_left_pointer() -> void:
	function_pointer_left.set_enabled(false)
	function_pointer_left.set_show_laser(XRToolsFunctionPointer.LaserShow.HIDE)
	#function_pickup_left.ranged_enable = false
	
	
## Controller input handling
## All methods handling input signals should be here
## Internal functionality should be realised in other methods
## External functionality should use emitted signals
## Avoid writing logic directlly into the handling

func _on_right_controller_button_pressed(p_button: String) -> void:
	#print(p_button + " was pressed on the right controller")	
	match p_button:
		"ax_button":
			enable_right_pointer()


func _on_right_controller_button_released(p_button: String) -> void:
	#print(p_button + " was released on the right controller")
	match p_button:
		"ax_button":
			disable_right_pointer()


func _on_left_controller_button_pressed(p_button: String) -> void:
	#print(p_button + " was pressed on the left controller")
	match p_button:
		"ax_button":
			enable_left_pointer()
		"menu_button":
			PauseManager.toggle_pause()


func _on_left_controller_button_released(p_button: String) -> void:
	#print(p_button + " was released on the left controller")
	match p_button:
		"ax_button":
			disable_left_pointer()


## Methods for using the controller haptic feedback

func trigger_left_haptic(frequency: float, amplitude: float, duration_sec: float, delay_sec: float) -> void:
	xr_controller_left.trigger_haptic_pulse("haptic", frequency, amplitude, duration_sec, delay_sec)
	
func trigger_right_haptic(frequency: float, amplitude: float, duration_sec: float, delay_sec: float) -> void:
	xr_controller_right.trigger_haptic_pulse("haptic", frequency, amplitude, duration_sec, delay_sec)

## Method that handles the pause state change singal from PauseManager
func _on_pause_state_changed(paused : bool) -> void:
	if paused:
		# Disable all movement
		movement_jump_left.enabled = false
		movement_direct_left.enabled = false
		function_teleport_left.enabled = false
	else:
		movement_jump_left.enabled = true
		# Enable one based on user settings
		if XRToolsUserSettings.movement_direct:
			movement_direct_left.enabled = true
		else:
			function_teleport_left.enabled = true
