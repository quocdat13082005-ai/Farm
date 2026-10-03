extends CanvasLayer
# Bản đồ nhỏ (minimap): xem toàn bộ nông trại, bấm vào một địa điểm để có dải chấm trắng
# dẫn đường trong thế giới. Phím "+" phóng to bản đồ ra giữa màn hình, "-" thu về như cũ.

const UIKit := preload("res://scripts/ui/ui_kit.gd")

const WORLD_SIZE := Vector2(1500, 1000)
const SMALL_W := 272.0
const DOT_SPACING := 26.0

# Đồ thị nút giao nằm trên mạng lối đi PATHS (xem main.gd) — dùng tính đường đi.
const NODES := {
	"house": Vector2(250, 250),
	"j_house": Vector2(250, 470),
	"j_pen": Vector2(304, 470),
	"pen": Vector2(304, 574),
	"farm_w": Vector2(408, 470),
	"farm": Vector2(648, 470),
	"j_tu": Vector2(1010, 470),
	"tu": Vector2(1010, 430),
	"j_pond": Vector2(1030, 470),
	"pond": Vector2(1030, 748),
	"j_batu": Vector2(1180, 470),
	"batu": Vector2(1180, 430),
	"j_hai": Vector2(1350, 470),
	"hai": Vector2(1350, 430),
}
const EDGES := [
	["house", "j_house"], ["j_house", "j_pen"], ["j_pen", "pen"],
	["j_pen", "farm_w"], ["farm_w", "farm"],
	["farm_w", "j_tu"], ["j_tu", "tu"],
	["j_tu", "j_pond"], ["j_pond", "pond"],
	["j_pond", "j_batu"], ["j_batu", "batu"],
	["j_batu", "j_hai"], ["j_hai", "hai"],
]

# Địa điểm bấm được trên bản đồ (id trùng với nút đích trong NODES).
# "mlabel" là tên ngắn vẽ trên bản đồ; "mlab_above" đẩy nhãn lên trên điểm.
const POIS := [
	{"id": "house", "name": "Nhà (ngủ & lưu game)", "mlabel": "Nhà (ngủ & lưu)", "pos": Vector2(250, 250), "color": Color(0.98, 0.62, 0.45), "letter": "N"},
	{"id": "farm", "name": "Nông trại", "mlabel": "Nông trại", "pos": Vector2(648, 470), "color": Color(0.55, 0.88, 0.42), "letter": "R"},
	{"id": "pen", "name": "Chuồng gia cầm", "mlabel": "Chuồng gia cầm", "pos": Vector2(304, 574), "color": Color(0.85, 0.65, 0.35), "letter": "C"},
	{"id": "tu", "name": "Quầy Cô Tư (gia cầm)", "mlabel": "Cô Tư — gia cầm", "mlab_above": true, "pos": Vector2(1010, 430), "color": Color(1.0, 0.68, 0.3), "letter": "T"},
	{"id": "batu", "name": "Quầy Bác Tư (hạt giống)", "mlabel": "Bác Tư — hạt giống", "pos": Vector2(1180, 430), "color": Color(1.0, 0.86, 0.3), "letter": "B"},
	{"id": "hai", "name": "Quầy Chú Hai (cần & cá)", "mlabel": "Chú Hai — cá", "mlab_above": true, "pos": Vector2(1350, 430), "color": Color(0.45, 0.82, 0.95), "letter": "H"},
	{"id": "pond", "name": "Ao câu cá", "mlabel": "Ao câu cá", "pos": Vector2(1030, 748), "color": Color(0.35, 0.6, 0.95), "letter": "A"},
]

var toast_cb := Callable()  # main gán: hud.toast(text, color)

var player: Node2D
var world: Node2D
var main: Node

var big := false
var panel: PanelContainer
var map_view: MapView
var status_label: Label
var cancel_btn: Button
var plus_btn: Button
var minus_btn: Button
var guide: GuideDots
var guide_dest := ""
var guide_name := ""


