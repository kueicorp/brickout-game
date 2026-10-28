## QA 視窗短測(非 headless):
## - 磚(40×20 規格,D31):底圖、數字、被擊中閃白、破壞 4 幀、炸彈標記、無敵外框、不可破壞磚(含被擊中)
##   以 1 倍逐像素對照 art/bricks40 原圖(含疊加順序)。
## - 球、光暈、擋板含槍端與裁切段、砲口閃光:維持原圖 nearest 2 倍逐像素對照;子彈 1 倍。
## 執行:Godot --path game --script res://tests/qa_window_2x_capture.gd -- <輸出資料夾>
## 跑完自動關閉;全部吻合時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")

var _m
var _frame := 0
var _out := ""
var _fail := 0
var _pass := 0
var _mark_seen := {}   # 動態炸彈標記看到的幀:"f1"/"f2" → 次數


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_m = MainScene.instantiate()
	root.add_child(_m)


func _brick(c: int, r: int, layers: int, unbreakable := false):
	var br = MainScript.Brick.new()
	br.layers = layers
	br.unbreakable = unbreakable
	_m.grid[r][c] = br
	return br


## 每格要畫的內容:[格子, 層數, 不可破壞, 標記, 被擊中列(-1 = 沒被擊中)]
var _cases := []
## 破壞動畫:[格子, t, hit_row, color]
const BREAKS := [[Vector2i(2, 1), 0.03, 21, 3], [Vector2i(3, 1), 0.09, 21, 3], [Vector2i(4, 1), 0.15, 21, 3],
	[Vector2i(5, 1), 0.21, 21, 3], [Vector2i(6, 1), 0.27, 21, 3], [Vector2i(7, 1), 0.15, 0, 6]]


func _add(c: int, r: int, layers: int, unbreakable := false, marked := false, hit_row := -1) -> void:
	var br = _brick(c, r, layers, unbreakable)
	br.marked = marked
	if hit_row >= 0:
		br.hit_t = 999.0
		br.hit_row = hit_row
	_cases.append([Vector2i(c, r), layers, unbreakable, marked, hit_row])


func _setup() -> void:
	for r in _m.grid.size():
		for c in _m.grid[r].size():
			_m.grid[r][c] = null
	_m.breakable_left = 99
	_m.items.clear()
	_m.anims.clear()
	_m.bullets.clear()
	_m.state = 1   # 凍結遊戲推進(不呼叫 _end,不出結束畫面),只為截圖
	_m.reduced_motion = true   # 固定炸彈標記、光暈、子彈在 F1,才能逐像素比對
	# 第 0 排:各種磚
	_add(0, 0, 1)                      # 紅、無數字
	_add(1, 0, 9)                      # 橙、數字 1
	_add(2, 0, 20)                     # 靛、數字 2
	_add(3, 0, 1, true)                # 不可破壞
	_add(4, 0, 30, false, true)        # 炸彈標記(30 = 橙 4 → 橙第 0 輪、無數字)
	_add(5, 0, 1, true, false, 0)      # 不可破壞被擊中
	_add(6, 0, 69)                     # 靛、數字 9
	_add(7, 0, 7)                      # 紫、無數字(第 7 欄)
	# 第 1 排:被擊中(閃白 + 扣層前的數字)
	_add(0, 1, 5, false, false, 19)    # 扣層前 20 層 → 閃白 + 數字 2
	_add(1, 1, 2, false, false, 2)     # 扣層前 3 層 → 閃白、無數字
	# 第 2 排:七色第 0 輪
	for i in 7:
		_add(i, 2, i + 1)
	# 第 3、4 排:數字 1~9,顏色輪流
	for d in range(1, 10):
		var layers := 7 * d + (d % 7) + 1
		_add((d - 1) % 8, 3 + (d - 1) / 8, layers)
	# 最後一排(第 16 排)
	_add(0, 16, 14)
	_add(7, 16, 69)
	# 破壞動畫:第 0 幀被擊中(閃白 + 數字)、F1~F3 依顏色、F4 灰塵
	for b in BREAKS:
		_m.anims.append({"kind": "break", "pos": _m._cell_rect(b[0]).position, "t": b[1], "dur": 999.0, "hit_row": b[2], "color": b[3]})
	# 球(一顆整數、一顆小數位置)與光暈(HUD 有格才顯示)
	_m.effects.reinforce = 1
	_m.balls.clear()
	for p in [Vector2(100, 500), Vector2(250.6, 520.4)]:
		var b = MainScript.Ball.new()
		b.pos = p
		_m.balls.append(b)
	# 擋板:新規格基準長度 85(奇數;16 + 32 × 1 + 裁切 21 + 16)+ 槍。不吃長度道具
	# 2026-10-28:槍改為限時效果;給足時間,截圖期間不會到期
	_m.effects.add_timed("gun", 999.0)
	_m.paddle_x = 180.0
	_m.target_x = 180.0
	_m._fire_gun()
	_m.bullets.append(Vector2(150, 600))


