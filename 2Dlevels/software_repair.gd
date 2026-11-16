extends Control

## 2D software repair. Hosts one of your minigame scenes: picks a random one,
## adds it as a child, and waits for it to say it's done. If you haven't
## assigned any minigames it falls back to a hold-E stand-in.
##
## Scene tree:
##   SoftwareRepair (Control, Layout -> Full Rect)   <- this script
##   ├── Backdrop (ColorRect, Full Rect)   covers the empty 3D world
##   ├── Job (Label)
##   ├── Message (Label)                   stand-in only
##   └── Progress (ProgressBar)            stand-in only
##
## What a minigame scene needs (both are loose, nothing breaks if it lacks them):
##   - a signal that fires when it's over, named one of Done Signals below.
##     It may carry one bool (true = won, false = lost) or nothing (= won).
##   - optionally: func setup_job(job: RepairJob), called right after it's added,
##     if the game wants to know which job it's for (work_time, task, ...).

signal finished(success: bool, part: Part)

## Drag your minigame scenes in here. One is picked at random per software job.
@export var minigames: Array[PackedScene] = []
## Signal names to listen for on the minigame's root node. First one it has wins.
@export var done_signals: Array[StringName] = [&"completed", &"finished", &"done"]
## Pause after a win so its "you did it" feedback can play.
@export var finish_delay: float = 0.6

@onready var job_label: Label = $Job

var job: RepairJob
var _game: Node = null
var _done: bool = false
var _prev_mouse_mode: Input.MouseMode

# Stand-in state (only used when there are no minigames)
var _armed: bool = false       # E has been released since the scene opened

## Call after add_child(). The part is always null for software jobs.
func setup(j: RepairJob, _p: Part) -> void:
	job = j
	job_label.text = "%s: %s" % [j.customer_name, j.request]

	# 2D minigames want a cursor. Put the old mouse mode back when we leave.
	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_start_minigame()

func _start_minigame() -> void:

	var scene: PackedScene = minigames.pick_random()
	_game = scene.instantiate()
	add_child(_game)

	if _game.has_method(&"setup_job"):
		_game.call(&"setup_job", job)

	for sig in done_signals:
		if _game.has_signal(sig):
			_game.connect(sig, _on_minigame_done)
			return

# Takes one optional value so it works whether the signal carries a bool or nothing.
func _on_minigame_done(result: Variant = true) -> void:
	var won: bool = result if result is bool else true
	_exit(won)

func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_exit(false)

func _exit(success: bool) -> void:
	if _done:
		return
	_done = true
	if success:
		await get_tree().create_timer(finish_delay).timeout
	Input.mouse_mode = _prev_mouse_mode
	finished.emit(success, null)

# ------------------------------------------------------------ stand-in

func _process(_delta: float) -> void:
	if _done or _game != null or job == null:
		return
	if not Input.is_action_pressed("interact"):
		_armed = true        # the E that opened this scene has been let go
		return
	if not _armed:
		return
