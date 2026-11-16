extends Control
## Six-part drag-and-match repair panel. All artwork is drawn in GDScript.
signal completed
signal closed(was_completed: bool)

const DESIGN := Vector2(1200, 820)
const NAMES := ["RAM", "CPU", "GPU", "FAN", "INPUT", "OUTPUT"]
const PART_SIZES := [Vector2(48, 220), Vector2(104, 104), Vector2(240, 92), Vector2(110, 110), Vector2(124, 62), Vector2(124, 62)]
const TARGETS := [Rect2(630, 260, 48, 220), Rect2(365, 290, 104, 104), Rect2(290, 550, 240, 92), Rect2(130, 340, 110, 110), Rect2(110, 220, 124, 62), Rect2(110, 650, 124, 62)]
const ACCENTS := [Color("8bc2a1"), Color("b1a3d9"), Color("8caacb"), Color("b1bac6"), Color("c7ac79"), Color("88bfc3")]
const RESET := Rect2(55, 757, 145, 44)
const CLOSE := Rect2(1035, 38, 110, 42)
const DONE := Rect2(1000, 757, 145, 44)
const TEXT := Color("e2e7ec")
const MUTED := Color("9aa8b4")

var installed: Array[bool] = [false, false, false, false, false, false]
var selected := -1
var dragging := false
var pointer := Vector2.ZERO
var feedback := "Match each part to its labeled socket."
var solved := false
var previous_mouse_mode
var closing := false
var tray_order: Array[int] = [0, 1, 2, 3, 4, 5]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resized.connect(queue_redraw)
	reset_game()

func reset_game() -> void:
	installed.assign([false, false, false, false, false, false])
	selected = -1
	dragging = false
	solved = false
	feedback = "Match each part to its labeled socket."
	queue_redraw()

func _factor() -> float:
	return maxf(0.001, minf(size.x / DESIGN.x, size.y / DESIGN.y))

func _origin() -> Vector2:
	return (size - DESIGN * _factor()) * 0.5

func _board_point(point: Vector2) -> Vector2:
	return (point - _origin()) / _factor()

func _card(part: int) -> Rect2:
	var index := tray_order.find(part)
	return Rect2(810 + (index % 2) * 166, 220 + floori(index / 2.0) * 168, 152, 154)

func _target_at(point: Vector2) -> int:
	for part in range(6):
		if TARGETS[part].grow(12).has_point(point):
			return part
	return -1

func _tray_at(point: Vector2) -> int:
	for part in range(6):
		if not installed[part] and _card(part).has_point(point):
			return part
	return -1

func _gui_input(event: InputEvent) -> void:
	if closing:
		return
	if event is InputEventMouseMotion:
		pointer = _board_point(event.position)
		if selected != -1:
			queue_redraw()
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return
	pointer = _board_point(event.position)
	if event.pressed:
		if CLOSE.has_point(pointer) or (solved and DONE.has_point(pointer)):
			close_game()
		elif RESET.has_point(pointer):
			reset_game()
		elif not solved:
			var target := _target_at(pointer)
			if selected != -1 and target != -1:
				try_install(selected, target)
			else:
				selected = _tray_at(pointer)
				dragging = selected != -1
	elif dragging:
		dragging = false
		var target := _target_at(pointer)
		# A click on the source card keeps it selected for click-to-place.
		if selected != -1 and _card(selected).has_point(pointer):
			feedback = "Now click the %s socket on the board." % NAMES[selected]
		else:
			try_install(selected, target)
	queue_redraw()
	accept_event()

func try_install(part: int, target: int) -> void:
	dragging = false
	selected = -1
	if solved or part < 0 or part >= 6 or installed[part]:
		return
	if target != part:
		feedback = "That part belongs in the %s socket. Try again." % NAMES[part]
		queue_redraw()
		return
	installed[part] = true
	feedback = "%s installed. %d / 6 parts fitted." % [NAMES[part], installed.count(true)]
	queue_redraw()
	if not installed.has(false):
		solved = true
		feedback = "SYSTEM ONLINE - all six components installed!"
		completed.emit()

func _input(event: InputEvent) -> void:
	if closing or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_game()
		elif event.keycode == KEY_R:
			get_viewport().set_input_as_handled()
			reset_game()

func _process(_delta: float) -> void:
	if dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = false
		queue_redraw()

func close_game() -> void:
	if closing:
		return
	closing = true
	hide()
	Input.mouse_mode = previous_mouse_mode
	closed.emit(solved)
	queue_free()

func _exit_tree() -> void:
	if not closing:
		Input.mouse_mode = previous_mouse_mode

