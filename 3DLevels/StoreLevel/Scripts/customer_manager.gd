class_name CustomerManager
extends Node3D

## Spawns a customer every few seconds while there's a free counter spot.
##
## Children it expects (same idea as Shelf and its "Slots"):
##   Entrance      Marker3D   where customers appear
##   Exit          Marker3D   where they walk off to
##   CounterSpots  Node3D     one Marker3D per spot, placed where the PC sits on the counter

@export var customer_scene: PackedScene
@export var computer_scene: PackedScene
## Optional hand-made jobs. Leave EMPTY to get random jobs from JobGenerator.
@export var jobs: Array[RepairJob] = []
## Chance (0..1) that a random job is a software job instead of a hardware one.
@export_range(0.0, 1.0) var software_chance: float = 0.3
@export var spawn_interval: float = 12.0
## Where the customer stands, in each counter spot's local space.
@export var stand_offset: Vector3 = Vector3(0, 0, 1.5)

@onready var spots_root: Node = $CounterSpots
@onready var entrance: Marker3D = $Entrance
@onready var exit_point: Marker3D = $Exit

var _taken: Dictionary = {}   # Marker3D -> Customer

func _ready() -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_try_spawn)
	add_child(timer)
	# Deferred so the shelves have filled themselves before we look at them.
	_try_spawn.call_deferred()

func _free_spot() -> Marker3D:
	for node in spots_root.get_children():
		var s: Marker3D = node as Marker3D
		if s != null and not _taken.has(s):
			return s
	return null

## Hand-made job if you set any, otherwise a random software or hardware job.
## Hardware jobs are based on a part that's on a shelf right now; if the shelves
## are empty it falls back to a software job.
func _make_job() -> RepairJob:
	if not jobs.is_empty():
		var picked: RepairJob = jobs.pick_random()
		return picked

	if randf() < software_chance:
		return JobGenerator.make_software()

	var stocked: Array[Part] = _shelf_parts()
	if stocked.is_empty():
		return JobGenerator.make_software()
	var p: Part = stocked.pick_random()
	return JobGenerator.make(p)

## Every part currently sitting in a shelf/bench slot (slots that accept anything).
func _shelf_parts() -> Array[Part]:
	var found: Array[Part] = []
	for node in get_tree().get_nodes_in_group("slots"):
		var s: Slot = node as Slot
		if s != null and s.accepts_socket == &"" and s.part != null:
			found.append(s.part)
	return found

func _try_spawn() -> void:
	if customer_scene == null or computer_scene == null:
		return
	var spot: Marker3D = _free_spot()
	if spot == null:
		return
	var job: RepairJob = _make_job()
	if job == null:
		return

	var c: Customer = customer_scene.instantiate() as Customer
	if c == null:
		push_warning("CustomerManager: customer_scene root doesn't have customer.gd")
		return
	add_child(c)
	c.spot = spot
	_taken[spot] = c
	c.arrived.connect(_on_arrived)
	c.timed_out.connect(_on_timed_out)
	c.left.connect(_on_left)

	c.start(job, entrance.global_position, spot.to_global(stand_offset), exit_point.global_position)

func _on_arrived(c: Customer) -> void:
	var comp: Computer = computer_scene.instantiate() as Computer
	if comp == null:
		push_warning("CustomerManager: computer_scene root doesn't have computer.gd")
		return
	c.spot.add_child(comp)
	comp.job = c.job
	comp.customer = c
	c.computer = comp

func _on_timed_out(c: Customer) -> void:
	GameState.fail_job(c.job)
	c.leave(false)

func _on_left(c: Customer) -> void:
	_taken.erase(c.spot)