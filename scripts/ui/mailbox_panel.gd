extends CanvasLayer
# Hòm Thư Trước Nhà: Quà tặng tân nông dân (999 cuốc, 999 xu) & Giao diện thư từ làng quê.

const TextureGen := preload("res://scripts/texture_gen.gd")
const UIKit := preload("res://scripts/ui/ui_kit.gd")

signal closed
signal changed

var data: Dictionary = {}

var player_hoes_label: Label
var player_coins_label: Label
var hoes_count_label: Label
var coins_count_label: Label
var take_hoes_btn: Button
var take_coins_btn: Button
var deposit_hoes_btn: Button
var deposit_coins_btn: Button
var claim_all_btn: Button
var empty_label: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.wood_frame(14, 3, UIKit.COLOR_WOOD_DARK, UIKit.COLOR_BORDER_GOLD))
	panel.custom_minimum_size = Vector2(640, 500)
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	# --- Tiêu đề & Thông tin đầu trang ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)

	var title := UIKit.title_label(head, "📬 HÒM THƯ TRƯỚC NHÀ", 22, UIKit.COLOR_TEXT_TITLE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Huy hiệu tiền & cuốc của người chơi
	var player_box := PanelContainer.new()
	player_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.20, 0.14, 0.08), UIKit.COLOR_BORDER_WOOD, 6))
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 10)
	player_box.add_child(ph)

	var mic := TextureRect.new()
	mic.texture = TextureGen.coin_icon()
	mic.custom_minimum_size = Vector2(16, 16)
	mic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ph.add_child(mic)
	player_coins_label = UIKit.label(ph, "%d xu" % GameState.money, 13, UIKit.COLOR_TEXT_GOLD)

	var hic := TextureRect.new()
	hic.texture = TextureGen.hoe_icon()
	hic.custom_minimum_size = Vector2(16, 16)
	hic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ph.add_child(hic)
	player_hoes_label = UIKit.label(ph, "×%d cuốc" % Inventory.hoes, 13, UIKit.COLOR_TEXT_BODY)

	head.add_child(player_box)

	var close_btn := UIKit.styled_button(head, "✕ Đóng (Esc)", 13, "danger")
	close_btn.pressed.connect(close)

	# --- Thư chào mừng từ Thị Trưởng / Làng ---
	var letter_box := PanelContainer.new()
	letter_box.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.23, 0.16, 0.10, 0.9), UIKit.COLOR_BORDER_GOLD, 8))
	v.add_child(letter_box)

	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 4)
	letter_box.add_child(lv)

	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", 6)
	lv.add_child(lh)

	var star_ic := TextureRect.new()
	star_ic.texture = TextureGen.star_icon()
	star_ic.custom_minimum_size = Vector2(16, 16)
	star_ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	lh.add_child(star_ic)

	UIKit.label(lh, "Thư Chào Mừng Tân Nông Dân!", 14, UIKit.COLOR_TEXT_TITLE)

	var letter_desc := UIKit.label(lv, "Kính gửi bạn! Chúc mừng bạn đã đến tiếp quản nông trại. Làng đã gửi tặng bạn gói quà hỗ trợ khởi nghiệp gồm 999 cuốc cày đất và 999 xu vàng trong hòm thư này. Chúc bạn có những mùa màng bội thu!", 12, UIKit.COLOR_TEXT_MUTED)
	letter_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	UIKit.divider(v)

	# --- Danh sách vật phẩm trong hòm ---
	var items_v := VBoxContainer.new()
	items_v.add_theme_constant_override("separation", 8)
	v.add_child(items_v)

	# 1. Hàng Cuốc
	var hoe_p := PanelContainer.new()
	hoe_p.add_theme_stylebox_override("panel", UIKit.row_box())
	items_v.add_child(hoe_p)

	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 10)
	hoe_p.add_child(hh)

	var h_slot := PanelContainer.new()
	h_slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var h_icon := TextureRect.new()
	h_icon.texture = TextureGen.hoe_icon()
	h_icon.custom_minimum_size = Vector2(28, 28)
	h_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	h_slot.add_child(h_icon)
	hh.add_child(h_slot)

	var h_info := VBoxContainer.new()
	h_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_info.add_theme_constant_override("separation", 2)
	hh.add_child(h_info)

	UIKit.label(h_info, "Cuốc Cày Đất", 15, UIKit.COLOR_TEXT_BODY)
	UIKit.label(h_info, "Dụng cụ dùng để cày xới đất trồng trọt (1 cuốc/ô).", 12, UIKit.COLOR_TEXT_MUTED)

	var h_pill := PanelContainer.new()
	h_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.14, 0.10, 0.07), UIKit.COLOR_BORDER_WOOD, 6))
	hoes_count_label = UIKit.label(h_pill, "×0 cuốc", 14, UIKit.COLOR_TEXT_TITLE)
	hh.add_child(h_pill)

	take_hoes_btn = UIKit.styled_button(hh, "Lấy cuốc", 13, "buy")
	take_hoes_btn.custom_minimum_size = Vector2(90, 32)
	take_hoes_btn.pressed.connect(_take_hoes)

	deposit_hoes_btn = UIKit.styled_button(hh, "Cất 10", 12, "default")
	deposit_hoes_btn.custom_minimum_size = Vector2(70, 32)
	deposit_hoes_btn.tooltip_text = "Cất 10 cuốc từ túi vào hòm thư"
	deposit_hoes_btn.pressed.connect(_deposit_hoes)

	# 2. Hàng Xu
	var coin_p := PanelContainer.new()
	coin_p.add_theme_stylebox_override("panel", UIKit.row_box())
	items_v.add_child(coin_p)

	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 10)
	coin_p.add_child(ch)

	var c_slot := PanelContainer.new()
	c_slot.add_theme_stylebox_override("panel", UIKit.slot_box(false))
	var c_icon := TextureRect.new()
	c_icon.texture = TextureGen.coin_icon()
	c_icon.custom_minimum_size = Vector2(28, 28)
	c_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	c_slot.add_child(c_icon)
	ch.add_child(c_slot)

	var c_info := VBoxContainer.new()
	c_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_info.add_theme_constant_override("separation", 2)
	ch.add_child(c_info)

	UIKit.label(c_info, "Tiền Vàng Thị Trấn", 15, UIKit.COLOR_TEXT_GOLD)
	UIKit.label(c_info, "Tiền tệ dùng để mua sắm hạt giống, cần câu và gia cầm.", 12, UIKit.COLOR_TEXT_MUTED)

	var c_pill := PanelContainer.new()
	c_pill.add_theme_stylebox_override("panel", UIKit.badge_box(Color(0.24, 0.16, 0.08), UIKit.COLOR_BORDER_GOLD, 6))
	coins_count_label = UIKit.label(c_pill, "+0 xu", 14, UIKit.COLOR_TEXT_GOLD)
	ch.add_child(c_pill)

	take_coins_btn = UIKit.styled_button(ch, "Lấy xu", 13, "buy")
	take_coins_btn.custom_minimum_size = Vector2(90, 32)
	take_coins_btn.pressed.connect(_take_coins)

	deposit_coins_btn = UIKit.styled_button(ch, "Cất 50", 12, "default")
	deposit_coins_btn.custom_minimum_size = Vector2(70, 32)
	deposit_coins_btn.tooltip_text = "Cất 50 xu từ ví vào hòm thư"
	deposit_coins_btn.pressed.connect(_deposit_coins)

	empty_label = UIKit.label(v, "(Hòm thư đang trống · Bạn đã nhận hết quà khởi đầu!)", 13, UIKit.COLOR_TEXT_MUTED)
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	UIKit.divider(v)

	# --- Nút Nhận Tất Cả & Hành động dưới cùng ---
	var bottom_h := HBoxContainer.new()
	bottom_h.add_theme_constant_override("separation", 12)
	v.add_child(bottom_h)

	claim_all_btn = UIKit.styled_button(bottom_h, "🎁 NHẬN TẤT CẢ VÀO TÚI", 15, "buy")
	claim_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	claim_all_btn.custom_minimum_size = Vector2(0, 42)
	claim_all_btn.pressed.connect(_claim_all)

	var close_btn_bot := UIKit.styled_button(bottom_h, "✕ Đóng (Esc/E)", 14, "default")
	close_btn_bot.custom_minimum_size = Vector2(130, 42)
	close_btn_bot.pressed.connect(close)


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		close()


