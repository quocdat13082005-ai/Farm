extends CharacterBody2D
# Nhân vật nông dân: đi 4 hướng, đổi hướng tạo ô tương tác.

const TextureGen := preload("res://scripts/texture_gen.gd")

const SPEED := 150.0

var facing := Vector2.DOWN:
	set(val):
		facing = val
		if val != Vector2.ZERO:
			if absf(val.x) >= absf(val.y):
				_dir = "side"
				if _sprite:
					_sprite.flip_h = val.x < 0
			else:
				_dir = "up" if val.y < 0 else "down"
				if _sprite:
					_sprite.flip_h = false
			if _sprite:
				_update_tex(0)

var can_move := true

var _sprite: Sprite2D
var _dir := "down"
var _anim_t := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(1.2, 1.2)
	_sprite.offset = Vector2(0, -18)
	add_child(_sprite)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	col.position = Vector2(0, -5)
	add_child(col)
	_update_tex(0)


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_anim_t = 0.0
		_update_tex(0)
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = v * SPEED
	move_and_slide()
	if v.length() > 0.01:
		if absf(v.x) >= absf(v.y):
			facing = Vector2(signf(v.x), 0)
			_dir = "side"
			_sprite.flip_h = v.x < 0
		else:
			facing = Vector2(0, signf(v.y))
			_dir = "up" if v.y < 0 else "down"
			_sprite.flip_h = false
		_anim_t += delta
		_update_tex(int(_anim_t * 8.0) % 4)
	else:
		_anim_t = 0.0
		_update_tex(0)


func get_facing_point() -> Vector2:
	return global_position + facing * 26.0


# Nhún người ngắn khi làm hành động (cày / gieo / tưới / thu hoạch).
func play_action_anim() -> void:
	_update_tex(99)
	var tw := create_tween()
	tw.tween_property(_sprite, "scale", Vector2(1.35, 1.05), 0.1)
	tw.tween_property(_sprite, "scale", Vector2(1.05, 1.35), 0.12)
	tw.tween_property(_sprite, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_callback(func(): _update_tex(0))


func _update_tex(frame: int) -> void:
	_sprite.texture = TextureGen.char_tex(_dir, frame, false)
