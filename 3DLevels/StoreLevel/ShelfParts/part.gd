class_name Part
extends Node3D

@export var data: PartData:
	set(v):
		data = v
		if is_node_ready(): _apply()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready(): _apply()
func _apply():
	if data: mesh_instance.mesh = data.mesh