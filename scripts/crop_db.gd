extends RefCounted
# Dữ liệu 16 loại cây Việt Nam, chia 3 nhóm.
# Thứ tự trong mảng chính là thứ tự mở khóa: đủ tiền mới mở khóa cây tiếp theo.
# Mọi nơi dùng file này bằng: const CropDB := preload("res://scripts/crop_db.gd")

const CROPS: Array = [
	# ---- Nhóm cây lương thực ----
	{"id": "rice", "name": "Lúa gạo", "group": "Lương thực", "stages": 5, "shape": "grain",
		"color": "e8d174", "leaf": "7cb342", "seed_price": 10, "sell_price": 26,
		"grow_sec": 60, "unlock_cost": 0, "desc": "Cây lương thực quan trọng nhất Việt Nam."},
	{"id": "wheat", "name": "Lúa mì", "group": "Lương thực", "stages": 5, "shape": "grain",
		"color": "d9b45b", "leaf": "8bc34a", "seed_price": 16, "sell_price": 45,
		"grow_sec": 90, "unlock_cost": 150, "desc": "Cây lương thực chính ở các nước ôn đới."},
	{"id": "corn", "name": "Ngô (Bắp)", "group": "Lương thực", "stages": 6, "shape": "tall",
		"color": "ffd54f", "leaf": "4c9a3f", "seed_price": 22, "sell_price": 70,
		"grow_sec": 120, "unlock_cost": 350, "desc": "Thực phẩm và chế biến thức ăn chăn nuôi."},
	{"id": "sweet_potato", "name": "Khoai lang", "group": "Lương thực", "stages": 5, "shape": "root",
		"color": "9c5fb8", "leaf": "5da25a", "seed_price": 20, "sell_price": 62,
		"grow_sec": 100, "unlock_cost": 600, "desc": "Củ giàu dinh dưỡng, dễ trồng."},
	{"id": "cassava", "name": "Sắn (Khoai mì)", "group": "Lương thực", "stages": 5, "shape": "tall",
		"color": "a1887f", "leaf": "4d9e51", "seed_price": 26, "sell_price": 95,
		"grow_sec": 150, "unlock_cost": 900, "desc": "Tinh bột cho công nghiệp và chăn nuôi."},
	# ---- Nhóm rau củ & ngắn ngày ----
	{"id": "potato", "name": "Khoai tây", "group": "Rau củ", "stages": 6, "shape": "root",
		"color": "d7b06a", "leaf": "589e4c", "seed_price": 30, "sell_price": 88,
		"grow_sec": 120, "unlock_cost": 1250, "desc": "Cây thực phẩm lấy củ ngắn ngày."},
	{"id": "carrot", "name": "Cà rốt", "group": "Rau củ", "stages": 4, "shape": "root",
		"color": "ff7043", "leaf": "3e9142", "seed_price": 24, "sell_price": 66,
		"grow_sec": 75, "unlock_cost": 1650, "desc": "Củ giàu vitamin A."},
	{"id": "cabbage", "name": "Bắp cải", "group": "Rau củ", "stages": 5, "shape": "head",
		"color": "aed581", "leaf": "689f38", "seed_price": 36, "sell_price": 110,
		"grow_sec": 130, "unlock_cost": 2100, "desc": "Rau ăn lá chủ lực mùa lạnh."},
	{"id": "tomato", "name": "Cà chua", "group": "Rau củ", "stages": 6, "shape": "bush",
		"color": "ff5252", "leaf": "3f9b3f", "seed_price": 32, "sell_price": 96,
		"grow_sec": 120, "unlock_cost": 2600, "desc": "Rau ăn quả phổ biến, giá trị kinh tế cao."},
	{"id": "watermelon", "name": "Dưa hấu", "group": "Rau củ", "stages": 6, "shape": "vine",
		"color": "2e7d32", "leaf": "43a047", "seed_price": 48, "sell_price": 155,
		"grow_sec": 180, "unlock_cost": 4200, "desc": "Họ bầu bí, thích hợp đất cát nhiều nắng."},
	# ---- Nhóm cây công nghiệp ----
	{"id": "soybean", "name": "Đậu tương", "group": "Cây công nghiệp", "stages": 6, "shape": "bush",
		"color": "c6d94f", "leaf": "4a8f3c", "seed_price": 34, "sell_price": 92,
		"grow_sec": 100, "unlock_cost": 3100, "desc": "Họ đậu giàu đạm, cải tạo đất tốt."},
	{"id": "peanut", "name": "Lạc (Đậu phụng)", "group": "Cây công nghiệp", "stages": 5, "shape": "bush",
		"color": "d7a86e", "leaf": "4f9443", "seed_price": 30, "sell_price": 84,
		"grow_sec": 100, "unlock_cost": 3600, "desc": "Cây lấy hạt và dầu ngắn ngày."},
	{"id": "sugarcane", "name": "Mía", "group": "Cây công nghiệp", "stages": 5, "shape": "tall",
		"color": "9ccc65", "leaf": "7cb342", "seed_price": 55, "sell_price": 175,
		"grow_sec": 200, "unlock_cost": 5200, "desc": "Nguyên liệu chính của ngành đường."},
	{"id": "coffee", "name": "Cà phê", "group": "Cây công nghiệp", "stages": 6, "shape": "bush",
		"color": "e53935", "leaf": "2e7d32", "seed_price": 65, "sell_price": 225,
		"grow_sec": 240, "unlock_cost": 6800, "desc": "Cây công nghiệp chủ lực xuất khẩu."},
	{"id": "pepper", "name": "Hồ tiêu", "group": "Cây công nghiệp", "stages": 6, "shape": "tall",
		"color": "d84315", "leaf": "33691e", "seed_price": 78, "sell_price": 280,
		"grow_sec": 270, "unlock_cost": 9000, "desc": "Gia vị mang giá trị kinh tế cao."},
	{"id": "rubber", "name": "Cao su", "group": "Cây công nghiệp", "stages": 6, "shape": "tree",
		"color": "eceff1", "leaf": "2e7d32", "seed_price": 95, "sell_price": 330,
		"grow_sec": 300, "unlock_cost": 12000, "desc": "Cây lâu năm, khai thác mủ công nghiệp."},
]