func _img(tex: Texture2D) -> Image:
	var i := tex.get_image()
	if i.is_compressed():
		i.decompress()
	return i


## 球、擋板用:目的地 dest 起、src 區域以 scale 倍 nearest 放大;只比原圖完全不透明的像素。
func _check(label: String, shot: Image, tex: Texture2D, src: Rect2i, dest: Vector2i, scale: int, over: Texture2D = null, dest_w := -1) -> void:
	var si := _img(tex)
	var oi: Image = _img(over) if over != null else null
	var w := src.size.x * scale if dest_w < 0 else dest_w
	var h := src.size.y * scale
	var bad := 0
	var checked := 0
	var first := ""
	for y in h:
		for x in w:
			var sp := src.position + Vector2i(x / scale, y / scale)
			var c := si.get_pixelv(sp)
			if oi != null:
				var o := oi.get_pixel(x / scale, y / scale)
				if o.a >= 0.999:
					c = o
				elif o.a > 0.0:
					continue
			if c.a < 0.999:
				continue
			var p := dest + Vector2i(x, y)
			if p.x < 0 or p.y < 0 or p.x >= shot.get_width() or p.y >= shot.get_height():
				continue
			checked += 1
			var g := shot.get_pixelv(p)
			if absf(g.r - c.r) > 0.02 or absf(g.g - c.g) > 0.02 or absf(g.b - c.b) > 0.02:
				bad += 1
				if first == "":
					first = "%s want %s got %s" % [p, c.to_html(false), g.to_html(false)]
	_report(label, bad, checked, first)


func _report(label: String, bad: int, checked: int, first: String) -> void:
	if bad == 0 and checked > 0:
		_pass += 1
		print("OK   %-44s %d px exact" % [label, checked])
	else:
		_fail += 1
		print("FAIL %-44s %d / %d px differ; first %s" % [label, bad, checked, first])


## 磚用(1 倍):names 由下到上疊在 dest 的 40×20;每個像素取最上層不透明的那張。
## 有半透明像素的位置跳過;整疊都透明的位置(看得到背景)跳過。回傳 [bad, checked, first]。
func _cmp_stack(shot: Image, names: Array, dest: Vector2i) -> Array:
	var imgs := []
	for n in names:
		imgs.append(_img(_b(n)))
	var bad := 0
	var checked := 0
	var first := ""
	for y in 20:
		for x in 40:
			var want := Color(0, 0, 0, 0)
			var skip := false
			for k in range(imgs.size() - 1, -1, -1):
				var c: Color = imgs[k].get_pixel(x, y)
				if c.a >= 0.999:
					want = c
					break
				if c.a > 0.0:
					skip = true
					break
			if skip or want.a == 0.0:
				continue
			checked += 1
			var g := shot.get_pixelv(dest + Vector2i(x, y))
			if absf(g.r - want.r) > 0.02 or absf(g.g - want.g) > 0.02 or absf(g.b - want.b) > 0.02:
				bad += 1
				if first == "":
					first = "%s want %s got %s" % [dest + Vector2i(x, y), want.to_html(false), g.to_html(false)]
	return [bad, checked, first]


func _check_stack(label: String, shot: Image, names: Array, dest: Vector2i) -> void:
	var r := _cmp_stack(shot, names, dest)
	_report("%s %s" % [label, names], r[0], r[1], r[2])


func _t(name: String) -> Texture2D:
	return load("res://art/generated/%s.png" % name)


func _b(name: String) -> Texture2D:
	return load("res://art/bricks40/%s.png" % name)


## 依 D31 規格算出某格應該疊哪些圖(不看程式碼裡的 brick_art,自己算)。
func _expected_stack(layers: int, unbreakable: bool, marked: bool, hit_row: int, invincible: bool, mark_frame: String) -> Array:
	var colors := ["red", "orange", "yellow", "green", "blue", "indigo", "purple"]
	if unbreakable:
		return ["d31_brick_unbreakable_hit" if hit_row >= 0 else "d31_brick_unbreakable"]
	var out := []
	var shown := hit_row + 1 if hit_row >= 0 else layers
	var digit := (shown - 1) / 7
	if marked and hit_row < 0:
		digit = 0   # 標記:同色第 0 輪
	out.append("d31_brick_hit" if hit_row >= 0 else "d31_brick_" + colors[(shown - 1) % 7])
	if digit > 0:
		out.append("d31_digit_%d" % digit)
	if invincible:
		out.append("d31_invincible_frame")
	if marked:
		out.append(mark_frame)
	return out


