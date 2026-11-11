extends Control
## Godot 4. Instantiate the scene under a CanvasLayer in your 3D game.
## The parent should disable player controls while this panel is open.

signal completed
signal closed(was_completed: bool)

@export var shuffle_sockets: bool = true
@export var free_on_close: bool = true

const BOARD_SIZE := Vector2(1000, 760)
const COLORS := [Color("ed5149"), Color("edbb39"), Color("508fe9"), Color("61c86e")]
const TAGS := ["A", "B", "C", "D"]
const HIT_RADIUS := 34.0
const CLOSE_RECT := Rect2(830, 65, 100, 40)
const RESET_RECT := Rect2(70, 655, 130, 44)
const DONE_RECT := Rect2(800, 655, 130, 44)

# Each right-hand row contains a color ID. Default matches the reference image.
var right_colors: Array[int] = [3, 2, 1, 0]
# Index = left wire/color; value = connected right row, or -1.
var connections: Array[int] = [-1, -1, -1, -1]
var dragging: int = -1
var drag_position := Vector2.ZERO
var solved: bool = false
var feedback: String = "Drag each left wire to its matching color and letter."
var feedback_time: float = 0.0
var old_mouse_mode: int
var mouse_restored: bool = false
var closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	old_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resized.connect(queue_redraw)
	reset_game()


func reset_game() -> void:
	connections.assign([-1, -1, -1, -1])
	right_colors.assign([3, 2, 1, 0])
	if shuffle_sockets:
		right_colors.shuffle()
	dragging = -1
	solved = false
	feedback_time = 0.0
	feedback = "Drag each left wire to its matching color and letter."
	queue_redraw()


func _board_scale() -> float:
	return maxf(0.001, minf(size.x / BOARD_SIZE.x, size.y / BOARD_SIZE.y))


func _board_offset() -> Vector2:
	return (size - BOARD_SIZE * _board_scale()) * 0.5


func _board_position(local_position: Vector2) -> Vector2:
	return (local_position - _board_offset()) / _board_scale()


func _terminal(row: int, right_side: bool) -> Vector2:
	return Vector2(770 if right_side else 230, 240 + row * 110)


func _hit_terminal(point: Vector2, right_side: bool) -> int:
	for row in range(4):
		if point.distance_to(_terminal(row, right_side)) <= HIT_RADIUS:
			return row
	return -1


func _gui_input(event: InputEvent) -> void:
	if closing:
		return
	if event is InputEventMouseMotion and dragging != -1:
		drag_position = _board_position(event.position)
		queue_redraw()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var point := _board_position(event.position)
		if event.pressed:
			if CLOSE_RECT.has_point(point) or (solved and DONE_RECT.has_point(point)):
				close_game()
			elif RESET_RECT.has_point(point):
				reset_game()
			elif not solved:
				var row := _hit_terminal(point, false)
				if row != -1 and connections[row] == -1:
					dragging = row
					drag_position = point
					queue_redraw()
		elif dragging != -1:
			_finish_drag(_hit_terminal(point, true))
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or closing:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_game()
		elif event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			reset_game()


func _finish_drag(right_row: int) -> void:
	var wire := dragging
	dragging = -1
	if wire < 0:
		return
	if right_row >= 0 and right_row < 4 and right_colors[right_row] == wire:
		connections[wire] = right_row
		feedback = "Connection secured."
	else:
		feedback = "Wrong socket. Match the color and letter."
	feedback_time = 1.6
	if not connections.has(-1):
		solved = true
		feedback = "POWER RESTORED - all four wires connected!"
		queue_redraw()
		completed.emit()
		return
	queue_redraw()


func _process(delta: float) -> void:
	# Cancel a drag if the window lost focus or the mouse was released outside it.
	if dragging != -1 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = -1
		queue_redraw()
	if feedback_time > 0.0 and not solved:
		feedback_time -= delta
		if feedback_time <= 0.0:
			feedback = "Drag each left wire to its matching color and letter."
			queue_redraw()


