extends Node

## Root of the game. Scene tree:
##   Main (Node)           <- this script
##   ├── Shop (Node3D)     <- your whole current level: player, shelves, counter,
##   │                        camera, CustomerManager...
##   └── HUD (CanvasLayer) <- hud.gd
##
## Pressing E on a computer hides + freezes Shop, spawns a repair scene next to
## it, and undoes all that when the repair scene finishes. Shop is never freed,
## so customers, shelves and timers are exactly as you left them.
##
## A repair scene can be anything (3D, 2D, ...) as long as its root has:
##   func setup(job: RepairJob, part: Part)
##   signal finished(success: bool, part: Part)
## part is null for software jobs.

@export var hardware_repair_scene: PackedScene   # 3D, root Node3D
@export var software_repair_scene: PackedScene   # 2D, root Control

@onready var shop: Node3D = $microCENTER

# Untyped on purpose: the root is a Node3D or a Control depending on the job.
var _repair = null
var _computer: Computer = null
var _shop_camera: Camera3D = null

func _ready() -> void:
	GameState.repair_requested.connect(_on_repair_requested)

func _hand() -> PlayerHand:
	return get_tree().get_first_node_in_group("hand") as PlayerHand

func _on_repair_requested(computer: Computer, part: Part) -> void:
	if _repair != null:
		return

	var scene: PackedScene = software_repair_scene if computer.job.is_software else hardware_repair_scene
	if scene == null:
		push_warning("Main: no repair scene assigned for this kind of job")
		if part != null:
			_hand().give(part)   # the hand already let go of it, give it back
		return

	_computer = computer
	_shop_camera = get_viewport().get_camera_3d()

	shop.visible = false
	shop.process_mode = Node.PROCESS_MODE_DISABLED

	_repair = scene.instantiate()
	add_child(_repair)
	_repair.setup(computer.job, part)
	_repair.finished.connect(_on_repair_finished)

func _on_repair_finished(success: bool, part: Part) -> void:
	# If it didn't work out, pull the part out before the repair scene is freed.
	if not success and part != null:
		part.get_parent().remove_child(part)

	_repair.queue_free()
	_repair = null

	shop.visible = true
	shop.process_mode = Node.PROCESS_MODE_INHERIT
	if _shop_camera != null:
		_shop_camera.make_current()

	if success:
		# An installed part is freed along with the repair scene.
		var customer: Customer = _computer.customer as Customer
		GameState.complete_job(_computer.job, customer.patience_fraction())
		customer.leave(true)
	elif part != null:
		_hand().give(part)
	_computer = null