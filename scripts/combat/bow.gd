@tool
class_name Bow
extends PhysicalPickable

const FIRE_FACTOR = 100

@onready var _bow_skeleton : Skeleton3D = get_node("Bow/Armature/Skeleton3D")

@onready var _pull_pivot: Node3D = get_node("PullPivot")
@onready var _pull_pivot_org_position: Vector3 = _pull_pivot.position

@onready var _pull_pick: PhysicalInteractableHandle = _pull_pivot.get_node("HandleOrigin/PullPick")
@onready var _pull_pick_org_pos: Vector3 = _pull_pick.position
@onready var _pull_pick_colision: CollisionShape3D = _pull_pick.get_node("CollisionShape3D")

@onready var _arrow_snap_zone : PhysicalSnapZone = _pull_pivot.get_node("ArrowSnapZone")

func _ready() -> void:
	super()
	
	# Make sure the pull pick is disabled
	_pull_pick.enabled = false
	
	# Make sure the snap zone is disable
	_arrow_snap_zone.enabled = false
	
	# Disable processing until picked up
	set_process(false)


func _process(_delta: float) -> void:
	if _pull_pick.is_picked_up():
		var pull_position: Vector3 = _pull_pick.global_position * global_transform
		
		# Move our pull pivot (the snap zone and handle origin) along the z axis
		_pull_pivot.position.z = clamp(pull_position.z, _pull_pivot_org_position.z, 0.5)
		
		# Adjust our bone poses
		var pulled_back: float = _pull_pivot.position.z - _pull_pivot_org_position.z
		var pose_transform : Transform3D = Transform3D()
		pose_transform.origin.y = pulled_back * 20.0
		_bow_skeleton.set_bone_pose_position(1, Vector3(0, -1 * pose_transform.origin.y, 0))


func _on_bow_picked_up(_pickable: Variant) -> void:
	StatisticsManager.start_archery_session()
	# Enable our pull pick and arrow snap zone
	_pull_pick.enabled=true
	_arrow_snap_zone.enabled = true


func _on_bow_dropped(_pickable: Variant) -> void:
	StatisticsManager.end_archery_session()
	if _pull_pick.is_picked_up():
		_pull_pick.drop()
	_pull_pick.enabled=false
	_arrow_snap_zone.enabled = false


func _on_pull_pick_picked_up(_pickable: Variant) -> void:
	_pull_pick.position = _pull_pick_org_pos
	_pull_pick_colision.position = _pull_pick_org_pos
	_pickable.position = _pull_pick_org_pos
	set_process(true)


func _on_pull_pick_dropped(_pickable: Variant) -> void:
	set_process(false)
	_bow_skeleton.set_bone_pose_position(1, Vector3(0, -1.638, 0))
	
	# Fire our arrow
	var arrow : PhysicalPickable = _arrow_snap_zone.picked_up_object
	if is_instance_valid(arrow):
		var pulled_back: float = _pull_pivot.position.z - _pull_pivot_org_position.z
		
		# Drop our arrow
		_arrow_snap_zone.drop_object()
		
		# Give it a linear velocity
		arrow.linear_velocity = transform.basis * Vector3(0.0, 0.0, -1 * pulled_back) * FIRE_FACTOR
		
		StatisticsManager.report_archery_shot()
		
	# Move our pivot back
	_pull_pivot.position = _pull_pivot_org_position
	_bow_skeleton.set_bone_pose_position(1, Vector3(0,-1,0))
	
	# Reenable the snap zone
	_arrow_snap_zone.enabled = true


func _on_arrow_snap_zone_has_picked_up(what: Variant) -> void:
	_arrow_snap_zone.enabled = false
