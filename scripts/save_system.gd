extends Node
# Lưu / tải game ra file JSON trong user://.

const SAVE_PATH := "user://save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(farm_state: Array, player_pos: Vector2, npc_met: bool, mailbox: Dictionary = {}, foliage: Array = []) -> void:
	var data := {
		"v": 2,
		"money": GameState.money,
		"day": GameState.day,
		"clock": GameState.clock,
		"unlocked": GameState.unlocked.duplicate(),
		"seeds": Inventory.seeds.duplicate(),
		"produce": Inventory.produce.duplicate(),
		"sel": Inventory.selected_seed,
		"hoes": Inventory.hoes,
		"rods": Inventory.rods.duplicate(),
		"fish": Inventory.fish.duplicate(),
		"coops": Inventory.coops.duplicate(),
		"animals": Inventory.animals.duplicate(true),
		"farm": farm_state,
		"player": [player_pos.x, player_pos.y],
		"npc_met": npc_met,
		"mailbox": mailbox.duplicate(),
		"foliage": foliage.duplicate(true),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Không thể ghi file save: " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func load_data() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