func _ready() -> void:
	layer = 12
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.resized.connect(_place_panel)
	add_child(root)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(10, 2, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	root.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	# --- hàng tiêu đề + nút phóng to / thu nhỏ ---
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	v.add_child(h)
	UIKit.label(h, "BẢN ĐỒ", 14, UIKit.COLOR_TEXT_TITLE)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(spacer)
	plus_btn = UIKit.styled_button(null, "+", 15, "tab")
	plus_btn.tooltip_text = "Phóng to bản đồ (+)"
	plus_btn.custom_minimum_size = Vector2(30, 26)
	plus_btn.focus_mode = Control.FOCUS_NONE
	plus_btn.pressed.connect(func() -> void: set_big(true))
	h.add_child(plus_btn)
	minus_btn = UIKit.styled_button(null, "−", 15, "tab")
	minus_btn.tooltip_text = "Thu nhỏ bản đồ (-)"
	minus_btn.custom_minimum_size = Vector2(30, 26)
	minus_btn.focus_mode = Control.FOCUS_NONE
	minus_btn.pressed.connect(func() -> void: set_big(false))
	h.add_child(minus_btn)

	# --- khung ảnh bản đồ ---
	map_view = MapView.new()
	map_view.pois = POIS
	map_view.size = Vector2(SMALL_W, SMALL_W / 1.5)
	map_view.custom_minimum_size = map_view.size
	map_view.poi_clicked.connect(_on_poi_clicked)
	v.add_child(map_view)

	# --- dòng trạng thái + nút huỷ ---
	status_label = UIKit.label(v, "Bấm 1 địa điểm để được chỉ đường", 11, UIKit.COLOR_TEXT_MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn = UIKit.styled_button(null, "✕  HỦY CHỈ ĐƯỜNG", 13, "danger")
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.visible = false
	cancel_btn.pressed.connect(_on_cancel_pressed)
	v.add_child(cancel_btn)

	guide = GuideDots.new()
	guide.z_index = 45
	guide.visible = false


# Gọi sau khi đã add_child(minimap): truyền texture nền, người chơi, thế giới, main.
func setup(p_ground_tex: Texture2D, p_player: Node2D, p_world: Node2D, p_main: Node) -> void:
	map_view.ground_tex = p_ground_tex
	player = p_player
	world = p_world
	main = p_main
	world.add_child(guide)
	set_big(false)


func set_big(p_big: bool) -> void:
	big = p_big
	map_view.show_labels = big
	var w := SMALL_W if big == false else minf(780.0, map_view.get_viewport_rect().size.x * 0.62)
	map_view.custom_minimum_size = Vector2(w, w / 1.5)
	plus_btn.disabled = big
	minus_btn.disabled = not big
	_place_panel()


func _place_panel() -> void:
	if panel == null:
		return
	panel.reset_size()
	var vs := map_view.get_viewport_rect().size
	var ps := panel.size
	if big:
		panel.position = (vs - ps) / 2.0
	else:
		panel.position = Vector2(vs.x - ps.x - 16.0, 16.0)


func _process(_delta: float) -> void:
	if player == null or map_view == null:
		return
	map_view.player_pos = player.position
	if guide_dest != "":
		if main != null and main.mode == main.Mode.TITLE:
			_clear_guide(true)
		elif player.position.distance_to(NODES[guide_dest]) < 26.0:
			_clear_guide(true)
			_toast("Đã đến %s 👍" % guide_name, Color(0.65, 1.0, 0.6))


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if main != null and main.mode != main.Mode.PLAY:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
		set_big(true)
	elif key.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
		set_big(false)


# ---------------- chỉ đường ----------------

func _on_poi_clicked(id: String) -> void:
	if get_tree().paused:
		return
	if main != null and main.mode != main.Mode.PLAY:
		return
	var poi := _poi_by_id(id)
	if poi.is_empty() or player == null:
		return
	var pts := _compute_route(player.position, id)
	if pts.size() < 2:
		_toast("Không tìm được đường tới %s" % poi.name, Color(1.0, 0.7, 0.5))
		return
	guide_dest = id
	guide_name = str(poi.name)
	guide.set_route(pts, NODES[id])
	map_view.dest_id = id
	cancel_btn.visible = true
	status_label.text = "Đang tới: %s" % poi.name
	_toast("Làm theo chấm trắng để tới %s" % poi.name, Color(1.0, 0.95, 0.7))


func _on_cancel_pressed() -> void:
	_clear_guide(false)


func _clear_guide(silent: bool) -> void:
	guide_dest = ""
	guide_name = ""
	guide.clear_route()
	map_view.dest_id = ""
	cancel_btn.visible = false
	status_label.text = "Bấm 1 địa điểm để được chỉ đường"
	if not silent:
		_toast("Đã huỷ chỉ đường", Color(0.85, 0.85, 0.85))


# Tính tuyến từ vị trí người chơi tới nút đích:
# bám vào cạnh gần nhất rồi Dijkstra trên đồ thị lối đi.
func _compute_route(start: Vector2, dest_id: String) -> PackedVector2Array:
	var best_d := INF
	var best_i := -1
	var best_t := 0.0
	for i in EDGES.size():
		var a: Vector2 = NODES[EDGES[i][0]]
		var b: Vector2 = NODES[EDGES[i][1]]
		var ab := b - a
		var t := clampf((start - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := start.distance_to(a + ab * t)
		if d < best_d:
			best_d = d
			best_i = i
			best_t = t
	if best_i < 0:
		return PackedVector2Array()

	var ea: String = EDGES[best_i][0]
	var eb: String = EDGES[best_i][1]
	var elen: float = NODES[ea].distance_to(NODES[eb])
	var proj: Vector2 = NODES[ea].lerp(NODES[eb], best_t)

	# Dijkstra từ nút ảo "S" (người chơi)
	var adj := {}
	for e in EDGES:
		var w: float = NODES[e[0]].distance_to(NODES[e[1]])
		if not adj.has(e[0]):
			adj[e[0]] = []
		if not adj.has(e[1]):
			adj[e[1]] = []
		adj[e[0]].append([e[1], w])
		adj[e[1]].append([e[0], w])
	adj["S"] = []
	if best_t <= 0.001:
		adj["S"].append([ea, best_d])
	elif best_t >= 0.999:
		adj["S"].append([eb, best_d])
	else:
		adj["S"].append([ea, best_d + elen * best_t])
		adj["S"].append([eb, best_d + elen * (1.0 - best_t)])

	var dist := {"S": 0.0}
	var prev := {}
	var visited := {}
	for _i in adj.size() + 1:
		var cur := ""
		var cur_d := INF
		for n in dist:
			if not visited.get(n, false) and dist[n] < cur_d:
				cur = n
				cur_d = dist[n]
		if cur == "" or cur == dest_id:
			break
		visited[cur] = true
		for nb in adj.get(cur, []):
			var nd: float = cur_d + nb[1]
			if nd < float(dist.get(nb[0], INF)):
				dist[nb[0]] = nd
				prev[nb[0]] = cur
	if not dist.has(dest_id):
		return PackedVector2Array()

	var chain := []
	var walk := dest_id
	while walk != "S" and walk != "":
		chain.push_front(walk)
		walk = str(prev.get(walk, ""))

	var pts := PackedVector2Array([start])
	if best_t > 0.001 and best_t < 0.999:
		pts.append(proj)
	for id in chain:
		pts.append(NODES[id])
	return pts


func _poi_by_id(id: String) -> Dictionary:
	for poi in POIS:
		if str(poi.id) == id:
			return poi
	return {}


func _toast(text: String, color: Color) -> void:
	if toast_cb.is_valid():
		toast_cb.call(text, color)


# ================= khung vẽ bản đồ =================

class MapView:
	extends Control
	# Vẽ ảnh nền thu nhỏ + điểm địa điểm + người chơi; bấm vào địa điểm để được chỉ đường.

	signal poi_clicked(id: String)

	var ground_tex: Texture2D
	var pois: Array = []
	var player_pos := Vector2(-9999, -9999)
	var dest_id := ""
	var hover_id := ""
	var show_labels := false

	var _time := 0.0


	func _world_to_map(p: Vector2) -> Vector2:
		return p * (size / WORLD_SIZE)


	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()


	func _draw() -> void:
		if ground_tex != null:
			draw_texture_rect(ground_tex, Rect2(Vector2.ZERO, size), false)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.66, 0.31))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.05, 0.03, 0.9), false, 2.0)

		var font := ThemeDB.fallback_font
		var pr := clampf(size.x / 40.0, 5.0, 9.0)  # bán kính điểm địa điểm theo khung
		for poi in pois:
			var mp := _world_to_map(poi.pos)
			if str(dest_id) == str(poi.id):
				draw_circle(mp, pr + 4.0 + sin(_time * 4.0), Color(1, 1, 1, 0.35))
			if str(hover_id) == str(poi.id) or str(dest_id) == str(poi.id):
				draw_circle(mp, pr + 2.5, Color(0.08, 0.05, 0.03))
			draw_circle(mp, pr, Color(0.08, 0.05, 0.03))
			draw_circle(mp, pr - 1.5, poi.color)
			var fs := int(pr + 3)
			var sw := font.get_string_size(str(poi.letter), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, mp + Vector2(-sw / 2.0, fs * 0.35), str(poi.letter),
					HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.07, 0.04))
			if show_labels:
				var nm: String = str(poi.get("mlabel", poi.name))
				var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
				var ly: float = mp.y - (pr + 4.0) if bool(poi.get("mlab_above", false)) else mp.y + (pr + 13.0)
				var lp := Vector2(mp.x - nw / 2.0, ly)
				draw_string_outline(font, lp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 2, Color(0.08, 0.05, 0.03))
				draw_string(font, lp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.97, 0.9))

		# điểm người chơi nhấp nháy nhẹ
		var pp := _world_to_map(player_pos)
		draw_circle(pp, pr + 1.0 + sin(_time * 5.0), Color(1, 1, 1, 0.3))
		draw_circle(pp, pr - 0.5, Color(0.08, 0.05, 0.03))
		draw_circle(pp, pr - 1.8, Color.WHITE)


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var id := _poi_at(event.position)
			if id != "":
				poi_clicked.emit(id)
				accept_event()
		elif event is InputEventMouseMotion:
			var nid := _poi_at(event.position)
			if nid != hover_id:
				hover_id = nid
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if nid != "" else Control.CURSOR_ARROW
				queue_redraw()


	func _poi_at(pos: Vector2) -> String:
		var best := ""
		var best_d := 14.0
		for poi in pois:
			var d := _world_to_map(poi.pos).distance_to(pos)
			if d <= best_d:
				best_d = d
				best = str(poi.id)
		return best


