extends Control
## A small, original sum-region domino puzzle. Godot 4 / no external assets.
## Add this scene under a CanvasLayer. Disable robot controls while it is open.
signal completed
signal closed(was_completed: bool)

const DESIGN := Vector2(1000, 760)
const TILE_SIZE := Vector2(116, 58)
const TILES := [Vector2i(0, 1), Vector2i(1, 3), Vector2i(1, 2), Vector2i(2, 4), Vector2i(2, 3), Vector2i(3, 5)]
const TARGETS := [5, 9, 13]
const ACCENTS := [Color("a89bd9"), Color("78b6ab"), Color("d1ab79")]
const RESET := Rect2(60, 660, 140, 46)
const CLOSE := Rect2(838, 45, 102, 42)
const DONE := Rect2(800, 660, 140, 46)
const INK := Color("ecedf3")
const MUTED := Color("a3aabb")

# slots[0..1] = region 1, slots[2..3] = region 2, slots[4..5] = region 3.
# A slot contains a tile ID; -1 means empty. Tiles not in a slot stay in the tray.
var slots: Array[int] = [-1, -1, -1, -1, -1, -1]
var tray_order: Array[int] = [0, 1, 2, 3, 4, 5]
var selected := -1
var dragging := false
var press_point := Vector2.ZERO
var pointer := Vector2.ZERO
var solved := false
var closing := false
var old_mouse_mode: int
var message := "Place two dominoes in each region. Count every dot."

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	old_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resized.connect(queue_redraw)
	reset_game()

func reset_game() -> void:
	slots.assign([-1, -1, -1, -1, -1, -1])
	tray_order.shuffle()
	selected = -1
	dragging = false
	solved = false
	message = "Place two dominoes in each region. Count every dot."
	queue_redraw()

func _scale_factor() -> float:
	return maxf(0.001, minf(size.x / DESIGN.x, size.y / DESIGN.y))

func _offset() -> Vector2:
	return (size - DESIGN * _scale_factor()) * 0.5

func _local_to_board(point: Vector2) -> Vector2:
	return (point - _offset()) / _scale_factor()

func _slot_rect(index: int) -> Rect2:
	return Rect2(Vector2(144 + (index / 2) * 300, 255 + (index % 2) * 85), TILE_SIZE)

func _tray_rect(tile: int) -> Rect2:
	return Rect2(Vector2(72 + tray_order.find(tile) * 148, 547), TILE_SIZE)

func _tile_rect(tile: int) -> Rect2:
	var slot := slots.find(tile)
	return _slot_rect(slot) if slot != -1 else _tray_rect(tile)

func _slot_at(point: Vector2) -> int:
	for index in range(6):
		if _slot_rect(index).has_point(point):
			return index
	return -1

func _tile_at(point: Vector2) -> int:
	for tile in range(6):
		if _tile_rect(tile).has_point(point):
			return tile
	return -1

func _gui_input(event: InputEvent) -> void:
	if closing:
		return
	if event is InputEventMouseMotion:
		pointer = _local_to_board(event.position)
		if selected != -1:
			queue_redraw()
	if not event is InputEventMouseButton:
		return
	var point := _local_to_board(event.position)
	pointer = point
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not solved:
		var tile := _tile_at(point)
		if tile != -1:
			_return_to_tray(tile)
		accept_event()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if CLOSE.has_point(point) or (solved and DONE.has_point(point)):
			close_game()
		elif RESET.has_point(point):
			reset_game()
		elif not solved:
			var tile := _tile_at(point)
			var slot := _slot_at(point)
			if selected != -1 and slot != -1 and slots[slot] != selected:
				place_tile(selected, slot)
			elif tile != -1:
				selected = tile
				dragging = true
				press_point = point
			elif selected != -1 and Rect2(55, 515, 890, 115).has_point(point):
				_return_to_tray(selected)
	elif dragging:
		dragging = false
		if point.distance_to(press_point) > 8.0:
			var destination := _slot_at(point)
			if destination != -1:
				place_tile(selected, destination)
			elif Rect2(55, 515, 890, 115).has_point(point):
				_return_to_tray(selected)
	queue_redraw()
	accept_event()

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

func place_tile(tile: int, destination: int) -> void:
	if solved or tile < 0 or tile >= 6 or destination < 0 or destination >= 6:
		return
	var previous := slots.find(tile)
	var displaced := slots[destination]
	if previous != -1:
		slots[previous] = displaced
	# If the selected tile came from the tray, the displaced tile returns there.
	slots[destination] = tile
	selected = -1
	dragging = false
	_check_board()

func _return_to_tray(tile: int) -> void:
	var slot := slots.find(tile)
	if slot != -1:
		slots[slot] = -1
	selected = -1
	dragging = false
	_check_board()

