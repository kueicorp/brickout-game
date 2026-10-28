## QA 重測:槍的說明文字(D29 表格 item_gun 列,以代號搜尋)與 3 選 1 讀屏標籤。
## 執行:Godot --headless --path game --script res://tests/qa_gun_text_test.gd
## 全部通過時結束碼 0,有失敗時結束碼 1。
extends SceneTree

const DOC := "../docs/design/ui-menus.md"
# 2026-10-28 道具秒數修訂:第 1 行合併為「點畫面，兩端各射1發」,新增第 3 行秒數(dur_gun = 10)
const GUN := ["點畫面，兩端各射1發", "減1層 不觸發功能磚", "持續10秒"]
const GUN_RAW := ["點畫面，兩端各射1發", "減1層 不觸發功能磚", "持續{dur_gun}秒"]

var _passed := 0
var _failed := 0
var _section := ""
var _started := false


func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	_run("gun_text_literal", _t_literal)
	_run("gun_text_doc_row", _t_doc_line)
	_run("gun_text_space_codepoint", _t_space)
	_run("other_items_unchanged", _t_others)
	_run("gun_menu_a11y", _t_a11y)
	_run("gun_line_width_info", _t_width)
	print("QA GUN RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
	return false


func _run(name: String, f: Callable) -> void:
	_section = name
	f.call()


func _eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		print("FAIL [%s] %s: expected %s, got %s" % [_section, label, expected, actual])


func _ok(cond: bool, label: String) -> void:
	_eq(cond, true, label)


func _t_literal() -> void:
	_eq(ItemDefs.item_name("gun"), "槍", "name")
	_eq(ItemDefs.TEXT["gun"][1], GUN_RAW, "raw TEXT")
	_eq(ItemDefs.desc_lines("gun"), GUN, "desc_lines")
	_eq(ItemDefs.desc_lines("gun").size(), 3, "3 lines")


func _t_doc_line() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join(DOC).simplify_path()
	var f := FileAccess.open(path, FileAccess.READ)
	_ok(f != null, "open doc")
	if f == null:
		return
	var lines := f.get_as_text().split("\n")
	# D29 修訂後行號會位移:改用代號 item_gun 找表格那一列(必須剛好 1 列)
	var hits := []
	for i in lines.size():
		if lines[i].strip_edges().begins_with("| `item_gun` |"):
			hits.append(i)
	_eq(hits.size(), 1, "exactly one item_gun table row (lines %s)" % [hits.map(func(i): return i + 1)])
	if hits.is_empty():
		return
	var row := lines[hits[0]].strip_edges()
	_ok(row.begins_with("| `item_gun` |"), "line %d is item_gun row: %s" % [hits[0] + 1, row])
	var cols := row.split("|")
	_eq(cols[2].strip_edges(), "槍", "doc name")
	_eq(Array(cols[3].strip_edges().split("｜")), ItemDefs.desc_lines("gun"), "doc desc == ItemDefs")
	_eq(int(cols[5].strip_edges().replace("*", "")), 3, "doc line count")


func _t_space() -> void:
	var s: String = ItemDefs.desc_lines("gun")[1]
	var i := s.find("層")
	_eq(s.unicode_at(i + 1), 0x20, "char after 層 is U+0020")
	_eq(s.count(" "), 1, "exactly one half-width space")
	_ok(not s.contains("　") and not s.contains(" "), "no full-width / nbsp space")
	for l in ItemDefs.desc_lines("gun"):
		_eq(l, l.strip_edges(), "no leading/trailing spaces: %s" % l)


## 其他 25 個道具文字的快照(預設設定,2026-10-28 道具秒數修訂後);槍以外任何改動都會失敗。
## 「擋板最大化」已移除,不得再出現在 TEXT。
func _t_others() -> void:
	var expect := {
		"paddle_len_1": ["擋板小幅增加", ["長度變成1.2倍", "持續30秒"]],
		"paddle_len_2": ["擋板大幅增加", ["長度變成1.6倍", "持續30秒"]],
		"pierce": ["穿透", ["穿過磚塊並減1層", "持續20秒"]],
		"flame": ["火焰", ["撞到的磚塊減2層", "周圍一圈減1層", "持續20秒"]],
		"bomb": ["炸彈", ["撞到的磚塊被標記", "10秒後全部爆炸"]],
		"slow": ["減速", ["球速下降1階"]],
		"split": ["分裂", ["場上的球變2倍"]],
		"reinforce": ["強化", ["每次撞磚多減1層", "最多加7層"]],
		"sticky": ["吸附", ["球碰到擋板會黏住", "點一下才發射", "持續30秒"]],
		"golden_ball": ["金球", ["三選一"]],
		"paddle_speed": ["擋板移動速度增加", ["移動速度上升1階"]],
		"paddle_len_down_1": ["擋板小幅減少", ["長度變成0.8倍", "持續30秒"]],
		"paddle_len_down_2": ["擋板大幅減少", ["長度變成0.4倍", "持續30秒"]],
		"paddle_len_min": ["擋板最短化", ["縮到最短，持續30秒"]],
		"fast": ["加速", ["球速上升1階"]],
		"paddle_speed_down": ["擋板移動速度減少", ["移動速度下降1階"]],
		"merge": ["融合", ["場上的球減半"]],
		"heal": ["回血", ["撞到的磚塊加1層", "持續10秒"]],
		"heal_area": ["範圍回血", ["撞到的磚塊加2層", "周圍一圈加1層", "持續10秒"]],
		"blackhole": ["黑洞", ["球碰到擋板就消失", "持續5秒"]],
		"blackhole_big": ["大黑洞", ["全場的球只剩1顆"]],
		"invincible": ["無敵", ["所有磚塊無法破壞", "魔王除外，持續10秒"]],
		"invisible": ["隱形", ["擋板變成透明", "持續10秒"]],
		"thief": ["小偷", ["偷走500到5000分", "分數最低到0"]],
		"black_ball": ["黑球", ["三選一"]],
	}
	_eq(ItemDefs.TEXT.size(), 26, "TEXT has 26 ids")
	_ok(not ItemDefs.TEXT.has("paddle_len_max"), "paddle_len_max removed from TEXT")
	for id in expect:
		_eq([ItemDefs.item_name(id), ItemDefs.desc_lines(id)], expect[id], "unchanged %s" % id)
	_eq(ItemDefs.BUFF.size() + ItemDefs.DEBUFF.size(), 26, "id lists size")
	_ok(ItemDefs.is_buff("gun"), "gun still buff")


func _t_a11y() -> void:
	var menu := ChoiceMenu.new()
	menu.setup(true, ["slow", "gun", "split"], 800, false)
	root.add_child(menu)
	var names := []
	for o in menu._options:
		names.append(o.accessibility_name)
	_eq(names[1], "槍，點畫面，兩端各射1發，減1層 不觸發功能磚，持續10秒，按兩下選擇", "gun a11y label")
	_eq(names[0], "減速，球速下降1階，按兩下選擇", "neighbour label unaffected")
	for n in names:
		_ok(not n.contains("雷射"), "no old wording: %s" % n)
	menu.free()


## 只印出寬度資訊(目前是預設字型,不列入通過/失敗);選項文字區寬 216 px(D29 修訂)。
## 實際寬度驗收在 qa_durations_hud_test.gd(用選單實際字型)。
func _t_width() -> void:
	var font := ThemeDB.fallback_font
	for l in ItemDefs.desc_lines("gun"):
		print("INFO gun line width (fallback font, 22px): %s -> %d px (limit 216)" % [l, int(font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x)])
