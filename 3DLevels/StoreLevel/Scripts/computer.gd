class_name Computer
extends Node3D

## The customer's PC sitting on the counter. The player presses E on it while
## holding a part. CustomerManager fills in job and customer when it spawns.

var job: RepairJob
# Left untyped on purpose: Customer already refers to Computer, and two
# classes that type each other can upset GDScript.
var customer = null

func _ready() -> void:
	add_to_group("computers")