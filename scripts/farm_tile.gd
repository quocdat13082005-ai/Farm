extends Node2D
# Một ô đất trong nông trại: đất mộc (không cỏ) -> đất cày -> đã gieo hạt.
# Cây lớn dần theo THỜI GIAN THẬT khi đất ẩm; đất khô sau ~4 phút thì phải tưới lại.

const TextureGen := preload("res://scripts/texture_gen.gd")
const CropDB := preload("res://scripts/crop_db.gd")

const DRY_SEC := 240.0  # đất đủ ẩm kéo dài bao lâu (giây thật) trước khi khô

enum TState { GRASS, TILLED, PLANTED }

var tstate: int = TState.GRASS
var crop_id := ""
var growth := 0.0  # số giây đã lớn (đất ẩm)
var watered := false
var coord := Vector2i.ZERO
var farm: Node2D = null

var _soil: Sprite2D
var _crop_spr: Sprite2D
var _wet_time := 0.0
var _last_stage := -1


func _ready() -> void:
	_soil = Sprite2D.new()
	_soil.texture = TextureGen.get_tex("tilled")
	_soil.visible = false
	add_child(_soil)
	_crop_spr = Sprite2D.new()
	_crop_spr.offset = Vector2(0, -16)
	_crop_spr.visible = false
	add_child(_crop_spr)


func setup(c: Vector2i) -> void:
	coord = c
	position = Vector2(c.x * 32 + 16, c.y * 32 + 16)


func _process(delta: float) -> void:
	tick_growth(delta)


# Mỗi nhịp thời gian: đất ẩm dần khô đi, cây lớn khi đất còn ẩm và chưa chín.
func tick_growth(delta: float) -> void:
	if tstate != TState.PLANTED:
		return
	if watered:
		_wet_time += delta
		if _wet_time >= DRY_SEC:
			watered = false
			_wet_time = 0.0
			refresh()
			return
	else:
		return
	if is_ready():
		return
	growth += delta
	var c := CropDB.get_crop(crop_id)
	if c.is_empty():
		return
	var st := visual_stage(c)
	if st != _last_stage:
		refresh()


func till() -> void:
	tstate = TState.TILLED
	refresh()
	notify_horizontal_neighbors()


func plant(id: String) -> void:
	crop_id = id
	growth = 0.0
	_last_stage = -1
	tstate = TState.PLANTED
	refresh()


func water() -> void:
	if tstate != TState.PLANTED:
		return
	watered = true
	_wet_time = 0.0
	refresh()


func is_ready() -> bool:
	if tstate != TState.PLANTED:
		return false
	var c := CropDB.get_crop(crop_id)
	return not c.is_empty() and growth >= float(c.grow_sec)


func harvest() -> String:
	var id := crop_id
	crop_id = ""
	growth = 0.0
	watered = false
	_wet_time = 0.0
	tstate = TState.TILLED
	refresh()
	return id


func reset_tile() -> void:
	tstate = TState.GRASS
	crop_id = ""
	growth = 0.0
	watered = false
	_wet_time = 0.0
	_last_stage = -1
	refresh()
	notify_horizontal_neighbors()


func refresh() -> void:
	if _soil == null:
		return
	if tstate == TState.GRASS:
		_soil.visible = false
		_crop_spr.visible = false
		return
	_soil.visible = true
	var w: bool = _has_soil(Vector2i(-1, 0))
	var e: bool = _has_soil(Vector2i(1, 0))
	var dir_type := "isolated"
	if not w and e:
		dir_type = "left"
	elif w and e:
		dir_type = "mid"
	elif w and not e:
		dir_type = "right"

	var tex_key := "tilled_wet_%s" % dir_type if watered else "tilled_%s" % dir_type
	_soil.texture = TextureGen.get_tex(tex_key)
	if tstate == TState.PLANTED:
		var c := CropDB.get_crop(crop_id)
		if c.is_empty():
			_crop_spr.visible = false
			return
		_crop_spr.visible = true
		_last_stage = visual_stage(c)
		_crop_spr.texture = TextureGen.crop_tex(c, _last_stage)
	else:
		_crop_spr.visible = false


func _has_soil(offset: Vector2i) -> bool:
	var f := farm
	if f == null:
		var p = get_parent()
		if p is Node2D and ("tiles" in p):
			f = p
	if f == null or not ("tiles" in f):
		return false
	var neighbor = f.tiles.get(coord + offset)
	return neighbor != null and neighbor.tstate != TState.GRASS


func notify_horizontal_neighbors() -> void:
	var f := farm
	if f == null:
		var p = get_parent()
		if p is Node2D and ("tiles" in p):
			f = p
	if f == null or not ("tiles" in f):
		return
	var left_tile = f.tiles.get(coord + Vector2i(-1, 0))
	if left_tile != null and left_tile.tstate != TState.GRASS:
		left_tile.refresh()
	var right_tile = f.tiles.get(coord + Vector2i(1, 0))
	if right_tile != null and right_tile.tstate != TState.GRASS:
		right_tile.refresh()


func visual_stage(c: Dictionary) -> int:
	var total_st: int = int(c.get("stages", 5))
	var t := float(c.get("grow_sec", 60))
	if growth >= t:
		return total_st - 1
	if growth <= 0.0:
		return 0
	var pct := clampf(growth / t, 0.0, 0.999)
	return int(pct * (total_st - 1))


func get_state() -> Dictionary:
	if tstate == TState.GRASS:
		return {}
	return {"x": coord.x, "y": coord.y, "s": tstate, "c": crop_id,
			"g": int(round(growth)), "w": watered}


func apply_state(d: Dictionary) -> void:
	tstate = int(d.get("s", 0))
	crop_id = str(d.get("c", ""))
	growth = float(d.get("g", 0))
	watered = bool(d.get("w", false))
	_wet_time = 0.0
	refresh()
	notify_horizontal_neighbors()
