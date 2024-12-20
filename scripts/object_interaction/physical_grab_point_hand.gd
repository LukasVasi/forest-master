@tool
class_name PhysicalGrabPointHand
extends XRToolsGrabPointHand

## Extends the XRToolsGrabPointHand class to allow use of PhysicalHand 
## for grabbing

# Get the controller associated with a grabber
static func _get_grabber_controller(grabber : Node3D) -> XRController3D:
	# Ensure the grabber is valid
	if not is_instance_valid(grabber):
		return null

	# Ensure the pickup is a physical hand
	var pickup := grabber as PhysicalHand
	if not pickup:
		return null

	# Get the controller associated with the hand
	return pickup.get_controller()
