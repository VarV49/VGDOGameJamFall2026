class_name Customer
extends Node3D

## Walks in, waits with a speech bubble, leaves happy or angry.
## Scene: Node3D (this script) + a mesh + a Label3D named "Bubble" (Billboard on).

signal arrived(customer: Customer)
signal timed_out(customer: Customer)
signal left(customer: Customer)

var job: RepairJob
var computer: Computer = null
var spot: Marker3D = null          # set by CustomerManager
var patience_left: float = 0.0

var _waiting: bool = false
var _exit_pos: Vector3 = Vector3.ZERO

@onready var bubble: Label3D = $Label3D

## Call after add_child().
func start(j: RepairJob, entrance_pos: Vector3, stand_pos: Vector3, exit_pos: Vector3) -> void:
	job = j
	patience_left = j.patience
	_exit_pos = exit_pos
	global_position = entrance_pos
	bubble.text = ""
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", stand_pos, 2.0)
	t.tween_callback(_on_arrived)

func _on_arrived() -> void:
	_waiting = true
	_update_bubble()
	arrived.emit(self)

func _process(delta: float) -> void:
	if not _waiting:
		return
	patience_left -= delta
	_update_bubble()
	if patience_left <= 0.0:
		_waiting = false
		timed_out.emit(self)

## 1.0 = just arrived, 0.0 = about to leave.
func patience_fraction() -> float:
	return clampf(patience_left / maxf(job.patience, 0.01), 0.0, 1.0)

func _update_bubble() -> void:
	bubble.text = "%s\n%s\n%ds" % [job.customer_name, job.request, ceili(patience_left)]

func leave(happy: bool) -> void:
	_waiting = false
	if computer != null:
		computer.queue_free()
		computer = null
	bubble.text = "Thanks!" if happy else "Too slow!"
	left.emit(self)
	var t: Tween = create_tween()
	t.tween_property(self, "global_position", _exit_pos, 2.0)
	t.tween_callback(queue_free)