func open(mb_data: Dictionary) -> void:
	data = mb_data
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	var hoes_in_box: int = int(data.get("hoes", 0))
	var coins_in_box: int = int(data.get("coins", 0))

	if player_hoes_label != null:
		player_hoes_label.text = "×%d cuốc" % Inventory.hoes
	if player_coins_label != null:
		player_coins_label.text = "%d xu" % GameState.money

	if hoes_count_label != null:
		hoes_count_label.text = "×%d cuốc" % hoes_in_box
	if coins_count_label != null:
		coins_count_label.text = "+%d xu" % coins_in_box

	if take_hoes_btn != null:
		take_hoes_btn.disabled = hoes_in_box <= 0
	if take_coins_btn != null:
		take_coins_btn.disabled = coins_in_box <= 0

	if deposit_hoes_btn != null:
		deposit_hoes_btn.disabled = Inventory.hoes < 10
	if deposit_coins_btn != null:
		deposit_coins_btn.disabled = GameState.money < 50

	var has_items := (hoes_in_box > 0 or coins_in_box > 0)
	if claim_all_btn != null:
		claim_all_btn.disabled = not has_items
	if empty_label != null:
		empty_label.visible = not has_items


func _claim_all() -> void:
	var h: int = int(data.get("hoes", 0))
	var c: int = int(data.get("coins", 0))
	if h <= 0 and c <= 0:
		return
	if h > 0:
		Inventory.add_hoes(h)
		data["hoes"] = 0
	if c > 0:
		GameState.add_money(c)
		data["coins"] = 0
	changed.emit()
	refresh()


func _take_hoes() -> void:
	var h: int = int(data.get("hoes", 0))
	if h <= 0:
		return
	Inventory.add_hoes(h)
	data["hoes"] = 0
	changed.emit()
	refresh()


func _take_coins() -> void:
	var c: int = int(data.get("coins", 0))
	if c <= 0:
		return
	GameState.add_money(c)
	data["coins"] = 0
	changed.emit()
	refresh()


func _deposit_hoes() -> void:
	if Inventory.hoes < 10:
		return
	Inventory.hoes -= 10
	Inventory.changed.emit()
	data["hoes"] = int(data.get("hoes", 0)) + 10
	changed.emit()
	refresh()


func _deposit_coins() -> void:
	if not GameState.try_spend(50):
		return
	data["coins"] = int(data.get("coins", 0)) + 50
	changed.emit()
	refresh()