func _verify(shot: Image, invincible: bool) -> void:
	var tag := " (invincible)" if invincible else ""
	for cs in _cases:
		var cell: Vector2i = cs[0]
		var dest := Vector2i(_m._cell_rect(cell).position)
		_check_stack("cell %s L%d%s" % [cell, cs[1], tag], shot, _expected_stack(cs[1], cs[2], cs[3], cs[4], invincible, "d31_bomb_mark_f1"), dest)
	# 破壞動畫:第 0 幀閃白 + 扣層前數字;F1~F3 依顏色、不疊數字;F4 灰塵(破壞中的格子不畫無敵外框)
	var colors := ["red", "orange", "yellow", "green", "blue", "indigo", "purple"]
	for b in BREAKS:
		var f := int(b[1] / 0.06)
		var names := []
		if f == 0:
			names = ["d31_brick_hit"]
			if b[2] / 7 > 0:
				names.append("d31_digit_%d" % (b[2] / 7))
		elif f < 4:
			names = ["d31_brick_%s_f%d" % [colors[b[3]], f]]
		else:
			names = ["d31_brick_dust_f4"]
		_check_stack("break t=%.2f frame %d%s" % [b[1], f, tag], shot, names, Vector2i(_m._cell_rect(b[0]).position))
	if invincible:
		return
	# 球、光暈(2 倍)
	for b in _m.balls:
		var bp := Vector2i((b.pos - Vector2(8, 8)).floor())
		_check("ball at %s" % b.pos, shot, _t("d15_ball_normal"), Rect2i(0, 0, 8, 8), bp, 2)
	var halo := _t("d15_ball_opt_c_halo_f1")
	var hb = _m.balls[0]
	# 光暈在球之下:只比對球 16×16 以外的部分(以裁切上下兩條邊檢查)
	var hp := Vector2i((hb.pos - Vector2(14, 14)).floor())
	_check("halo top band", shot, halo, Rect2i(0, 0, 14, 3), hp, 2)
	_check("halo bottom band", shot, halo, Rect2i(0, 11, 14, 3), hp + Vector2i(0, 22), 2)
	# 擋板(85,槍)2 倍
	var len: int = _m._paddle_len()
	var left: int = _m._paddle_left(len)
	var py: int = _m._paddle_y()
	print("INFO paddle len %d left %d py %d view_h %d" % [len, left, py, _m.view_h])
	# 85、paddle_x 180 → 左緣 round(137.5) = 138,中段 1 整段 + 裁切 21 px
	if len != 85 or left != 138:
		_report("paddle len 85 at left 138 (got len %d left %d)" % [len, left], 1, 1, "")
	_check_paddle(shot, "gun", len, left, py)
	for gl in [left, left + len - 16]:
		_check("muzzle flash at %d" % gl, shot, _t("d19_gun_muzzle_flash_f1"), Rect2i(0, 0, 8, 4), Vector2i(gl, py - 16), 2)
	_check("bullet 4x8 at 1x", shot, _t("d19_bullet_laser_f1"), Rect2i(0, 0, 4, 8), Vector2i(150, 600), 1)


## D13 擋板組裝(2 倍):左端 16 + 中段 32 × n + 裁切 rest + 右端 16;kind = "gun" 時兩端換槍端(高 24、上移 8)。
func _check_paddle(shot: Image, kind: String, len: int, left: int, py: int) -> void:
	var end_h := 12 if kind == "gun" else 8
	var end_y := py - 8 if kind == "gun" else py
	_check("%s end left" % kind, shot, _t("d13_paddle_%s_left" % kind), Rect2i(0, 0, 8, end_h), Vector2i(left, end_y), 2)
	_check("%s end right" % kind, shot, _t("d13_paddle_%s_right" % kind), Rect2i(0, 0, 8, end_h), Vector2i(left + len - 16, end_y), 2)
	var mid := _t("d13_paddle_normal_mid")
	var full := (len - 32) / 32
	for i in full:
		_check("%s paddle mid %d" % [kind, i], shot, mid, Rect2i(0, 0, 16, 8), Vector2i(left + 16 + 32 * i, py), 2)
	var rest := (len - 32) % 32
	if rest > 0:
		_check("%s paddle cropped mid (%d px)" % [kind, rest], shot, mid, Rect2i(0, 0, 16, 8), Vector2i(left + 16 + 32 * full, py), 2, null, rest)


