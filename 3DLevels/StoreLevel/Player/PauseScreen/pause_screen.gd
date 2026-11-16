extends CanvasLayer

## Pause menu. Attach to the CanvasLayer root. Scene tree:
##   PauseMenu (CanvasLayer)    <- this script, Layer = 10 (above the HUD)
##   └── Root (Control)         Layout -> Full Rect
##       ├── Dim (ColorRect)    Full Rect, dark translucent color (e.g. #000000a0)
##       └── Buttons (VBoxContainer)   centered
##           ├── ResumeButton (Button)
##           └── QuitButton (Button)
##
## Needs an input action named "pause" (Project Settings -> Input Map, e.g. P).
## Don't use ui_cancel / Esc: the repair scenes already use it to back out.

@onready var resume_button: Button = %Resume
@onready var quit_button: Button = %Quit

var _prev_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	# Must keep running while the rest of the game is paused, or it can't be clicked.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(resume)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if visible:
			resume()
		else:
			pause()

func pause() -> void:
	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()   # so a controller / keyboard can use the menu too

func resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = _prev_mouse_mode

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

# If this menu is removed while open (scene change), don't leave the game frozen.
func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