func _box(rect: Rect2, fill: Color, border: Color, radius: int = 8) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _text(point: Vector2, value: String, font_size: int, color: Color = TEXT) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _button(rect: Rect2, title: String) -> void:
	_box(rect, Color("252f3a"), Color("465566"))
	_text(rect.position + Vector2(15, 29), title, 18)

func _screw(point: Vector2) -> void:
	draw_circle(point, 7, Color("667571"))
	draw_circle(point, 4, Color("1b2628"))
	draw_line(point - Vector2(3, 0), point + Vector2(3, 0), Color("8c9991"), 2)

func _fan(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color("0c121b"))
	draw_arc(center, radius - 3, 0, TAU, 48, Color("647381"), 3, true)
	for blade in range(7):
		var angle := blade * TAU / 7.0
		var points := PackedVector2Array([center + Vector2.from_angle(angle) * radius * 0.19, center + Vector2.from_angle(angle + 0.2) * radius * 0.82, center + Vector2.from_angle(angle + 0.72) * radius * 0.84, center + Vector2.from_angle(angle + 0.88) * radius * 0.36])
		draw_colored_polygon(points, Color("465564"))
	draw_circle(center, radius * 0.24, Color("89989c"))
	draw_circle(center, radius * 0.12, Color("26333c"))

# Parts use their own local coordinate system so the tray and board share artwork.
func _part_art(part: int, rect: Rect2) -> void:
	var natural: Vector2 = PART_SIZES[part]
	var zoom: float = minf(rect.size.x / natural.x, rect.size.y / natural.y)
	var corner: Vector2 = rect.position + (rect.size - natural * zoom) * 0.5
	draw_set_transform(_origin() + corner * _factor(), 0, Vector2.ONE * _factor() * zoom)
	match part:
		0: # Flat RAM module with memory chips and gold contacts.
			_box(Rect2(0, 0, 48, 220), Color("294637"), Color("6b8a6c"), 3)
			for chip in range(6):
				_box(Rect2(9, 12 + chip * 32, 27, 23), Color("182024"), Color("40504a"), 2)
			for pin in range(23):
				if pin != 15:
					draw_rect(Rect2(41, 6 + pin * 9, 7, 5), Color("baa268"))
		1: # CPU heat spreader with substrate and corner marker.
			_box(Rect2(0, 0, 104, 104), Color("384c43"), Color("77917c"), 3)
			for pin in range(12):
				draw_rect(Rect2(5 + pin * 8, 2, 4, 5), Color("c0ab77"))
				draw_rect(Rect2(5 + pin * 8, 97, 4, 5), Color("c0ab77"))
			_box(Rect2(10, 10, 84, 84), Color("929b9b"), Color("c0c7c2"), 4)
			_text(Vector2(28, 57), "CPU", 22, Color("2d393e"))
			draw_colored_polygon(PackedVector2Array([Vector2(15, 15), Vector2(26, 15), Vector2(15, 26)]), Color("dcc284"))
		2: # Top-down graphics card, twin fans and PCIe contacts.
			_box(Rect2(0, 0, 240, 85), Color("27313e"), Color("6d8097"), 5)
			draw_rect(Rect2(0, 0, 10, 92), Color("8e999c"))
			for pin in range(22):
				draw_rect(Rect2(38 + pin * 6, 85, 4, 7), Color("b49c63"))
			_fan(Vector2(75, 42), 34)
			_fan(Vector2(164, 42), 34)
			for fin in range(6):
				draw_line(Vector2(211, 13 + fin * 11), Vector2(230, 13 + fin * 11), Color("66778a"), 2)
		3: # Separate board cooling fan; its own socket avoids CPU overlap.
			_box(Rect2(0, 0, 110, 110), Color("29323b"), Color("89969d"), 6)
			_fan(Vector2(55, 55), 47)
			for point in [Vector2(9, 9), Vector2(101, 9), Vector2(9, 101), Vector2(101, 101)]:
				_screw(point)
		4, 5: # Stylized I/O modules, intentionally distinct shapes.
			_box(Rect2(0, 0, 124, 62), Color("3e4d4b") if part == 4 else Color("34434d"), ACCENTS[part], 4)
			if part == 4:
				for port in range(2):
					_box(Rect2(12 + port * 53, 12, 43, 30), Color("a0a7a3"), Color("c0c4b9"), 2)
					draw_rect(Rect2(17 + port * 53, 18, 33, 17), Color("101d24"))
					draw_rect(Rect2(20 + port * 53, 26, 27, 5), Color("8d7952"))
			else:
				draw_colored_polygon(PackedVector2Array([Vector2(13, 13), Vector2(110, 13), Vector2(104, 43), Vector2(20, 43)]), Color("a3b0b1"))
				draw_colored_polygon(PackedVector2Array([Vector2(21, 20), Vector2(102, 20), Vector2(97, 36), Vector2(26, 36)]), Color("14222c"))
				for pin in range(12):
					draw_rect(Rect2(28 + pin * 6, 26, 3, 5), Color("bdab78"))
			for pin in range(12):
				draw_rect(Rect2(14 + pin * 8, 55, 4, 7), Color("b6a475"))
	draw_set_transform(_origin(), 0, Vector2.ONE * _factor())