# ================= dải chấm trắng dẫn đường =================

class GuideDots:
	extends Node2D
	# Vẽ dải chấm trắng chạy dọc tuyến đường về phía đích + vòng sáng nhấp nháy ở đích.

	var route := PackedVector2Array()
	var dest := Vector2.ZERO
	var _phase := 0.0
	var _time := 0.0


	func set_route(pts: PackedVector2Array, dest_pos: Vector2) -> void:
		# gộp điểm trùng/đính nhau để không còn đoạn 0 dài gây chia 0 khi rải chấm
		var clean := PackedVector2Array()
		for p in pts:
			if clean.is_empty() or clean[clean.size() - 1].distance_to(p) > 1.0:
				clean.append(p)
		route = clean
		dest = dest_pos
		_phase = 0.0
		visible = route.size() >= 2
		queue_redraw()


	func clear_route() -> void:
		route = PackedVector2Array()
		visible = false


	func _process(delta: float) -> void:
		if route.size() < 2:
			return
		_phase = fmod(_phase + delta * 16.0, DOT_SPACING)
		_time += delta
		queue_redraw()


	func _draw() -> void:
		if route.size() < 2:
			return
		var total := 0.0
		for i in range(route.size() - 1):
			total += route[i].distance_to(route[i + 1])
		var s := _phase
		while s < total - 10.0:
			var p := _point_at(s)
			draw_circle(p, 5.0, Color(0.08, 0.05, 0.03, 0.5))
			draw_circle(p, 3.4, Color(1, 1, 1, 0.95))
			s += DOT_SPACING
		# vòng chỉ đích
		var pulse := 9.0 + sin(_time * 4.5) * 2.5
		draw_arc(dest, pulse + 2.5, 0, TAU, 28, Color(0.08, 0.05, 0.03, 0.55), 3.0)
		draw_arc(dest, pulse, 0, TAU, 28, Color(1, 0.95, 0.6, 0.95), 2.5)
		draw_circle(dest, 4.0, Color(1, 1, 1, 0.9))


	func _point_at(dist: float) -> Vector2:
		var acc := 0.0
		for i in range(route.size() - 1):
			var seg := route[i].distance_to(route[i + 1])
			if seg < 0.001:
				continue
			if acc + seg >= dist:
				return route[i].lerp(route[i + 1], (dist - acc) / seg)
			acc += seg
		return route[route.size() - 1]