func close_game() -> void:
	if closing:
		return
	closing = true
	dragging = -1
	hide()
	_restore_mouse()
	closed.emit(solved)
	if free_on_close:
		queue_free()


func _restore_mouse() -> void:
	if not mouse_restored:
		Input.mouse_mode = old_mouse_mode
		mouse_restored = true


func _exit_tree() -> void:
	_restore_mouse()


func _text(at: Vector2, value: String, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _cable(start: Vector2, end: Vector2, color: Color) -> void:
	draw_line(start + Vector2(0, 5), end + Vector2(0, 5), Color(0, 0, 0, 0.6), 19, true)
	draw_line(start, end, color.darkened(0.55), 16, true)
	draw_line(start, end, color, 10, true)
	draw_line(start + Vector2(0, -2), end + Vector2(0, -2), color.lightened(0.2), 2, true)


func _button(rect: Rect2, title: String, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(rect, color.lightened(0.25), false, 2)
	_text(rect.position + Vector2(14, 29), title, 19, Color.WHITE)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.03, 0.025, 0.94))
	draw_set_transform(_board_offset(), 0.0, Vector2.ONE * _board_scale())
	draw_rect(Rect2(40, 30, 920, 700), Color("5b5144"))
	draw_rect(Rect2(60, 115, 880, 515), Color("0e1412"))
	draw_rect(Rect2(60, 115, 880, 515), Color("272a26"), false, 12)
	for stripe in range(23):
		draw_rect(Rect2(40 + stripe * 40, 30, 40, 20), Color("c49128") if stripe % 2 == 0 else Color("191b18"))
	_text(Vector2(75, 94), "CONTROL WIRING", 28, Color("f0dfb8"))
	_button(CLOSE_RECT, "CLOSE", Color("403e36"))
	draw_circle(Vector2(890, 160), 12, Color("6aee9a") if solved else Color("9b6134"))
	_text(Vector2(90, 170), "MATCH COLOR + LETTER", 19, Color("93a79b"))
	_text(Vector2(642, 170), "%d / 4 CONNECTED" % (4 - connections.count(-1)), 18, Color("b7c4ba"))
	for row in range(4):
		for side in range(2):
			var is_right := side == 1
			var color_id: int = right_colors[row] if is_right else row
			var p := _terminal(row, is_right)
			draw_circle(p, 30, Color("46453c"))
			draw_circle(p, 23, Color("080c0a"))
			draw_arc(p, 25, 0, TAU, 48, COLORS[color_id].darkened(0.2), 3, true)
			var label_x := 825.0 if is_right else 118.0
			draw_rect(Rect2(label_x, p.y - 23, 48, 46), COLORS[color_id])
			_text(Vector2(label_x + 15, p.y + 8), TAGS[color_id], 25, Color("111713"))
			_text(p + Vector2(-13, 49), ("R" if is_right else "L") + str(row + 1), 16, Color("8c998c"))
	for wire in range(4):
		var start := _terminal(wire, false)
		if connections[wire] != -1:
			_cable(start, _terminal(connections[wire], true), COLORS[wire])
		elif dragging == wire:
			_cable(start, drag_position, COLORS[wire])
			draw_circle(drag_position, 8, Color("d8c499"))
		else:
			_cable(start, start + Vector2(45, 0), COLORS[wire])
	if dragging != -1:
		var hover := _hit_terminal(drag_position, true)
		if hover != -1:
			draw_arc(_terminal(hover, true), 33, 0, TAU, 48, Color.WHITE, 2, true)
	_text(Vector2(220, 612), feedback, 19, Color("78e7a0") if solved else Color("dfd3b8"))
	_button(RESET_RECT, "RETRY [R]", Color("51452d"))
	_text(Vector2(250, 683), "DRAG to connect     /     ESC to leave", 19, Color("ded7c9"))
	if solved:
		_button(DONE_RECT, "DONE", Color("286942"))