func _draw_board() -> void:
	_box(Rect2(55, 170, 710, 565), Color("21352f"), Color("617569"), 12)
	# Muted PCB traces, chips, solder points, and mounting screws.
	for trace in range(25):
		var x := 80.0 + trace * 26
		var y := 190.0 + (trace % 5) * 9
		var path := PackedVector2Array([Vector2(x, 195), Vector2(x, y + 280), Vector2(x + 18, y + 298), Vector2(x + 18, 710)])
		draw_polyline(path, Color("304a3d"), 1.5, true)
		for dot in range(4):
			draw_circle(Vector2(x + 18, 490 + dot * 58), 2, Color("728067"))
	for point in [Vector2(75, 190), Vector2(745, 190), Vector2(75, 715), Vector2(745, 715)]:
		_screw(point)
	_box(Rect2(365, 440, 118, 67), Color("343e3d"), Color("6b7871"), 3)
	for fin in range(9):
		draw_line(Vector2(373, 448 + fin * 6), Vector2(475, 448 + fin * 6), Color("84918b"), 2)
	for cap in range(5):
		var point := Vector2(520 + (cap % 2) * 32, 250 + cap * 47)
		draw_circle(point, 11, Color("111b20"))
		draw_circle(point - Vector2(1, 2), 8, Color("9ca8a0"))
		draw_line(point + Vector2(-6, -2), point + Vector2(6, -2), Color("465750"), 2)
	_box(Rect2(570, 650, 115, 35), Color("171f22"), Color("526257"), 3)
	for pin in range(12):
		draw_circle(Vector2(578 + pin * 9, 661), 2, Color("c5b585"))
		draw_circle(Vector2(578 + pin * 9, 674), 2, Color("c5b585"))
	_text(Vector2(283, 705), "MB-03  /  SERVICE BOARD", 15, Color("8b9c8e"))
	for part in range(6):
		var target: Rect2 = TARGETS[part]
		var highlight := selected == part
		_box(target.grow(7), Color("12221f"), ACCENTS[part] if highlight else Color("4d685a"), 5)
		if not installed[part]:
			for mark in range(4):
				var y: float = target.position.y + 10 + mark * (target.size.y - 20) / 3
				draw_line(Vector2(target.position.x + 4, y), Vector2(target.end.x - 4, y), Color("2f4138"), 2)
			_text(target.position + Vector2(0, -16), NAMES[part], 17, ACCENTS[part])
		else:
			_part_art(part, target)
			_text(target.position + Vector2(0, -16), NAMES[part] + "  OK", 17, Color("9ed8b1"))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0c1118"))
	draw_set_transform(_origin(), 0, Vector2.ONE * _factor())
	_text(Vector2(55, 49), "REPAIR 03 / HARDWARE", 14, MUTED)
	_text(Vector2(55, 94), "MOTHERBOARD ASSEMBLY", 33)
	_text(Vector2(55, 130), "Drag the flat components from the tray into their matching sockets.", 20, MUTED)
	_button(CLOSE, "CLOSE")
	_draw_board()
	_box(Rect2(790, 170, 355, 565), Color("171f2a"), Color("354453"), 12)
	_text(Vector2(812, 201), "COMPONENT TRAY", 18)
	_text(Vector2(1058, 201), "%d / 6" % installed.count(true), 18, Color("9ed8b1"))
	for part in range(6):
		var card := _card(part)
		_box(card, Color("202a35") if not installed[part] else Color("15231f"), ACCENTS[part] if selected == part else Color("344352"))
		if installed[part]:
			_text(card.position + Vector2(22, 80), "INSTALLED", 17, Color("9ed8b1"))
		elif not (selected == part and dragging):
			_part_art(part, Rect2(card.position + Vector2(13, 10), Vector2(126, 108)))
		_text(card.position + Vector2(15, 141), NAMES[part], 17, ACCENTS[part])
	if dragging and selected != -1:
		var natural: Vector2 = PART_SIZES[selected]
		var rect := Rect2(pointer - natural * 0.5, natural)
		_box(rect.grow(4), Color(0.03, 0.04, 0.05, 0.9), ACCENTS[selected], 4)
		_part_art(selected, rect)
	_button(RESET, "RESET [R]")
	_text(Vector2(220, 782), feedback, 18, Color("9ed8b1") if solved else MUTED)
	if solved:
		_button(DONE, "DONE")