# Ảnh chính của mỗi loại cây khi CHÍN, nằm trong thư mục res://picture/.
# Tên file phải khớp tuyệt đối, kể cả khoảng trắng cuối ("Lúa Mì .png", "Dưa Hấu .png").
const PICTURES := {
	"rice": "Lúa gạo.png",
	"wheat": "Lúa Mì .png",
	"corn": "Cây ngô pixel giữa nền đất_lua.png",
	"sweet_potato": "Khoai Lang.png",
	"cassava": "Sắn.png",
	"potato": "Khoai Tây.png",
	"carrot": "Cà rốt.png",
	"cabbage": "Bắp cải.png",
	"tomato": "Cà chua.png",
	"watermelon": "Dưa Hấu .png",
	"soybean": "Đậu tương.png",
	"peanut": "Lạc.png",
	"sugarcane": "Mía.png",
	"coffee": "Cà Phê.png",
	"pepper": "Hồ tiêu.png",
	"rubber": "Cao su.png",
}


static func picture_path(id: String) -> String:
	if not PICTURES.has(id):
		return ""
	return "res://picture/%s" % PICTURES[id]


static func get_crop(id: String) -> Dictionary:
	for c in CROPS:
		if c.id == id:
			return c
	return {}


static func index_of(id: String) -> int:
	for i in CROPS.size():
		if CROPS[i].id == id:
			return i
	return -1


static func next_locked(unlocked: Array) -> Dictionary:
	for c in CROPS:
		if not unlocked.has(c.id):
			return c
	return {}
