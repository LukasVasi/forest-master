class_name CreatureHitbox
extends StaticBody3D

signal hit_by_arrow

func on_hit_by_arrow():
	hit_by_arrow.emit()
