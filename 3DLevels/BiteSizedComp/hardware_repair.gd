extends Node3D

## 3D hardware repair. Replaces the old repair_scene.gd (delete that file, or
## rename it and paste this in, so there's no leftover "class_name RepairScene").
## Your part floats in, E tries to install it, Esc backs out.
## The real hardware puzzle goes in here later.
##
## Scene tree:
##   HardwareRepair (Node3D)   <- this script
##   ├── Camera3D              (Current on)
##   ├── DirectionalLight3D
##   ├── Board                 the motherboard / PC mesh
##   ├── PartHover             Marker3D, where the part floats before installing
##   ├── Socket                Marker3D, where the part ends up when installed
##   └── UI (CanvasLayer)
##       ├── Job (Label)
##       └── Message (Label)

signal finished(success: bool, part: Part)

@onready var part_hover: Marker3D = $PartHover
@onready var socket: Marker3D = $Socket
@onready var job_label: Label = $UI/Job
@onready var message: Label = $UI/Message

var job: RepairJob
var part: Part
var _done: bool = false

## Call after add_child().
func setup(j: RepairJob, p: Part) -> void:
	job = j
	part = p
	job_label.text = "%s: %s" % [j.customer_name, j.request]
	message.text = "E: install    Esc: back out"
	part_hover.add_child(p)
	p.transform = Transform3D.IDENTITY

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_try_install()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_done = true
		finished.emit(false, part)

func _try_install() -> void:
	if not job.accepts(part):
		message.text = "The %s doesn't fit this machine." % part.display_name
		return
	_done = true
	part.reparent(socket, false)
	part.transform = Transform3D.IDENTITY
	message.text = "Fixed!"
	await get_tree().create_timer(0.8).timeout
	finished.emit(true, part)
