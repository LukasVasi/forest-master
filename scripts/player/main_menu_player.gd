extends Player

func _ready() -> void:
	init_controllers()


func init_controllers() -> void:
	# Initialise the right controller and its children
	xr_controller_right = XRHelpers.get_right_controller(self)
	if not xr_controller_right:
		push_error("Right controller could not be found.")
	else:
		xr_controller_right.button_pressed.connect(_on_right_controller_button_pressed)
		xr_controller_right.button_released.connect(_on_right_controller_button_released)
		movement_turn_right = XRTools.find_xr_child(xr_controller_right, "*", "XRToolsMovementTurn", true)
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
