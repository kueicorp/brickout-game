## QA 視窗短測(非 headless):D32 掉落道具 40×40 與接取閃光 48×48(art/items40)。
## - 27 種道具 F1(減少動態)、F2(動態時截到的 F2 幀)以 1 倍逐像素對照原圖;位置 = 磚中心 − 20(含小數 pos)。
## - 閃光 F1~F3 逐像素對照原圖(半透明像素依背景混色比對);中心 = 道具中心。
## - 呼吸:F1、F2 各 400 ms 共用時鐘(每幀截圖對照繪圖當下的 ticks);減少動態時固定 F1。
## - 道具以外的畫面不多畫(和背景截圖比對)。
## 執行:Godot --path game --script res://tests/qa_window_items40_capture.gd -- <輸出資料夾>
## 跑完自動關閉;全部吻合時結束碼 0。
extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainScript := preload("res://scripts/main.gd")


## 掛在 main 最後面的節點:記錄每次繪圖當下的 ticks(與道具圖層同一幀繪圖)
class TickProbe:
	extends Node2D
	var last_ms := -1
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		last_ms = Time.get_ticks_msec()


var _m
var _probe: TickProbe
var _frame := 0
var _out := ""
var _fail := 0
var _pass := 0
var _base: Image
var _slots := []      # [id, pos]
var _flashes := []    # [frame 1~3, item pos]
var _phase_ok := 0
var _phase_edge := 0  # 換幀邊界 ±5 ms 內的不一致(繪圖與 ticks 取樣時間差),不算失敗
var _phase_bad := 0
var _phase_seen := {}
var _saved_f2 := false
var _rm_seen := {}
var _first_bad := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else OS.get_user_data_dir()
	_m = MainScene.instantiate()
	root.add_child(_m)
	_probe = TickProbe.new()
	_m.add_child(_probe)


func _img(name: String) -> Image:
	var i: Image = (load("res://art/items40/%s.png" % name) as Texture2D).get_image()
	if i.is_compressed():
		i.decompress()
	i.convert(Image.FORMAT_RGBA8)
	return i


func _report(label: String, ok: bool, detail := "") -> void:
	if ok:
		_pass += 1
		print("OK   %-56s %s" % [label, detail])
	else:
		_fail += 1
		print("FAIL %-56s %s" % [label, detail])


## src 以 1 倍畫在 dest:不透明像素須完全相同;透明像素須等於背景;半透明依背景混色(容差 2/255)。
## 回傳 [bad, opaque, partial, first]
func _cmp(shot: Image, src: Image, dest: Vector2i) -> Array:
	var bad := 0
	var opaque := 0
	var partial := 0
	var first := ""
	for y in src.get_height():
		for x in src.get_width():
			var p := dest + Vector2i(x, y)
			var c := src.get_pixel(x, y)
			var bg := _base.get_pixelv(p)
			var want := c
			if c.a == 0.0:
				want = bg
			elif c.a < 0.999:
				partial += 1
				want = bg.lerp(Color(c.r, c.g, c.b, 1.0), c.a)
			else:
				opaque += 1
			var g := shot.get_pixelv(p)
			var tol := 0.004 if c.a >= 0.999 or c.a == 0.0 else 0.008
			if absf(g.r - want.r) > tol or absf(g.g - want.g) > tol or absf(g.b - want.b) > tol:
				bad += 1
				if first == "":
					first = "%s want %s got %s (src a %.2f)" % [p, want.to_html(false), g.to_html(false), c.a]
	return [bad, opaque, partial, first]


func _item_dest(pos: Vector2) -> Vector2i:
	return Vector2i(_m._item_rect(pos.floor()).position)


func _setup() -> void:
	for r in _m.grid.size():
		for c in _m.grid[r].size():
			_m.grid[r][c] = null
	_m.breakable_left = 99
	_m.items.clear()
	_m.anims.clear()
	_m.bullets.clear()
	_m.balls.clear()
	_m.state = 1           # 凍結遊戲推進(不呼叫 _end),只為截圖
	_m.reduced_motion = true


func _place() -> void:
	var ids: Array = ItemDefs.BUFF + ItemDefs.DEBUFF
	for k in ids.size():
		var cell := Vector2i(k % 8, (k / 8) * 2)   # 第 0、2、4、6 排;含最左、最右欄
		var pos: Vector2 = _m._cell_rect(cell).get_center() - Vector2(8, 8)
		_slots.append([ids[k], pos])
	# 小數位置(掉落中):畫在 floor(pos) − 12
	_slots.append(["slow", _m._cell_rect(Vector2i(6, 8)).get_center() - Vector2(8, 8) + Vector2(0.6, 0.45)])
	for s in _slots:
		_m.items.append({"id": s[0], "pos": s[1]})
	# 閃光 3 幀(凍結 t):第 10 排第 1、3、5 欄;位置走正式程式 _pickup
	var ts := [0.03, 0.09, 0.15]
	for i in 3:
		var p: Vector2 = _m._cell_rect(Vector2i(1 + 2 * i, 11)).get_center() - Vector2(8, 8)
		_m.state = 0
		_m._pickup("slow", p)
		_m.state = 1
		_m.anims[-1]["t"] = ts[i]
		_m.anims[-1]["dur"] = 999.0
		_flashes.append([i + 1, p])
	# _pickup 會套用減速、加分;還原,讓 HUD 與分數和背景截圖一樣
	_m.effects.ball_tier = 0
	_m.score = 0


