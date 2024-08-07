class_name Bow
extends XRToolsPickable

@onready var bow_skeleton : Skeleton3D = $bow/Armature/Skeleton3D
@onready var pull_pick = $PullPivot/HandleOrigin/PullPick
@onready var pull_pick_org_pos = $PullPivot/HandleOrigin.transform.origin
@onready var pull_pick_colision = $PullPivot/HandleOrigin/PullPick/CollisionShape3D
@onready var pull_pivot = $PullPivot
@onready var pull_pivot_org_position = $PullPivot.transform.origin
@onready var arrow_snap_zone : XRToolsSnapZone = $PullPivot/ArrowSnapZone
# Called when the node enters the scene tree for the first time.
const fire_factor = 85

func _ready():
	super()
	set_process(false)
	
func _process(delta):
	if pull_pick.is_picked_up():
		var curr_pull_pivot_position = pull_pivot.transform.origin
		var pull_position = pull_pick.global_transform.origin * global_transform
		
		#move our pull pivot along the x axis
		pull_pivot.transform.origin.x = clamp(pull_position.x,pull_pivot_org_position.x,0.5)
		
		#adjust our bones
		var pulled_back = pull_pivot.transform.origin.x - pull_pivot_org_position.x
		var pose_transform : Transform3D = Transform3D()
		pose_transform.origin.y = pulled_back * 20.0
		bow_skeleton.set_bone_pose_position(1,Vector3(0,-1*pose_transform.origin.y,0))
		#adjust our pull pick location by the movement we just added to pull pivot
		pull_pick.transform.origin = curr_pull_pivot_position - pull_position

func _on_Bow_picked_up(_pickable):
	#Enable our PullPick
	print("Paimtas lankas")
	pull_pick.enabled=true
	arrow_snap_zone.enabled = true
	pull_pick.freeze=false
	
func _on_Bow_dropped(_pickable):
	pull_pick.freeze=true
	if pull_pick.is_picked_up():
		pull_pick.let_go(pull_pick,Vector3(),Vector3())
	pull_pick.enabled=false
	arrow_snap_zone.enabled = false

func _on_pull_pick_picked_up(_pickable):
	print("paimta virve")
	pull_pick.freeze=false
	pull_pick.transform.origin = pull_pick_org_pos
	pull_pick_colision.transform.origin = pull_pick_org_pos
	_pickable.transform.origin = pull_pick_org_pos
	set_process(true)


func _on_pull_pick_dropped(_pickable):
	pull_pick.freeze=false
	set_process(false)
	print("paleista virve")
	#move back to start position, and re-enable our collision layer
	pull_pick_colision.transform = Transform3D()
	pull_pick.freeze=true
	bow_skeleton.set_bone_pose_position(1,Vector3(-1,0,0))
	pull_pick.freeze=false
	#fire our arrow
	
	var arrow : RigidBody3D = arrow_snap_zone.picked_up_object
	if arrow:
		var pulled_back = pull_pivot.transform.origin.x - pull_pivot_org_position.x
		
		#drop our arrow
		arrow_snap_zone.drop_object()
		
		#give it a linear velocity
		arrow.linear_velocity = transform.basis * Vector3(-1*pulled_back,0.0,0.0) * fire_factor
		$PullPivot/ArrowSnapZone/Timer.start()
		
	#move our pivot back
	pull_pivot.transform.origin = pull_pivot_org_position
	bow_skeleton.set_bone_pose_position(1,Vector3(0,-1,0))

func _on_arrow_snap_zone_has_picked_up(what):
	arrow_snap_zone.enabled = false
	what.collision_layer=0
	pass # Replace with function body.


func _on_ArrowSnapZome_timer_timeout():
	arrow_snap_zone.enabled = is_picked_up()