func region_total(region: int) -> int:
	var total := 0
	for slot in range(region * 2, region * 2 + 2):
		var tile := slots[slot]
		if tile != -1:
			total += TILES[tile].x + TILES[tile].y
	return total

func region_full(region: int) -> bool:
	return slots[region * 2] != -1 and slots[region * 2 + 1] != -1

func _check_board() -> void:
	var correct := 0
	for region in range(3):
		if region_full(region) and region_total(region) == TARGETS[region]:
			correct += 1
	message = "%d / 3 regions complete. Move tiles freely until every total matches." % correct
	queue_redraw()
	if correct == 3 and not solved:
		solved = true
		message = "CIRCUIT BALANCED - repair complete!"
		completed.emit()

func close_game() -> void:
	if closing:
		return
	closing = true
	hide()
	Input.mouse_mode = old_mouse_mode
	closed.emit(solved)
	queue_free()

func _exit_tree() -> void:
	if not closing:
		Input.mouse_mode = old_mouse_mode

func _box(rect: Rect2, fill: Color, edge: Color, radius: int = 12) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func _text(point: Vector2, value: String, font_size: int, color: Color = INK) -> void:
	draw_string(ThemeDB.fallback_font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _pips(center: Vector2, count: int) -> void:
	var points: Array[Vector2] = []
	if count % 2 == 1:
		points.append(Vector2.ZERO)
	if count >= 2:
		points.append_array([Vector2(-13, -13), Vector2(13, 13)])
	if count >= 4:
		points.append_array([Vector2(13, -13), Vector2(-13, 13)])
	if count == 6:
		points.append_array([Vector2(-13, 0), Vector2(13, 0)])
	for point in points:
		draw_circle(center + point, 4.3, Color("222838"))

func _domino(tile: int, rect: Rect2) -> void:
	_box(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0, 0, 0, 0.35), Color.TRANSPARENT, 8)
	_box(rect, Color("e0ded6"), Color("b6a3f5") if selected == tile else Color("aaaeb4"), 8)
	draw_line(rect.position + Vector2(58, 7), rect.position + Vector2(58, 51), Color("a2a4aa"), 2)
	_pips(rect.position + Vector2(29, 29), TILES[tile].x)
	_pips(rect.position + Vector2(87, 29), TILES[tile].y)

func _button(rect: Rect2, title: String) -> void:
	_box(rect, Color("262d3c"), Color("424d61"), 8)
	_text(rect.position + Vector2(16, 29), title, 18)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d1119"))
	draw_set_transform(_offset(), 0.0, Vector2.ONE * _scale_factor())
	_text(Vector2(60, 58), "REPAIR 02 / LOGIC PANEL", 14, MUTED)
	_text(Vector2(60, 103), "CIRCUIT DOMINOES", 33)
	_text(Vector2(60, 139), "Two tiles per region. Make the dots add up to the target.", 20, MUTED)
	_button(CLOSE, "CLOSE")
	for region in range(3):
		var x := 60 + region * 300
		var accent: Color = ACCENTS[region]
		var total := region_total(region)
		var full := region_full(region)
		var correct: bool = full and total == TARGETS[region]
		_box(Rect2(x, 182, 280, 265), Color("191e2b"), Color("80c7a7") if correct else accent.darkened(0.4))
		_text(Vector2(x + 20, 215), "REGION " + str(region + 1), 14, accent)
		_text(Vector2(x + 20, 242), "TARGET  " + str(TARGETS[region]), 21)
		for slot in range(region * 2, region * 2 + 2):
			_box(_slot_rect(slot), Color("111621"), Color("3a4356"), 8)
		var status := "MATCH" if correct else ("ADJUST" if full else "FILL BOTH")
		_text(Vector2(x + 20, 430), "Total %d / %d   %s" % [total, TARGETS[region], status], 17, Color("80c7a7") if correct else MUTED)
	_text(Vector2(60, 488), "YOUR DOMINOES", 16)
	_text(Vector2(260, 488), "Drag a tile, or click a tile then a slot.", 18, MUTED)
	_box(Rect2(55, 515, 890, 115), Color("151b26"), Color("283244"))
	for tile in range(6):
		_box(_tray_rect(tile), Color("111620"), Color("242c3b"), 8)
		if not (dragging and selected == tile and pointer.distance_to(press_point) > 8.0):
			_domino(tile, _tile_rect(tile))
	if dragging and selected != -1 and pointer.distance_to(press_point) > 8.0:
		_domino(selected, Rect2(pointer - TILE_SIZE * 0.5, TILE_SIZE))
	_text(Vector2(60, 651), message, 18, Color("80c7a7") if solved else MUTED)
	_button(RESET, "RESET [R]")
	_text(Vector2(225, 689), "Right-click a tile to return it.  /  ESC to leave", 17, MUTED)
	if solved:
		_button(DONE, "DONE")