## frame_n:1 或 2;回傳是否全部道具都吻合該幀。verbose 時逐項回報
func _check_items(shot: Image, frame_n: int, verbose: bool) -> bool:
	var all_ok := true
	for s in _slots:
		var r := _cmp(shot, _img("d32_item_%s_f%d" % [s[0], frame_n]), _item_dest(s[1]))
		var ok: bool = r[0] == 0 and r[1] > 0
		all_ok = all_ok and ok
		if verbose:
			_report("item %s F%d at %s (pos %s)" % [s[0], frame_n, _item_dest(s[1]), s[1]], ok, "%d opaque, %d partial px; %d differ %s" % [r[1], r[2], r[0], r[3]])
	return all_ok


func _check_flashes(shot: Image) -> void:
	for f in _flashes:
		var ap: Vector2 = (f[1] - Vector2(16, 16)).floor()
		var dest := Vector2i(ap)
		var r := _cmp(shot, _img("d32_item_pickup_f%d" % f[0]), dest)
		var center := Vector2(dest) + Vector2(24, 24)
		var item_center: Vector2 = _m._item_rect((f[1] as Vector2).floor()).get_center()
		_report("pickup flash F%d at %s" % [f[0], dest], r[0] == 0 and r[1] > 0, "%d opaque, %d partial px; %d differ %s" % [r[1], r[2], r[0], r[3]])
		_report("pickup flash F%d center %s == item center %s" % [f[0], center, item_center], center == item_center)


## 道具與閃光範圍以外,畫面必須和背景一樣
func _check_outside(shot: Image) -> void:
	var rects: Array[Rect2i] = []
	for s in _slots:
		rects.append(Rect2i(_item_dest(s[1]), Vector2i(40, 40)))
	for f in _flashes:
		rects.append(Rect2i(Vector2i(((f[1] as Vector2) - Vector2(16, 16)).floor()), Vector2i(48, 48)))
	var bad := 0
	var first := ""
	for y in shot.get_height():
		for x in shot.get_width():
			var inside := false
			for r in rects:
				if r.has_point(Vector2i(x, y)):
					inside = true
					break
			if inside:
				continue
			if not shot.get_pixel(x, y).is_equal_approx(_base.get_pixel(x, y)):
				bad += 1
				if first == "":
					first = "(%d, %d)" % [x, y]
	_report("nothing drawn outside item/flash rects", bad == 0, "%d px differ %s" % [bad, first])


func _classify(shot: Image) -> String:
	if _check_items(shot, 1, false):
		return "f1"
	if _check_items(shot, 2, false):
		return "f2"
	return "none"


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		print("INFO viewport %s view_h %d" % [root.get_visible_rect().size, _m.view_h])
		_setup()
	if _frame == 8:
		_base = root.get_texture().get_image()
		_base.convert(Image.FORMAT_RGBA8)
		_base.save_png(_out.path_join("qa_items40_base.png"))
		_place()
	if _frame == 14:
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGBA8)
		shot.save_png(_out.path_join("qa_items40_f1_flash.png"))
		_check_items(shot, 1, true)
		_check_flashes(shot)
		_check_outside(shot)
		_m.reduced_motion = false
	# 動態:約 2 秒每幀截圖,對照繪圖當下的 ticks(上一幀繪圖 = 這一幀拿到的截圖)
	if _frame >= 16 and _frame < 136:
		var ms: int = _probe.last_ms
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGBA8)
		var k := _classify(shot)
		_phase_seen[k] = _phase_seen.get(k, 0) + 1
		var ph := fmod(ms / 1000.0, 0.8)
		var want := "f2" if ph >= 0.4 else "f1"
		var near_edge := absf(ph - 0.4) * 1000.0 <= 5.0 or ph * 1000.0 <= 5.0 or (0.8 - ph) * 1000.0 <= 5.0
		if k == want:
			_phase_ok += 1
		elif near_edge and k != "none":
			_phase_edge += 1
		else:
			_phase_bad += 1
			if _first_bad == "":
				_first_bad = "ms %d phase %.3f want %s got %s" % [ms, ph, want, k]
		if k == "f2" and not _saved_f2:
			_saved_f2 = true
			shot.save_png(_out.path_join("qa_items40_f2.png"))
			_check_items(shot, 2, true)
	if _frame == 136:
		print("INFO blink frames seen: %s; match ticks %d, boundary +-5ms %d, mismatch %d %s" % [_phase_seen, _phase_ok, _phase_edge, _phase_bad, _first_bad])
		_report("blink F1/F2 follow shared 400 ms clock (drawn tick)", _phase_bad == 0 and _phase_seen.has("f1") and _phase_seen.has("f2") and not _phase_seen.has("none"), str(_phase_seen))
		_m.reduced_motion = true
	if _frame >= 140 and _frame < 200:
		var shot := root.get_texture().get_image()
		shot.convert(Image.FORMAT_RGBA8)
		var k := _classify(shot)
		_rm_seen[k] = _rm_seen.get(k, 0) + 1
	if _frame == 200:
		_report("reduced motion: F1 only over 60 frames", _rm_seen.keys() == ["f1"], str(_rm_seen))
		print("QA ITEMS40 CAPTURE RESULT: %d passed, %d failed" % [_pass, _fail])
		quit(1 if _fail > 0 else 0)
		return true
	return false