## 擋板外側 2 欄(左緣左邊、右端右邊)在擋板列上必須和「擋板隱形」時的畫面一樣:擋板沒有多畫或少畫。
func _check_paddle_outside(shot: Image, bg: Image, len: int, left: int, py: int) -> void:
	var bad := 0
	var checked := 0
	var first := ""
	for y in range(py, py + 16):
		for x in [left - 2, left - 1, left + len, left + len + 1]:
			checked += 1
			var a := shot.get_pixel(x, y)
			var b := bg.get_pixel(x, y)
			if not a.is_equal_approx(b):
				bad += 1
				if first == "":
					first = "(%d, %d) shot %s bg %s" % [x, y, a.to_html(false), b.to_html(false)]
	_report("paddle %d px: nothing drawn outside x %d..%d" % [len, left, left + len - 1], bad, checked, first)
	# 擋板內側最外 1 欄必須有畫(與隱形時不同的像素至少 1 個)
	for x in [left, left + len - 1]:
		var diff := 0
		for y in range(py, py + 16):
			if not shot.get_pixel(x, y).is_equal_approx(bg.get_pixel(x, y)):
				diff += 1
		_report("paddle column x %d is drawn" % x, 0 if diff > 0 else 1, 16, "" if diff > 0 else "no paddle pixel")


var _normal_shot: Image


## 動態炸彈標記(reduced_motion 關):截到的那一幀必須整格吻合 F1 或 F2 其中之一。
func _verify_mark_anim(shot: Image) -> void:
	var dest := Vector2i(_m._cell_rect(Vector2i(4, 0)).position)
	var r1 := _cmp_stack(shot, ["d31_brick_orange", "d31_bomb_mark_f1"], dest)
	var r2 := _cmp_stack(shot, ["d31_brick_orange", "d31_bomb_mark_f2"], dest)
	var k := "f1" if r1[0] == 0 else ("f2" if r2[0] == 0 else "none")
	_mark_seen[k] = _mark_seen.get(k, 0) + 1


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		print("INFO viewport %s view_h %d reduced_motion %s" % [root.get_visible_rect().size, _m.view_h, _m.reduced_motion])
		_setup()
	if _frame == 12:
		var shot := root.get_texture().get_image()
		shot.save_png(_out.path_join("qa_bricks40_render.png"))
		_verify(shot, false)
		_m.effects.add_timed("invincible", 999.0)
	if _frame == 18:
		var shot := root.get_texture().get_image()
		shot.save_png(_out.path_join("qa_bricks40_render_invincible.png"))
		_verify(shot, true)
		_m.effects.timed.erase("invincible")
		_m.reduced_motion = false
		_m.effects.timed.erase("gun")   # 下一張截圖檢查一般擋板(非槍端)
	if _frame == 24:
		var len: int = _m._paddle_len()
		var left: int = _m._paddle_left(len)
		var py: int = _m._paddle_y()
		_normal_shot = root.get_texture().get_image()
		_normal_shot.save_png(_out.path_join("qa_paddle85_normal.png"))
		_check_paddle(_normal_shot, "normal", len, left, py)
		_m.effects.add_timed("invisible", 999.0)   # invisible_alpha 0 → 擋板不畫,當背景對照
	if _frame == 30:
		var bg := root.get_texture().get_image()
		_check_paddle_outside(_normal_shot, bg, _m._paddle_len(), _m._paddle_left(_m._paddle_len()), _m._paddle_y())
	if _frame >= 36 and _frame < 96:
		var shot := root.get_texture().get_image()
		_verify_mark_anim(shot)
		if _frame == 50 or _frame == 60:
			shot.save_png(_out.path_join("qa_bricks40_mark_anim_%d.png" % _frame))
	if _frame == 96:
		print("INFO animated bomb mark frames seen over 60 captures: %s (expect F1 ~60%%, F2 ~40%%)" % [_mark_seen])
		if _mark_seen.has("f1") and _mark_seen.has("f2") and not _mark_seen.has("none"):
			_pass += 1
			print("OK   animated bomb mark: both F1 and F2 drawn exactly, no other frame")
		else:
			_fail += 1
			print("FAIL animated bomb mark: %s" % [_mark_seen])
		print("QA 2X CAPTURE RESULT: %d passed, %d failed" % [_pass, _fail])
		quit(1 if _fail > 0 else 0)
		return true
	return false
