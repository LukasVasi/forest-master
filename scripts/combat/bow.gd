@tool
class_name Bow
extends XRToolsPickable

const FIRE_FACTOR = 85

@onready var _bow_skeleton : Skeleton3D = $Bow/Armature/Skeleton3D
@onready var _pull_pick: RigidBody3D = $PullPivot/HandleOrigin/PullPick
@onready var _pull_pick_org_pos: Vector3 = _pull_pick.position
@onready var _pull_pick_colision: CollisionShape3D = $PullPivot/HandleOrigin/PullPick/CollisionShape3D
@onready var _pull_pivot: Node3D = $PullPivot
@onready var _pull_pivot_org_position: Vector3 = _pull_pivot.position
@onready var _arrow_snap_zone_timer: Timer = $PullPivot/ArrowSnapZone/Timer
@onready var _arrow_snap_zone : XRToolsSnapZone = $PullPivot/ArrowSnapZone


func _ready() -> void:
	super()
	set_process(false)


func _process(_delta: float) -> void:
	if _pull_pick.is_picked_up():
		var curr_pull_pivot_position: Vector3 = _pull_pivot.position
		var pull_position: Vector3 = _pull_pick.global_position * global_transform
		
		#move our pull pivot along the x axis
		_pull_pivot.position.x = clamp(pull_position.x,_pull_pivot_org_position.x,0.5)
		
		#adjust our bones
		var pulled_back: float = _pull_pivot.position.x - _pull_pivot_org_position.x
		var pose_transform : Transform3D = Transform3D()
		pose_transform.origin.y = pulled_back * 20.0
		_bow_skeleton.set_bone_pose_position(1,Vector3(0,-1*pose_transform.origin.y,0))
		#adjust our pull pick location by the movement we just added to pull pivot
		_pull_pick.position = curr_pull_pivot_position - pull_position


func _on_bow_picked_up(_pickable: Variant) -> void:
	#Enable our PullPick
	_pull_pick.enabled=true
	_arrow_snap_zone.enabled = true
	_pull_pick.freeze=false


func _on_bow_dropped(_pickable: Variant) -> void:
	_pull_pick.freeze=true
	if _pull_pick.is_picked_up():
		_pull_pick.let_go(_pull_pick,Vector3(),Vector3())
	_pull_pick.enabled=false
	_arrow_snap_zone.enabled = false


func _on_pull_pick_picked_up(_pickable: Variant) -> void:
	_pull_pick.freeze=false
	_pull_pick.position = _pull_pick_org_pos
	_pull_pick_colision.position = _pull_pick_org_pos
	_pickable.position = _pull_pick_org_pos
	set_process(true)


func _on_pull_pick_dropped(_pickable: Variant) -> void:
	_pull_pick.freeze=false
	set_process(false)
	#move back to start position, and re-enable our collision layer
	_pull_pick_colision.transform = Transform3D()
	_pull_pick.freeze=true
	_bow_skeleton.set_bone_pose_position(1,Vector3(-1,0,0))
	_pull_pick.freeze=false
	#fire our arrow
	
	var arrow : RigidBody3D = _arrow_snap_zone.picked_up_object
	if arrow:
		var pulled_back: float = _pull_pivot.position.x - _pull_pivot_org_position.x
		
		#drop our arrow
		_arrow_snap_zone.drop_object()
		
		#give it a linear velocity
		arrow.linear_velocity = transform.basis * Vector3(-1 * pulled_back,0.0,0.0) * FIRE_FACTOR
		_arrow_snap_zone_timer.start()
		
	#move our pivot back
	_pull_pivot.position = _pull_pivot_org_position
	_bow_skeleton.set_bone_pose_position(1,Vector3(0,-1,0))


func _on_arrow_snap_zone_has_picked_up(what: Variant) -> void:
	_arrow_snap_zone.enabled = false
	what.collision_layer=0
	pass # Replace with function body.


func _on_arrow_snap_zone_timer_timeout() -> void:
	_arrow_snap_zone.enabled = is_picked_up()
