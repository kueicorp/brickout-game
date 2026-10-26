extends SceneTree
## 像素圖預覽轉檔工具。
##
## 讀取設計稿 pixel-art-bricks.md:
##   1. 每個 ```text 區塊(一字元 = 一像素)轉成單張 PNG 與 ×8 放大版;
##   2. 依 D12「自動產生規則」與換色對照表，由母版產生各磚種的精靈圖(sprites/);
##      多層磚依 D12「多層磚層數(新規則)」產生 70 種外觀(7 色 ×(無數字 + 數字 1~9))與層數對照表 layer_map.json;
##   3. 依 D17、D18「需轉檔工具新增的自動產生規則」產生功能型磚(數字合成、被擊中、破壞幀)、
##      垂直雷射光束(由水平圖旋轉、鏡射)與彩虹挑色環七色版;
##   3b. 依 D20、D21「F2 規則」由道具 F1 與底板產生各道具的 F2(單張圖 <項目>_<道具 id>_f2,不放進總覽圖);
##   4. 依 D13 拼接規則，由擋板分段拼出各長度、各狀態的擋板圖(sprites/paddle_*.png);
##   5. 產生總覽圖 overview.png 與示意盤面 board_sample.png。
## 調色盤、換色表、被擊中規則、擋板長度與拼接參數從設計稿解析;設計稿標明「寫死在轉檔工具」的規則
## (多層磚數字位置、裂痕範圍、功能型磚數字位置、垂直光束轉換等)寫在下方常數，並以設計稿的範例網格逐像素核對。
## 任何解析或檢查錯誤都會在刪檔、寫檔之前擋下。
##
## 執行方式(不需要 project.godot):
##   Godot_console.exe --headless --script md_to_png.gd -- <md 路徑> <輸出資料夾>
## 一般請用同資料夾的 run.ps1。

const SCALE_SINGLE := 8    # 單張放大版倍率
const SCALE_SPRITE := 6    # 精靈圖放大版倍率
const SCALE_OVERVIEW := 6  # 總覽圖倍率
const SCALE_BOARD := 3     # 示意盤面放大版倍率

const SPRITE_DIR := "sprites"
const RULE_ITEM := "D12"   # 母版與自動產生規則所在的設計稿項目

# 格子尺寸來自 PM 交付的 D12 規格;母版實際尺寸不符時報錯
const CELL_W := 32
const CELL_H := 16
const BOSS_W := 128
const BOSS_H := 48
const DIGIT_COUNT := 10
const DIGIT_W := 5
const DIGIT_H := 7

## 換色時一律不變的字元(換色只替換母版色階代號，此清單用來檢查母版沒有規則外的代號)
const SWAP_KEEP := ["K", "W", "G", "."]
## 寶箱、金幣、圓形的破壞幀色階(D12:寶箱橙、金幣黃、圓形紫維持原外觀)
const FRAME_COLORS := {"寶箱": "橙", "金幣": "黃", "圓形": "紫"}

# ---- D12「多層磚層數(新規則)」:設計稿標明寫死在轉檔工具;欄列從 0 起算
const LAYER_MAX := 69          # 實際使用的最高層數(靛 9)
const ROUND_COUNT := 10        # 輪數 0~9;第 0 輪不畫數字
const MULTI_DIGIT_X := 13      # 數字字形左上角
const MULTI_DIGIT_Y := 4
const MULTI_FILL := "W"        # 字形填色
const MULTI_OUTLINE := "K"     # 字形 8 鄰格描邊
## 有數字的磚要改成 T3 的區域:[x0, x1, y0, y1, 原色階, 新色階](色階 1 起算，含端點)
## 裂痕:第 25~27 欄、第 3~7 列的 T5;磨損：第 12 列第 16~17 欄的 T2
const MULTI_FIXES := [[25, 27, 3, 7, 5, 3], [16, 17, 12, 12, 2, 3]]

# ---- D17 功能型磚(第 1 批):數字 `K` 疊在第 21 欄、第 4 列
const FUNC_ITEM := "D17"
const FUNC_DIGIT_X := 21
const FUNC_DIGIT_Y := 4
const FUNC_DIGIT_INK := "K"
## [底圖 id, 精靈圖檔名, 破壞幀色階(D17 換色表「目標」欄;解析時全形括號已轉半形)]
const FUNC_BRICKS := [
	["laser_brick_h", "brick_laser_h", "雷射(洋紅)"],
	["laser_brick_v", "brick_laser_v", "雷射(洋紅)"],
	["laser_brick_x", "brick_laser_x", "雷射(洋紅)"],
	["lightning_brick", "brick_lightning", "閃電(電青)"],
	["reaper_brick", "brick_reaper", "死神(骨白)"],
]
const FUNC_TIERS := ["雷射(洋紅)", "閃電(電青)", "死神(骨白)"]
## 垂直光束：[輸出 id, 來源 id, 做法];ccw = 逆時針轉 90 度，flip_v = 上下鏡射(來源為已產生的垂直圖)
const BEAM_SIZE := 16
const BEAM_V := [
	["laser_beam_v_mid_thin", "laser_beam_mid_thin", "ccw"],
	["laser_beam_v_mid_full", "laser_beam_mid_full", "ccw"],
	["laser_beam_v_block_up_thin", "laser_beam_block_thin", "ccw"],
	["laser_beam_v_block_up_full", "laser_beam_block_full", "ccw"],
	["laser_beam_v_block_down_thin", "laser_beam_v_block_up_thin", "flip_v"],
	["laser_beam_v_block_down_full", "laser_beam_v_block_up_full", "flip_v"],
]

# ---- D18 功能型磚(第 2 批)
const FUNC2_ITEM := "D18"
## [底圖 id, 精靈圖檔名, 破壞幀色階(D18 換色表「目標」欄)]
const FUNC2_BRICKS := [
	["explosion_brick", "brick_explosion", "爆炸(炸藥褐)"],
	["rainbow_brick", "brick_rainbow", "彩虹(珍珠白)"],
]
const PICK_FRAMES := ["rainbow_pick_f1", "rainbow_pick_f2", "rainbow_pick_f3"]
const PICK_W := 48
const PICK_H := 32

# ---- D20、D21 道具 F2(設計稿標明寫死在轉檔工具):F1 中與底板 F1 同位置、同代號的像素改成底板 F2 同位置的像素
## [設計稿項目, 底板 F1 id, 底板 F2 id];道具 = 該項目中 id 以 item_ 開頭、但不是 item_plate_* 與 item_pickup_* 的區塊
const ITEM_F2_SPECS := [
	["D20", "item_plate_buff_f1", "item_plate_buff_f2"],
	["D21", "item_plate_debuff_f1", "item_plate_debuff_f2"],
]
const ITEM_SIZE := 16

const PADDLE_ITEM := "D13"  # 擋板分段與拼接規則所在的設計稿項目
## 各擋板圖使用的分段 id(左端、中段、右端)。設計稿的「槍」「吸附」「同時有槍與吸附」規則
## 是文字敘述，無法可靠解析成對應表，所以依其內容寫在這裡;同時有槍與吸附為設計師暫定。
const PADDLE_SETS := {
	"paddle_normal": ["paddle_normal_left", "paddle_normal_mid", "paddle_normal_right"],
	"paddle_gun": ["paddle_gun_left", "paddle_normal_mid", "paddle_gun_right"],
	"paddle_sticky": ["paddle_sticky_left", "paddle_sticky_mid", "paddle_sticky_right"],
	"paddle_gun_sticky": ["paddle_gun_left", "paddle_sticky_mid", "paddle_gun_right"],
}
## 用來對照的完整圖 id:由規則拼出的同長度擋板必須與它逐像素相同，否則視為設計稿矛盾
const PADDLE_REFERENCE := {"paddle_normal": "paddle_normal_64", "paddle_gun": "paddle_gun_64", "paddle_sticky": "paddle_sticky_64"}
const ID_RE := "^[a-z0-9_]+$"

## 一般磚精靈圖的列順序(紅橙黃綠藍靛紫),名稱需與換色對照表「目標」欄一致
const COLOR_ORDER := ["紅", "橙", "黃", "綠", "藍", "靛", "紫"]
## 檔名用的顏色英文代稱
const COLOR_SLUG := {"紅": "red", "橙": "orange", "黃": "yellow", "綠": "green", "藍": "blue", "靛": "indigo", "紫": "violet"}
## 標題中的磚種 → 檔名片段
const SUBJECT_SLUG := {"一般磚": "brick", "寶箱": "chest", "金幣": "coin", "圓形": "round", "魔王": "boss"}

const OVERVIEW_WIDTH := 1440
const OVERVIEW_MARGIN := 24
const OVERVIEW_GAP_X := 24
const OVERVIEW_GAP_Y := 20
const OVERVIEW_SECTION_GAP := 36
const LABEL_SCALE := 2     # 檔名標籤：3×5 字放大 2 倍
const HEADER_SCALE := 4    # 區塊標題(D12 等)放大 4 倍

const BG_COLOR := Color8(0x10, 0x10, 0x18, 255)      # 總覽圖與盤面背景(深色)
const FRAME_COLOR := Color8(0x24, 0x24, 0x34, 255)   # 總覽圖每張圖的底框，用來看出透明範圍
const BORDER_COLOR := Color8(0x3A, 0x38, 0x58, 255)  # 盤面左右邊框的暫用單色(邊框美術不在設計稿)
const TEXT_COLOR := Color8(0xC8, 0xC8, 0xD8, 255)
const HEADER_COLOR := Color8(0xF0, 0xF0, 0xFF, 255)

const BOARD_W := 360
const BOARD_H := 640
const BOARD_BORDER := 20   # 左右邊框寬
const BOARD_COLS := 10
const BOARD_TOP := 48      # 上方預留給 HUD 的空間，只是示意
const BOARD_PADDLE_LEN := 64   # 示意盤面的擋板長度(基準長度)
const BOARD_PADDLE_Y := 600    # 擋板上緣 y;離畫布底 32 px,示意球拍位置

## 示意盤面(10 欄)。每格一個代號，以空白分隔：
##   R O Y G B I V = 一般磚紅橙黃綠藍靛紫(= 多層磚層 1~7);數字 1~69 = 多層磚層數;C = 寶箱;$ = 金幣;
##   @ = 圓形;X = 魔王左上角(佔 4×3 格;置中須放在從 0 起算的第 3 欄，即 D12 的「第 4~7 欄」);- = 被魔王覆蓋;. = 空格
const BOARD_LAYOUT := [
	"R O Y X - - - G B I",
	"V R O - - - - Y G B",
	"I V R - - - - O Y G",
	"8 9 10 C 12 $ 20 24 61 69",
	"B I V @ R @ O Y G R",
	"G C Y 15 16 17 Y $ O V",
	"R O Y G B I V R O Y",
	". 32 . 40 @ 48 . 55 . 66",
	"Y G B I V R O Y G B",
	". . C . $ . @ . . .",
]
const BOARD_COLOR_TOKENS := {"R": "紅", "O": "橙", "Y": "黃", "G": "綠", "B": "藍", "I": "靛", "V": "紫"}

## 自繪 3×5 像素字，只用於標籤(避免依賴字型檔)。
## 調色盤代號大小寫有別(如 H 與 h),所以小寫另畫一套。
const FONT := {
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["###", "..#", "###", "#..", "###"],
	"3": ["###", "..#", "###", "..#", "###"],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "###", "..#", "###"],
	"6": ["###", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "###"],
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"],
	"N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "##.", ".##"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	"a": ["...", ".##", "#.#", "#.#", ".##"],
	"b": ["#..", "##.", "#.#", "#.#", "##."],
	"c": ["...", ".##", "#..", "#..", ".##"],
	"d": ["..#", ".##", "#.#", "#.#", ".##"],
	"e": ["...", ".#.", "###", "#..", ".##"],
	"f": [".##", "#..", "###", "#..", "#.."],
	"g": [".##", "#.#", ".##", "..#", "##."],
	"h": ["#..", "##.", "#.#", "#.#", "#.#"],
	"i": [".#.", "...", ".#.", ".#.", ".#."],
	"j": ["..#", "...", "..#", "#.#", ".#."],
	"k": ["#..", "#.#", "##.", "##.", "#.#"],
	"l": ["##.", ".#.", ".#.", ".#.", "###"],
	"m": ["...", "##.", "###", "#.#", "#.#"],
	"n": ["...", "##.", "#.#", "#.#", "#.#"],
	"o": ["...", ".#.", "#.#", "#.#", ".#."],
	"p": ["...", "##.", "#.#", "##.", "#.."],
	"q": ["...", ".##", "#.#", ".##", "..#"],
	"r": ["...", "#.#", "##.", "#..", "#.."],
	"s": ["...", ".##", ".#.", "..#", "##."],
	"t": [".#.", "###", ".#.", ".#.", "..#"],
	"u": ["...", "#.#", "#.#", "#.#", ".##"],
	"v": ["...", "#.#", "#.#", "#.#", ".#."],
	"w": ["...", "#.#", "#.#", "###", "###"],
	"x": ["...", "#.#", ".#.", ".#.", "#.#"],
	"y": ["...", "#.#", "#.#", ".##", "##."],
	"z": ["...", "###", ".##", "#..", "###"],
	"_": ["...", "...", "...", "...", "###"],
	"-": ["...", "...", "###", "...", "..."],
	".": ["...", "...", "...", "...", ".#."],
	" ": ["...", "...", "...", "...", "..."],
}

# 全形標點：設計稿用全形冒號、括號、波浪號、頓號;用跳脫序列寫明，避免編輯器轉成半形
const FW_COLON := "\uFF1A"
const FW_LPAREN := "\uFF08"
const FW_RPAREN := "\uFF09"
const RE_TILDE := "[~\uFF5E\u301C]"
const RE_COMMA := "[,\u3001\uFF0C]"
const RE_LPAREN := "[(\uFF08]"
const RE_RPAREN := "[)\uFF09]"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("用法: --headless --script md_to_png.gd -- <pixel-art-bricks.md> <輸出資料夾>")
		quit(2)
		return
	var err := run(args[0], args[1])
	quit(err)


## 主流程。回傳 0 表示成功，非 0 表示失敗(錯誤訊息已印出)。
func run(md_path: String, out_dir: String) -> int:
	var f := FileAccess.open(md_path, FileAccess.READ)
	if f == null:
		printerr("讀不到設計稿: %s (%s)" % [md_path, error_string(FileAccess.get_open_error())])
		return 1
	var lines := f.get_as_text().replace("\r\n", "\n").split("\n")
	f.close()

	# 所有可能失敗的檢查(調色盤、區塊結構、檔名、網格、規則解析、精靈圖產生、盤面配置)
	# 都在清檔與寫檔之前完成;任何錯誤都不刪、不寫檔案，避免預覽資料夾變成一半新一半舊
	var errors := PackedStringArray()
	var palette := parse_palette(lines)
	if palette.is_empty():
		errors.append("D01 調色盤表格解析失敗或為空")
	var blocks := parse_blocks(lines, errors)
	if blocks.is_empty() and errors.is_empty():
		errors.append("找不到任何 ```text 區塊")
	for b in blocks:
		var msg := validate_grid(b["grid"], palette)
		if msg != "":
			errors.append("%s (設計稿第 %d 行): %s" % [b["name"], b["line"], msg])

	var sheets := {}
	var layer_map := {}
	var beam_layout := {}
	var item_f2 := {}  # 輸出檔名(不含副檔名)-> 網格
	if errors.is_empty():
		var rules := parse_rules(section_lines(lines, RULE_ITEM), palette, errors)
		if errors.is_empty():
			parse_func_rules(lines, palette, rules, errors)
		if errors.is_empty():
			sheets = build_sprite_sheets(blocks, rules, palette, errors)
		if errors.is_empty():
			var fsheets := build_func_sheets(blocks, rules, palette, errors)
			for k in fsheets:
				sheets[k] = fsheets[k]
			layer_map = build_layer_map()
			beam_layout = build_beam_layout(blocks)
		# 擋板規則與磚塊規則各自獨立，兩邊的錯誤一起列出
		var prules := parse_paddle_rules(section_lines(lines, PADDLE_ITEM), errors)
		if not prules.is_empty():
			var psheets := build_paddle_sheets(blocks, prules, palette, errors)
			for k in psheets:
				sheets[k] = psheets[k]
		# 道具 F2 只依賴 D20、D21 的網格，錯誤與上面的規則一起列出
		item_f2 = build_item_f2(blocks, errors)
	errors.append_array(check_board_requirements())
	if not errors.is_empty():
		for e in errors:
			printerr(e)
		printerr("有 %d 個錯誤，未變動任何輸出檔" % errors.size())
		return 1

	var sprite_dir := out_dir.path_join(SPRITE_DIR)
	DirAccess.make_dir_recursive_absolute(sprite_dir)
	clean_old_outputs(out_dir, sprite_dir)

	var images := {}  # name -> 原尺寸 Image
	for b in blocks:
		var img := render_grid(b["grid"], palette)
		images[b["name"]] = img
		if save(img, out_dir.path_join(b["name"] + ".png")) != OK:
			return 1
		if save(scaled(img, SCALE_SINGLE), out_dir.path_join("%s_x%d.png" % [b["name"], SCALE_SINGLE])) != OK:
			return 1
		print("%-26s %dx%d" % [b["name"], img.get_width(), img.get_height()])

	# 道具 F2:與單張圖同處、同樣附 ×8,但不放進 overview.png(不加入 images)
	for name in item_f2:
		var img := render_grid(item_f2[name], palette)
		if save(img, out_dir.path_join(name + ".png")) != OK:
			return 1
		if save(scaled(img, SCALE_SINGLE), out_dir.path_join("%s_x%d.png" % [name, SCALE_SINGLE])) != OK:
			return 1
		print("%-26s %dx%d" % [name, img.get_width(), img.get_height()])

	for sheet_name in sheets:
		var img := render_grid(sheets[sheet_name]["grid"], palette)
		if save(img, sprite_dir.path_join(sheet_name + ".png")) != OK:
			return 1
		if save(scaled(img, SCALE_SPRITE), sprite_dir.path_join("%s_x%d.png" % [sheet_name, SCALE_SPRITE])) != OK:
			return 1
		print("%-26s %dx%d" % [SPRITE_DIR + "/" + sheet_name, img.get_width(), img.get_height()])

	# 對照資料(給遊戲程式用):層數 → (顏色, 數字)、雷射光束分段尺寸與鏡射方式
	for pair in [["layer_map.json", layer_map], ["laser_beam_layout.json", beam_layout]]:
		if save_json(pair[1], sprite_dir.path_join(pair[0])) != OK:
			return 1
		print("%-26s" % [SPRITE_DIR + "/" + pair[0]])

	if save(build_overview(blocks, images, palette), out_dir.path_join("overview.png")) != OK:
		return 1

	var board := build_board(sheets, palette)
	if save(board, out_dir.path_join("board_sample.png")) != OK:
		return 1
	if save(scaled(board, SCALE_BOARD), out_dir.path_join("board_sample_x%d.png" % SCALE_BOARD)) != OK:
		return 1

	print("完成：%d 個區塊、%d 張道具 F2、%d 張精靈圖，輸出到 %s" % [blocks.size(), item_f2.size(), sheets.size(), out_dir])
	return 0


# ---------------------------------------------------------------- 解析：調色盤與區塊

## 從 D01 段落的表格讀調色盤。回傳 {字元: Color};`.` 對應全透明。
## 只看 D01 段落，因為其他段落(如換色表)也有「`R`」樣式的欄位。
func parse_palette(lines: PackedStringArray) -> Dictionary:
	var row_re := RegEx.create_from_string("^\\|\\s*`(.)`\\s*\\|\\s*([^|]*?)\\s*\\|")
	var hex_re := RegEx.create_from_string("^#([0-9A-Fa-f]{6})$")
	var palette := {}
	for raw in section_lines(lines, "D01"):
		var r := row_re.search(raw.strip_edges())
		if r == null:
			continue
		var code := r.get_string(1)
		var value := r.get_string(2)
		if code == ".":
			palette[code] = Color8(0, 0, 0, 0)
			continue
		var h := hex_re.search(value)
		if h == null:
			printerr("D01 代號 %s 的 HEX 無法解析: %s" % [code, value])
			return {}
		var hex := h.get_string(1)
		palette[code] = Color8(hex.substr(0, 2).hex_to_int(), hex.substr(2, 2).hex_to_int(), hex.substr(4, 2).hex_to_int(), 255)
	return palette


## 取出某個 D 項目的所有行：從含「[Dxx]」的行開始，到下一個 D 項目或分隔線「---」為止。
func section_lines(lines: PackedStringArray, item: String) -> PackedStringArray:
	var item_re := RegEx.create_from_string("\\[(D\\d+)\\]")
	var out := PackedStringArray()
	var inside := false
	for raw in lines:
		var m := item_re.search(raw)
		if m:
			inside = m.get_string(1) == item
		elif raw.strip_edges() == "---":
			inside = false
		if inside:
			out.append(raw)
	return out


## 找出所有 ```text 區塊。回傳 Array[Dictionary],每項含
## item(如 "D12")、title(區塊前一行文字)、name(輸出檔名，不含副檔名)、line(```text 所在行號)、grid。
## 結構錯誤(區塊沒有結尾、標題無法命名或重名)附加到 errors,該區塊不列入回傳。
func parse_blocks(lines: PackedStringArray, errors: PackedStringArray) -> Array:
	var item_re := RegEx.create_from_string("\\[(D\\d+)\\]")
	var blocks := []
	var used := {}
	var item := "D00"
	var title := ""
	var i := 0
	while i < lines.size():
		var s := lines[i].strip_edges()
		var m := item_re.search(s)
		if m:
			item = m.get_string(1)
		if s == "```text":
			var start := i + 1
			var grid := PackedStringArray()
			i += 1
			while i < lines.size() and lines[i].strip_edges() != "```":
				# 設計稿的網格因為在列表內而有縮排，去掉前後空白即可
				grid.append(lines[i].strip_edges())
				i += 1
			if i >= lines.size():
				# 沒有結尾時會把後面整份文件吞進網格，必須擋下
				errors.append("設計稿第 %d 行的 ```text 區塊沒有結尾的 ```" % start)
				break
			var slug := id_from_title(title)
			if slug == "":
				slug = slug_from_title(title)
			if slug.begins_with("!"):
				errors.append("%s 區塊(設計稿第 %d 行)的標題「%s」%s" % [item, start, title, slug.substr(1)])
			else:
				var name := item + "_" + slug
				if used.has(name):
					# 精靈圖靠檔名找母版，重名會讓來源不明確
					errors.append("%s 區塊(設計稿第 %d 行)的標題「%s」與第 %d 行的區塊同名(%s)" % [item, start, title, used[name], name])
				else:
					used[name] = start
					blocks.append({"item": item, "title": title, "name": name, "line": start, "grid": grid})
		elif s != "" and not s.begins_with("```"):
			title = s
		i += 1
	return blocks


## 標題含「(id: 代號)」(全形或半形括號、冒號皆可)時直接用代號當檔名片段。
## 回傳：代號;標題沒有 id 時回傳 "";有 id 但格式錯誤時回傳以「!」開頭的錯誤說明。
## 例：「正常左端(id: paddle_normal_left):」→ paddle_normal_left
func id_from_title(title: String) -> String:
	# 先寬鬆偵測「(id」,再嚴格比對，才能把寫錯的 id 報出來而不是悄悄改用中文命名
	if RegEx.create_from_string(RE_LPAREN + "\\s*id\\b").search(title) == null:
		return ""
	var m := RegEx.create_from_string(RE_LPAREN + "\\s*id\\s*[:：]\\s*([^)）]*?)\\s*" + RE_RPAREN).search(title)
	if m == null:
		return "!的 id 格式錯誤(預期「(id: 英文代號)」)"
	var id := m.get_string(1)
	if RegEx.create_from_string(ID_RE).search(id) == null:
		return "!的 id「%s」只能用小寫英文、數字、底線(%s)" % [id, ID_RE]
	return id


## 把中文標題轉成英文檔名片段。
## 只比對標題的「名稱部分」(第一個冒號或左括號之前),括號內的補充說明不參與命名。
## 規則：
##   「數字 N」→ digitN;「層 N X範例」→ example_<顏色>N;「層 N」→ layerNN(以上三種不可再搭配其他字)
##   磚種(一般磚/寶箱/金幣/圓形/魔王)+ 狀態(正常 normal、被擊中 hit、FN fN、含「疊」overlay)
##   例：「一般磚正常」→ brick_normal、「F1 裂開」→ f1、「魔王裂痕疊加」→ boss_overlay
##   都不符合 → block。
## 回傳：檔名片段;規則衝突(兩個磚種、兩個狀態、特殊名稱又含其他詞)時回傳以「!」開頭的錯誤說明。
func slug_from_title(title: String) -> String:
	var t := title.trim_prefix("- ")
	var head := t
	for sep in [":", FW_COLON, "(", FW_LPAREN]:
		var p := head.find(sep)
		if p >= 0:
			head = head.substr(0, p)

	var specials := PackedStringArray()
	var rest := head
	var m := RegEx.create_from_string("數字\\s*(\\d+)").search(rest)
	if m:
		specials.append("digit" + m.get_string(1))
		rest = rest.replace(m.get_string(0), "")
	m = RegEx.create_from_string("層\\s*(\\d+)\\s*(\\S?)範例").search(rest)
	if m:
		specials.append("example_%s%s" % [COLOR_SLUG.get(m.get_string(2), "x"), m.get_string(1)])
		rest = rest.replace(m.get_string(0), "")
	m = RegEx.create_from_string("層\\s*(\\d+)").search(rest)
	if m:
		specials.append("layer%02d" % m.get_string(1).to_int())
		rest = rest.replace(m.get_string(0), "")

	var subjects := PackedStringArray()
	for key in SUBJECT_SLUG:
		if rest.contains(key):
			subjects.append(SUBJECT_SLUG[key])
	var states := PackedStringArray()
	m = RegEx.create_from_string("F(\\d)").search(rest)
	if m:
		states.append("f" + m.get_string(1) + ("_overlay" if rest.contains("疊") else ""))
	elif rest.contains("疊"):
		states.append("overlay")
	if rest.contains("被擊中"):
		states.append("hit")
	if rest.contains("正常"):
		states.append("normal")

	var all := specials + subjects + states
	if specials.size() > 1 or (specials.size() == 1 and all.size() > 1) or subjects.size() > 1 or states.size() > 1:
		return "!同時符合多個命名規則(%s),請調整標題" % ", ".join(all)
	if all.is_empty():
		return "block"
	return "_".join(all)


## 檢查網格：不可為空、每列等寬、所有字元都在調色盤內。回傳錯誤訊息，沒問題回傳空字串。
func validate_grid(grid: PackedStringArray, palette: Dictionary) -> String:
	if grid.is_empty() or grid[0].length() == 0:
		return "網格是空的"
	var w := grid[0].length()
	for y in grid.size():
		if grid[y].length() != w:
			return "(從 0 起算)第 %d 列寬度 %d,與第 0 列的 %d 不一致" % [y, grid[y].length(), w]
		for x in grid[y].length():
			var c := grid[y][x]
			if not palette.has(c):
				return "(從 0 起算)第 %d 列第 %d 欄有調色盤沒有的字元「%s」" % [y, x, c]
	return ""


# ---------------------------------------------------------------- 解析:D12 自動產生規則

## Markdown 表格列 → 去掉前後空白的儲存格陣列;不是表格列回傳空陣列。
func table_cells(raw: String) -> PackedStringArray:
	var s := raw.strip_edges()
	if not s.begins_with("|"):
		return PackedStringArray()
	var parts := s.split("|")
	var cells := PackedStringArray()
	for k in range(1, parts.size() - 1):
		cells.append(parts[k].strip_edges())
	return cells


## 取出字串中所有反引號包住的內容。
func backticks(s: String) -> PackedStringArray:
	var out := PackedStringArray()
	for m in RegEx.create_from_string("`([^`]*)`").search_all(s):
		out.append(m.get_string(1))
	return out


## 在規則表中找「項目」欄含 keyword 的那一列，回傳「規則」欄;找不到或不唯一時記錄錯誤並回傳 ""。
func find_rule(rule_rows: Dictionary, keyword: String, errors: PackedStringArray, item := RULE_ITEM) -> String:
	var found := []
	for key in rule_rows:
		if key.contains(keyword):
			found.append(key)
	if found.size() != 1:
		errors.append("%s 規則表：項目含「%s」的列有 %d 個(應為 1 個)" % [item, keyword, found.size()])
		return ""
	return rule_rows[found[0]]


## 解析 D12 的自動產生規則表與換色對照表。回傳規則 Dictionary;錯誤附加到 errors。
## 回傳欄位:source(母版色階代號陣列，T1~T5)、tiers({顏色名: 5 個代號})、
##   hit_keep(被擊中不變的字元)、hit_to(被擊中改成的字元)。
## 舊規則列(一般磚七色、通用破壞、多層磚組合、數字與層對應、多層磚破壞、扣層)已由
## 「多層磚層數(新規則)」取代，相關參數改用本檔常數、不再解析;所以那些列存在或被刪除都不影響轉檔。
func parse_rules(sec: PackedStringArray, palette: Dictionary, errors: PackedStringArray) -> Dictionary:
	var rules := {}
	if sec.is_empty():
		errors.append("設計稿找不到 %s 項目" % RULE_ITEM)
		return rules

	# 規則表：兩欄的表格列，鍵為「項目」
	var rule_rows := {}
	for raw in sec:
		var cells := table_cells(raw)
		if cells.size() == 2 and not cells[0].begins_with("---"):
			rule_rows[cells[0]] = cells[1]

	var swap := parse_swap_table(sec, palette, errors, RULE_ITEM, "目標", COLOR_ORDER)
	if not swap.is_empty():
		var tiers: Dictionary = swap["tiers"]
		if tiers.has("紅") and tiers["紅"] != swap["source"]:
			errors.append("%s 換色對照表矛盾：「紅」列 %s 與表頭母版欄 %s 不同" % [RULE_ITEM, " ".join(tiers["紅"]), " ".join(swap["source"])])
		rules["source"] = swap["source"]
		rules["tiers"] = tiers

	# 被擊中：「除 `K`、`.` 以外的像素全部改成 `W`」
	var text := find_rule(rule_rows, "被擊中", errors)
	if text != "":
		var m := RegEx.create_from_string("除(.+?)以外的像素全部改成\\s*`(.)`").search(text)
		if m == null or backticks(m.get_string(1)).is_empty():
			errors.append("%s 規則「被擊中」格式無法解析(預期「除 `K`、`.` 以外的像素全部改成 `W`」): %s" % [RULE_ITEM, text])
		else:
			rules["hit_keep"] = backticks(m.get_string(1))
			rules["hit_to"] = m.get_string(2)
	return rules


## 解析換色對照表：表頭第一欄為 header_first,其後各欄為母版代號(「T1(`h`)」或「`h`」;寫了 T 階就必須與欄位順序一致)。
## 列名的全形括號轉成半形(「雷射（洋紅）」→「雷射(洋紅)」),方便與本檔常數比對。
## required:必須出現的列名。回傳 {"source": 母版代號陣列, "tiers": {列名: 代號陣列}};無法解析時回傳空字典。
func parse_swap_table(sec: PackedStringArray, palette: Dictionary, errors: PackedStringArray, item: String, header_first: String, required: Array) -> Dictionary:
	var header_at := -1
	for k in sec.size():
		var cells := table_cells(sec[k])
		if cells.size() > 0 and cells[0] == header_first:
			if header_at >= 0:
				errors.append("%s 有兩個以上「%s」開頭的換色對照表" % [item, header_first])
				return {}
			header_at = k
	if header_at < 0:
		errors.append("%s 找不到換色對照表(表頭第一欄應為「%s」)" % [item, header_first])
		return {}

	var header := table_cells(sec[header_at])
	var source := PackedStringArray()
	for k in range(1, header.size()):
		var codes := backticks(header[k])
		var tm := RegEx.create_from_string("T(\\d)").search(header[k])
		if codes.size() != 1 or codes[0].length() != 1 or (tm != null and tm.get_string(1).to_int() != k):
			errors.append("%s 換色對照表表頭(從 0 起算)第 %d 欄格式錯誤(預期「T%d(`代號`)」或「`代號`」): %s" % [item, k, k, header[k]])
			return {}
		source.append(codes[0])
	if source.is_empty():
		errors.append("%s 換色對照表表頭沒有色階欄" % item)
		return {}

	var tiers := {}
	var k2 := header_at + 1
	while k2 < sec.size():
		var cells := table_cells(sec[k2])
		if cells.is_empty():
			break
		k2 += 1
		if cells[0].begins_with("---"):
			continue
		var name := cells[0].replace(FW_LPAREN, "(").replace(FW_RPAREN, ")")
		if cells.size() != source.size() + 1:
			errors.append("%s 換色對照表「%s」列有 %d 欄，應為 %d 欄" % [item, name, cells.size(), source.size() + 1])
			continue
		var codes := PackedStringArray()
		for c in range(1, cells.size()):
			var b := backticks(cells[c])
			if b.size() != 1 or b[0].length() != 1:
				errors.append("%s 換色對照表「%s」列(從 0 起算)第 %d 欄格式錯誤: %s" % [item, name, c, cells[c]])
				break
			if not palette.has(b[0]):
				errors.append("%s 換色對照表「%s」列的代號 `%s` 不在 D01 調色盤" % [item, name, b[0]])
			codes.append(b[0])
		if codes.size() != source.size():
			continue
		if tiers.has(name):
			errors.append("%s 換色對照表的「%s」重複出現" % [item, name])
		tiers[name] = codes
	for name in required:
		if not tiers.has(name):
			errors.append("%s 換色對照表缺少「%s」" % [item, name])
	return {"source": source, "tiers": tiers}


## 取出某個 D 項目的所有行。與 section_lines 不同，不因項目內「縮排」的分隔線(如 D17 效果之間的「    ---」)中斷;
## 到下一個 D 項目、頂格的「---」或「## 」標題為止。
func item_lines(lines: PackedStringArray, item: String) -> PackedStringArray:
	var item_re := RegEx.create_from_string("\\[(D\\d+)\\]")
	var out := PackedStringArray()
	var inside := false
	for raw in lines:
		var m := item_re.search(raw)
		if m:
			inside = m.get_string(1) == item
		elif raw.rstrip(" \t") == "---" or raw.begins_with("## "):
			inside = false
		if inside:
			out.append(raw)
	return out


## 解析 D17、D18 的破壞幀換色表，結果寫入 rules["func_tiers"]({列名: 代號陣列},列名已轉半形括號)。
## 兩表的母版欄必須與 D12 相同;D18 的挑色環換色表(表頭「中選色」)若存在，必須與 D12 換色表完全一致。
func parse_func_rules(lines: PackedStringArray, palette: Dictionary, rules: Dictionary, errors: PackedStringArray) -> void:
	var func2_tiers := []
	for spec in FUNC2_BRICKS:
		if not func2_tiers.has(spec[2]):
			func2_tiers.append(spec[2])
	var all := {}
	for spec in [[FUNC_ITEM, FUNC_TIERS], [FUNC2_ITEM, func2_tiers]]:
		var sec := item_lines(lines, spec[0])
		if sec.is_empty():
			errors.append("設計稿找不到 %s 項目" % spec[0])
			continue
		var t := parse_swap_table(sec, palette, errors, spec[0], "目標", spec[1])
		if t.is_empty():
			continue
		if t["source"] != rules["source"]:
			errors.append("%s 換色對照表的母版欄 %s 與 D12 母版色階 %s 不同" % [spec[0], " ".join(t["source"]), " ".join(rules["source"])])
		for name in t["tiers"]:
			all[name] = t["tiers"][name]
	rules["func_tiers"] = all

	# 挑色環換色表「與 D12 同表，另列出」:兩表不一致就是設計稿矛盾
	var sec2 := item_lines(lines, FUNC2_ITEM)
	var has_pick := false
	for raw in sec2:
		var cells := table_cells(raw)
		if cells.size() > 0 and cells[0] == "中選色":
			has_pick = true
	if has_pick:
		var p := parse_swap_table(sec2, palette, errors, FUNC2_ITEM, "中選色", COLOR_ORDER)
		if not p.is_empty():
			if p["source"] != rules["source"]:
				errors.append("%s 挑色環換色表的母版欄 %s 與 D12 母版色階 %s 不同" % [FUNC2_ITEM, " ".join(p["source"]), " ".join(rules["source"])])
			for name in COLOR_ORDER:
				if p["tiers"].has(name) and p["tiers"][name] != rules["tiers"][name]:
					errors.append("%s 挑色環換色表「%s」列 %s 與 D12 換色對照表 %s 不同" % [FUNC2_ITEM, name, " ".join(p["tiers"][name]), " ".join(rules["tiers"][name])])


# ---------------------------------------------------------------- 精靈圖產生(字元網格運算)

## 換色：依 map 把字元換掉，不在 map 的字元保留。
func swap_grid(grid: PackedStringArray, map: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for row in grid:
		var s := ""
		for c in row:
			s += map.get(c, c)
		out.append(s)
	return out


## 被擊中：keep 以外的字元全部改成 to。
func hit_grid(grid: PackedStringArray, keep: PackedStringArray, to: String) -> PackedStringArray:
	var out := PackedStringArray()
	for row in grid:
		var s := ""
		for c in row:
			s += c if keep.has(c) else to
		out.append(s)
	return out


## 疊加：top 的非 `.` 像素蓋到 base 上(左上角對齊 ox, oy);ink 不為空時一律以 ink 著色。
func overlay_grid(base: PackedStringArray, top: PackedStringArray, ox: int, oy: int, ink := "") -> PackedStringArray:
	var out := base.duplicate()
	for y in top.size():
		var row := out[oy + y]
		for x in top[y].length():
			var c := top[y][x]
			if c != ".":
				row = row.substr(0, ox + x) + (ink if ink != "" else c) + row.substr(ox + x + 1)
		out[oy + y] = row
	return out


## 在矩形範圍(含端點)內把 from 換成 to。
func replace_in_rect(grid: PackedStringArray, x0: int, x1: int, y0: int, y1: int, from: String, to: String) -> PackedStringArray:
	var out := grid.duplicate()
	for y in range(y0, y1 + 1):
		var row := out[y]
		for x in range(x0, x1 + 1):
			if row[x] == from:
				row = row.substr(0, x) + to + row.substr(x + 1)
		out[y] = row
	return out


## 每列一組影格，由左到右、由上到下無間隙拼成一張網格。
func compose_sheet(rows: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for frames in rows:
		for y in frames[0].size():
			var s := ""
			for fr in frames:
				s += fr[y]
			out.append(s)
	return out


## 取出某個 D 項目的所有母版網格：{檔名去掉「Dxx_」的部分: 網格}。
func item_grids(blocks: Array, item: String) -> Dictionary:
	var g := {}
	for b in blocks:
		if b["item"] == item:
			g[b["name"].trim_prefix(item + "_")] = b["grid"]
	return g


## 檢查 need({名稱: [寬, 高]})列出的母版都存在且尺寸正確;錯誤附加到 errors。
func check_masters(g: Dictionary, need: Dictionary, item: String, errors: PackedStringArray) -> void:
	for n in need:
		if not g.has(n):
			errors.append("%s 缺少母版區塊 %s_%s(依標題命名，見 id_from_title、slug_from_title)" % [item, item, n])
		elif g[n][0].length() != need[n][0] or g[n].size() != need[n][1]:
			errors.append("%s_%s 尺寸 %dx%d,應為 %dx%d" % [item, n, g[n][0].length(), g[n].size(), need[n][0], need[n][1]])


## 由「母版色階 → 目標色階」建立換色表 {母版代號: 目標代號}。
func tier_map(source: PackedStringArray, target: PackedStringArray) -> Dictionary:
	var mp := {}
	for k in source.size():
		mp[source[k]] = target[k]
	return mp


## D12 通用破壞 F1~F4 依 map 換色後的 4 幀。
func generic_frames(g12: Dictionary, map: Dictionary) -> Array:
	return [swap_grid(g12["f1"], map), swap_grid(g12["f2"], map), swap_grid(g12["f3"], map), swap_grid(g12["f4"], map)]


## 數字疊加圖(CELL_W×CELL_H,`.` 透明):字形非 `.` 像素改成 fill,字形以外的 8 鄰格畫 outline。
## (ox, oy) 為字形左上角;描邊超出磚格的部分捨棄(呼叫端已確認不會發生)。
func outlined_digit(glyph: PackedStringArray, ox: int, oy: int, fill: String, outline: String) -> PackedStringArray:
	var cells := []
	for y in CELL_H:
		var row := []
		row.resize(CELL_W)
		row.fill(".")
		cells.append(row)
	# 先畫描邊再畫字形，字形像素才不會被相鄰筆畫的描邊蓋掉
	for pass_fill in [false, true]:
		for y in glyph.size():
			for x in glyph[y].length():
				if glyph[y][x] == ".":
					continue
				if pass_fill:
					cells[oy + y][ox + x] = fill
					continue
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var yy: int = oy + y + dy
						var xx: int = ox + x + dx
						if yy >= 0 and yy < CELL_H and xx >= 0 and xx < CELL_W:
							cells[yy][xx] = outline
	var out := PackedStringArray()
	for row in cells:
		out.append("".join(PackedStringArray(row)))
	return out


## 多層磚正常圖(D12「多層磚層數(新規則)」):母版換色;digit > 0 時再把 MULTI_FIXES 區域改 T3、疊上白字加描邊。
## overlays:數字 1~9 的疊加圖(索引 = 數字)。
func multi_normal(master: PackedStringArray, map: Dictionary, target: PackedStringArray, digit: int, overlays: Array) -> PackedStringArray:
	var out := swap_grid(master, map)
	if digit == 0:
		return out
	for fx in MULTI_FIXES:
		# 換色後再改：原色階、新色階都用目標色的代號
		out = replace_in_rect(out, fx[0], fx[1], fx[2], fx[3], target[fx[4] - 1], target[fx[5] - 1])
	return overlay_grid(out, overlays[digit], 0, 0)


## 回傳兩張同尺寸網格第一個不同的像素說明;相同回傳 ""。
func grid_diff(a: PackedStringArray, b: PackedStringArray) -> String:
	if a.size() != b.size() or a[0].length() != b[0].length():
		return "尺寸 %dx%d 與 %dx%d 不同" % [a[0].length(), a.size(), b[0].length(), b.size()]
	for y in a.size():
		for x in a[y].length():
			if a[y][x] != b[y][x]:
				return "(從 0 起算)第 %d 欄第 %d 列：產生 `%s`、範例 `%s`" % [x, y, a[y][x], b[y][x]]
	return ""


## 依規則產生 D12 各磚種精靈圖。回傳 {檔名: {"grid": 網格, "frames": Array[Array[網格]]}};錯誤附加到 errors。
## 每張圖每列 6 格：正常、被擊中、F1、F2、F3、F4。
## bricks_multi:依層數由上到下 70 列(層 1~70;層 70 = 紫 9,產生但遊戲不使用),
## 層 L 的顏色 = (L − 1) mod 7、數字 = (L − 1) div 7;破壞幀依顏色換色、與數字無關。
func build_sprite_sheets(blocks: Array, rules: Dictionary, palette: Dictionary, errors: PackedStringArray) -> Dictionary:
	var g := item_grids(blocks, RULE_ITEM)

	# 母版需求：名稱 → 尺寸
	var need := {"brick_normal": [CELL_W, CELL_H], "chest_normal": [CELL_W, CELL_H], "coin_normal": [CELL_W, CELL_H],
		"round_normal": [CELL_W, CELL_H], "f1": [CELL_W, CELL_H], "f2": [CELL_W, CELL_H], "f3": [CELL_W, CELL_H],
		"f4": [CELL_W, CELL_H], "round_f1": [CELL_W, CELL_H], "round_f2": [CELL_W, CELL_H],
		"boss_normal": [BOSS_W, BOSS_H], "boss_overlay": [BOSS_W, BOSS_H], "boss_f2": [BOSS_W, BOSS_H],
		"boss_f3": [BOSS_W, BOSS_H], "boss_f4": [BOSS_W, BOSS_H]}
	for d in DIGIT_COUNT:
		need["digit%d" % d] = [DIGIT_W, DIGIT_H]
	check_masters(g, need, RULE_ITEM, errors)
	if not errors.is_empty():
		return {}

	var source: PackedStringArray = rules["source"]
	var keep: PackedStringArray = rules["hit_keep"]
	var hit_to: String = rules["hit_to"]

	# 換色前檢查：會換色的母版只能含母版色階與「不變」清單內的字元，否則換色結果不明確
	for n in ["brick_normal", "f1", "f2", "f3", "f4"]:
		for row in g[n]:
			for c in row:
				if not source.has(c) and not SWAP_KEEP.has(c):
					errors.append("%s_%s 含換色規則未涵蓋的代號 `%s`(不在母版色階 %s,也不在不變清單 %s)" % [RULE_ITEM, n, c, " ".join(source), " ".join(SWAP_KEEP)])
					return {}

	var maps := {}
	for name in rules["tiers"]:
		maps[name] = tier_map(source, rules["tiers"][name])

	# 數字字形：只能有 `.` 與墨色
	for d in DIGIT_COUNT:
		for row in g["digit%d" % d]:
			for c in row:
				if c != "." and c != FUNC_DIGIT_INK:
					errors.append("%s_digit%d 含墨色 `%s` 以外的字元 `%s`" % [RULE_ITEM, d, FUNC_DIGIT_INK, c])
					return {}
	# 數字加描邊(7×9)必須在磚格內
	if MULTI_DIGIT_X < 1 or MULTI_DIGIT_Y < 1 or MULTI_DIGIT_X + DIGIT_W + 1 > CELL_W or MULTI_DIGIT_Y + DIGIT_H + 1 > CELL_H:
		errors.append("多層磚數字位置(第 %d 欄、第 %d 列)加描邊超出磚格" % [MULTI_DIGIT_X, MULTI_DIGIT_Y])
		return {}

	var sheets := {}

	# 一般磚七色(= 多層磚第 0 輪)
	var rows := []
	for color in COLOR_ORDER:
		var normal := swap_grid(g["brick_normal"], maps[color])
		rows.append([normal, hit_grid(normal, keep, hit_to)] + generic_frames(g, maps[color]))
	sheets["bricks_normal"] = rows

	# 多層磚：層 1~(輪數 × 7)
	var overlays := [PackedStringArray()]
	for d in range(1, DIGIT_COUNT):
		overlays.append(outlined_digit(g["digit%d" % d], MULTI_DIGIT_X, MULTI_DIGIT_Y, MULTI_FILL, MULTI_OUTLINE))
	rows = []
	for layer in range(1, ROUND_COUNT * COLOR_ORDER.size() + 1):
		var color: String = COLOR_ORDER[(layer - 1) % COLOR_ORDER.size()]
		var digit: int = (layer - 1) / COLOR_ORDER.size()
		var normal := multi_normal(g["brick_normal"], maps[color], rules["tiers"][color], digit, overlays)
		rows.append([normal, hit_grid(normal, keep, hit_to)] + generic_frames(g, maps[color]))
	sheets["bricks_multi"] = rows

	# 設計稿的範例網格(id: layer_example_<顏色><數字>)必須與產生結果逐像素相同
	var ex_re := RegEx.create_from_string("^layer_example_([a-z]+)(\\d)$")
	for n in g:
		var m := ex_re.search(n)
		if m == null:
			continue
		var color := ""
		for c in COLOR_SLUG:
			if COLOR_SLUG[c] == m.get_string(1):
				color = c
		var digit := m.get_string(2).to_int()
		if color == "":
			errors.append("%s_%s:看不懂範例的顏色「%s」" % [RULE_ITEM, n, m.get_string(1)])
			continue
		var layer: int = digit * COLOR_ORDER.size() + COLOR_ORDER.find(color) + 1
		var diff := grid_diff(rows[layer - 1][0], g[n])
		if diff != "":
			errors.append("依多層磚新規則產生的層 %d(%s %d)與範例 %s_%s 不同：%s" % [layer, color, digit, RULE_ITEM, n, diff])

	# 寶箱、金幣：正常與被擊中用專屬母版，破壞用通用幀換色
	for pair in [["brick_chest", "chest_normal", "寶箱"], ["brick_coin", "coin_normal", "金幣"]]:
		var normal: PackedStringArray = g[pair[1]]
		sheets[pair[0]] = [[normal, hit_grid(normal, keep, hit_to)] + generic_frames(g, maps[FRAME_COLORS[pair[2]]])]

	# 圓形：F1、F2 專用幀，F3、F4 通用幀
	var round_frames: Array = generic_frames(g, maps[FRAME_COLORS["圓形"]])
	sheets["brick_round"] = [[g["round_normal"], hit_grid(g["round_normal"], keep, hit_to), g["round_f1"], g["round_f2"], round_frames[2], round_frames[3]]]

	# 魔王:F1 = 正常圖疊上裂痕層
	sheets["brick_boss"] = [[g["boss_normal"], hit_grid(g["boss_normal"], keep, hit_to),
		overlay_grid(g["boss_normal"], g["boss_overlay"], 0, 0), g["boss_f2"], g["boss_f3"], g["boss_f4"]]]

	return finish_sheets(sheets, palette, errors)


## 把每張精靈圖的影格拼成網格並檢查;回傳 {檔名: {"grid", "frames"}}。
func finish_sheets(sheets: Dictionary, palette: Dictionary, errors: PackedStringArray) -> Dictionary:
	var out := {}
	for name in sheets:
		var grid := compose_sheet(sheets[name])
		var msg := validate_grid(grid, palette)
		if msg != "":
			errors.append("產生的 %s: %s" % [name, msg])
		out[name] = {"grid": grid, "frames": sheets[name]}
	return out


## 逆時針轉 90 度(正方形網格):新圖第 r 列第 c 欄 = 原圖第 c 列第 (n − 1 − r) 欄(D17「垂直光束轉換」)。
func rotate_ccw(grid: PackedStringArray) -> PackedStringArray:
	var n := grid.size()
	var out := PackedStringArray()
	for r in n:
		var s := ""
		for c in n:
			s += grid[c][n - 1 - r]
		out.append(s)
	return out


## 上下鏡射：新圖第 r 列 = 原圖第 (n − 1 − r) 列。
func flip_v(grid: PackedStringArray) -> PackedStringArray:
	var out := grid.duplicate()
	out.reverse()
	return out


## 依 D17、D18「需轉檔工具新增的自動產生規則」產生功能型磚精靈圖。回傳格式同 build_sprite_sheets。
##   brick_laser_h/v/x、brick_lightning、brick_reaper:9 列(數字 1~9)× [正常、被擊中、F1~F4];
##   laser_beam_v_*:由水平光束旋轉、鏡射的 6 張 16×16 單張圖;
##   brick_explosion、brick_rainbow:1 列 × [正常、被擊中、F1~F4];
##   rainbow_pick:7 列(紅橙黃綠藍靛紫)× 3 幀(F1~F3),依 D12 換色表換色;不產生「沒有多層磚」用的白色版(使用者決定)。
func build_func_sheets(blocks: Array, rules: Dictionary, palette: Dictionary, errors: PackedStringArray) -> Dictionary:
	var g12 := item_grids(blocks, RULE_ITEM)
	var g17 := item_grids(blocks, FUNC_ITEM)
	var g18 := item_grids(blocks, FUNC2_ITEM)
	var before := errors.size()

	var need17 := {}
	for spec in FUNC_BRICKS:
		need17[spec[0]] = [CELL_W, CELL_H]
	for spec in BEAM_V:
		if spec[2] == "ccw":
			need17[spec[1]] = [BEAM_SIZE, BEAM_SIZE]
	check_masters(g17, need17, FUNC_ITEM, errors)
	var need18 := {}
	for spec in FUNC2_BRICKS:
		need18[spec[0]] = [CELL_W, CELL_H]
	for n in PICK_FRAMES:
		need18[n] = [PICK_W, PICK_H]
	check_masters(g18, need18, FUNC2_ITEM, errors)
	if errors.size() > before:
		return {}

	var source: PackedStringArray = rules["source"]
	var keep: PackedStringArray = rules["hit_keep"]
	var hit_to: String = rules["hit_to"]
	var fmaps := {}
	for name in rules["func_tiers"]:
		fmaps[name] = tier_map(source, rules["func_tiers"][name])

	var sheets := {}

	# D17 功能型磚：底圖疊上 `K` 數字(`K` 覆蓋底圖、`.` 不動)
	for spec in FUNC_BRICKS:
		var base: PackedStringArray = g17[spec[0]]
		var frames := generic_frames(g12, fmaps[spec[2]])
		var rows := []
		for d in range(1, DIGIT_COUNT):
			var normal := overlay_grid(base, g12["digit%d" % d], FUNC_DIGIT_X, FUNC_DIGIT_Y, FUNC_DIGIT_INK)
			rows.append([normal, hit_grid(normal, keep, hit_to)] + frames)
			# 設計稿的對照範例(id: <底圖>_n<數字>)必須與產生結果逐像素相同
			var ex_id := "%s_n%d" % [spec[0], d]
			if g17.has(ex_id):
				var diff := grid_diff(normal, g17[ex_id])
				if diff != "":
					errors.append("依 %s 規則產生的 %s 數字 %d 與範例 %s_%s 不同：%s" % [FUNC_ITEM, spec[0], d, FUNC_ITEM, ex_id, diff])
		sheets[spec[1]] = rows

	# 垂直光束：中段、往上端點由水平圖逆時針轉 90 度;往下端點 = 往上端點上下鏡射
	var made := {}
	for spec in BEAM_V:
		var src: PackedStringArray = g17[spec[1]] if spec[2] == "ccw" else made[spec[1]]
		made[spec[0]] = rotate_ccw(src) if spec[2] == "ccw" else flip_v(src)
		sheets[spec[0]] = [[made[spec[0]]]]

	# D18 爆炸、彩虹磚
	for spec in FUNC2_BRICKS:
		var normal: PackedStringArray = g18[spec[0]]
		sheets[spec[1]] = [[normal, hit_grid(normal, keep, hit_to)] + generic_frames(g12, fmaps[spec[2]])]

	# 彩虹挑色環：只能含母版色階、`W`、`.`,否則換色結果不明確
	for n in PICK_FRAMES:
		for row in g18[n]:
			for c in row:
				if not source.has(c) and c != "W" and c != ".":
					errors.append("%s_%s 含挑色環換色規則未涵蓋的代號 `%s`" % [FUNC2_ITEM, n, c])
					return {}
	var pick_rows := []
	for color in COLOR_ORDER:
		var mp := tier_map(source, rules["tiers"][color])
		var row := []
		for n in PICK_FRAMES:
			row.append(swap_grid(g18[n], mp))
		pick_rows.append(row)
	sheets["rainbow_pick"] = pick_rows

	if errors.size() > before:
		return {}
	return finish_sheets(sheets, palette, errors)


## 層數對照表(D12「圖與層數對應」):層 1~LAYER_MAX → (顏色, 數字) 與 bricks_multi 的列號。
func build_layer_map() -> Dictionary:
	var layers := []
	for layer in range(1, LAYER_MAX + 1):
		var color: String = COLOR_ORDER[(layer - 1) % COLOR_ORDER.size()]
		layers.append({"layer": layer, "color": COLOR_SLUG[color], "color_name": color,
			"digit": (layer - 1) / COLOR_ORDER.size(), "row": layer - 1})
	return {"sheet": "bricks_multi.png", "cell": [CELL_W, CELL_H],
		"columns": ["normal", "hit", "f1", "f2", "f3", "f4"],
		"note": "digit 0 = 第 0 輪，不畫數字;bricks_multi 第 70 列(紫 9)有產生但不使用",
		"max_layer": LAYER_MAX, "layers": layers}


## 雷射光束排版資料(D17「雷射分段拼接」):各分段的檔案、尺寸、由來與鏡射方式。拼接本身由遊戲程式處理。
func build_beam_layout(blocks: Array) -> Dictionary:
	var pieces := {}
	for b in blocks:
		var id: String = b["name"].trim_prefix(FUNC_ITEM + "_")
		if b["item"] == FUNC_ITEM and id.begins_with("laser_beam_"):
			pieces[id] = {"file": b["name"] + ".png", "w": b["grid"][0].length(), "h": b["grid"].size()}
	for spec in BEAM_V:
		pieces[spec[0]] = {"file": SPRITE_DIR + "/" + spec[0] + ".png", "w": BEAM_SIZE, "h": BEAM_SIZE,
			"from": spec[1], "transform": "rotate_ccw_90" if spec[2] == "ccw" else "flip_v"}
	return {"pieces": pieces,
		"mirror": {"left_block": "laser_beam_block_* 水平鏡射(左側被擋下)"},
		"vertical_offset_x": BEAM_SIZE / 2,
		"note": "水平中段可左右平鋪;垂直分段圖左緣 x = 磚左緣 x + 8;起點圖 32×16 覆蓋雷射磚整格"}


## 依 D20、D21「F2 規則」產生道具 F2:道具 F1 與底板 F1 同位置、同代號的像素，改成底板 F2 同位置的像素，其餘不動。
## 回傳 {"<項目>_<道具 id>_f2": 網格}(依設計稿順序);底板缺少、尺寸不是 16×16、道具不是 16×16、
## 輸出檔名與既有區塊重名時，錯誤附加到 errors 並回傳空字典。
func build_item_f2(blocks: Array, errors: PackedStringArray) -> Dictionary:
	var before := errors.size()
	var names := {}
	for b in blocks:
		names[b["name"]] = true
	var out := {}
	for spec in ITEM_F2_SPECS:
		var item: String = spec[0]
		var g := item_grids(blocks, item)
		check_masters(g, {spec[1]: [ITEM_SIZE, ITEM_SIZE], spec[2]: [ITEM_SIZE, ITEM_SIZE]}, item, errors)
		if errors.size() > before:
			continue
		var p1: PackedStringArray = g[spec[1]]
		var p2: PackedStringArray = g[spec[2]]
		for id in g:
			if not id.begins_with("item_") or id.begins_with("item_plate_") or id.begins_with("item_pickup_"):
				continue
			var f1: PackedStringArray = g[id]
			if f1[0].length() != ITEM_SIZE or f1.size() != ITEM_SIZE:
				errors.append("%s_%s 尺寸 %dx%d,道具應為 %dx%d" % [item, id, f1[0].length(), f1.size(), ITEM_SIZE, ITEM_SIZE])
				continue
			var name := "%s_%s_f2" % [item, id]
			if names.has(name):
				errors.append("道具 F2 輸出檔名 %s 與設計稿既有區塊同名" % name)
				continue
			var f2 := PackedStringArray()
			for y in ITEM_SIZE:
				var s := ""
				for x in ITEM_SIZE:
					s += p2[y][x] if f1[y][x] == p1[y][x] else f1[y][x]
				f2.append(s)
			out[name] = f2
	if errors.size() > before:
		return {}
	return out


# ---------------------------------------------------------------- 擋板(D13)

## 解析 D13 的擋板規格與拼接規則表。回傳規則 Dictionary(失敗時為空);錯誤附加到 errors。
## 回傳欄位:heights(允許的圖高)、end_l、end_r、tile_w、full_w、min、max、
##   lengths(要產生的長度，由小到大)、hit_keep、hit_to。
## 尺寸各自解析、不假設兩端與中段同寬或同高;同一個尺寸在多處出現時(說明文字、組成列、中段拼法列)
## 必須一致，否則視為設計稿矛盾。另外交叉比對最短/最長長度與「例」列的 W/n/r。
func parse_paddle_rules(sec: PackedStringArray, errors: PackedStringArray) -> Dictionary:
	var before := errors.size()
	var r := {}
	if sec.is_empty():
		errors.append("設計稿找不到 %s 項目" % PADDLE_ITEM)
		return {}
	var text := "\n".join(sec)
	var rule_rows := {}
	for raw in sec:
		var cells := table_cells(raw)
		if cells.size() == 2 and not cells[0].begins_with("---"):
			rule_rows[cells[0]] = cells[1]

	# 圖高(固定句型):「圖高(對象):N」,例如「圖高(槍左端):12」;對象對應到哪些分段見 height_targets()
	var specs := []
	for mm in RegEx.create_from_string("圖高\\s*" + RE_LPAREN + "([^)\uFF09]+)" + RE_RPAREN + "\\s*[:\uFF1A]\\s*(\\d+)").search_all(text):
		specs.append([mm.get_string(1).strip_edges(), mm.get_string(2).to_int()])
	var heights := []
	if specs.is_empty():
		# 舊寫法：「圖高 8」或「圖高 8、12」,只能檢查高度是否在清單內
		for mm in RegEx.create_from_string("圖高([^;\uFF1B\u3002\\n寬]*)").search_all(text):
			for nm in RegEx.create_from_string("\\d+").search_all(mm.get_string(1)):
				if not heights.has(nm.get_string(0).to_int()):
					heights.append(nm.get_string(0).to_int())
	else:
		for s in specs:
			if not heights.has(s[1]):
				heights.append(s[1])
	if heights.is_empty():
		errors.append("%s 找不到圖高(預期固定句型「圖高(本體):8」「圖高(槍左端):12」)" % PADDLE_ITEM)
	heights.sort()
	r["heights"] = heights
	r["height_specs"] = specs

	# 「高度與對齊」列(若有):必須是底部對齊;「正常、吸附為 8;槍為 12」用來核對組好的整條高
	r["set_heights"] = {}
	var align_rows := rule_rows.keys().filter(func(k): return k.contains("高度與對齊"))
	if align_rows.size() == 1:
		var at: String = rule_rows[align_rows[0]]
		if not at.contains("底部對齊"):
			errors.append("%s 規則「高度與對齊」沒有寫「底部對齊」,與使用者決定的底部對齊不一致: %s" % [PADDLE_ITEM, at])
		var set_of := {"正常": "paddle_normal", "吸附": "paddle_sticky", "槍": "paddle_gun"}
		for mm in RegEx.create_from_string("((?:正常|吸附|槍)(?:\\s*" + RE_COMMA + "\\s*(?:正常|吸附|槍))*)\\s*為\\s*(\\d+)").search_all(at):
			for nm in RegEx.create_from_string("正常|吸附|槍").search_all(mm.get_string(1)):
				r["set_heights"][set_of[nm.get_string(0)]] = mm.get_string(2).to_int()

	# 寬度：每個尺寸收集所有出處 [出處文字, 數值],之後檢查一致
	var dims := {"左端寬": [], "右端寬": [], "中段圖塊寬": [], "完整圖寬": []}
	var w_re := "(?:圖)?寬\\s*[:\uFF1A]?\\s*\\**\\s*(\\d+)"
	for key in [["左端", "左端寬"], ["右端", "右端寬"], ["中段圖塊", "中段圖塊寬"], ["完整圖", "完整圖寬"]]:
		for mm in RegEx.create_from_string(key[0] + w_re).search_all(text):
			dims[key[1]].append([mm.get_string(0).replace("*", ""), mm.get_string(1).to_int()])
	# 「端帽圖寬 N」同時指左端與右端
	for mm in RegEx.create_from_string("端帽" + w_re).search_all(text):
		dims["左端寬"].append([mm.get_string(0), mm.get_string(1).to_int()])
		dims["右端寬"].append([mm.get_string(0), mm.get_string(1).to_int()])

	# 組成：左端(寬 a)+ 中段(寬 L − b)+ 右端(寬 c)
	var formula := -1
	var comp := find_rule(rule_rows, "組成", errors, PADDLE_ITEM)
	if comp != "":
		var ml := RegEx.create_from_string("左端\\s*" + RE_LPAREN + "\\s*寬\\s*(\\d+)\\s*" + RE_RPAREN).search(comp)
		var mr := RegEx.create_from_string("右端\\s*" + RE_LPAREN + "\\s*寬\\s*(\\d+)\\s*" + RE_RPAREN).search(comp)
		var mf := RegEx.create_from_string("L\\s*[\\-−]\\s*(\\d+)").search(comp)
		if ml == null or mr == null or mf == null:
			errors.append("%s 規則「組成」格式無法解析(預期「左端(寬 8)+ 中段(寬 `L − 16`)+ 右端(寬 8)」): %s" % [PADDLE_ITEM, comp])
		else:
			dims["左端寬"].append(["組成列「左端(寬 %s)」" % ml.get_string(1), ml.get_string(1).to_int()])
			dims["右端寬"].append(["組成列「右端(寬 %s)」" % mr.get_string(1), mr.get_string(1).to_int()])
			formula = mf.get_string(1).to_int()

	# 中段拼法：「W 除以 N」的 N 也是中段圖塊寬
	var mid := find_rule(rule_rows, "中段拼法", errors, PADDLE_ITEM)
	if mid != "":
		var mm := RegEx.create_from_string("除以\\s*(\\d+)").search(mid)
		if mm == null:
			errors.append("%s 規則「中段拼法」找不到「W 除以 N」: %s" % [PADDLE_ITEM, mid])
		else:
			dims["中段圖塊寬"].append(["中段拼法列「除以 %s」" % mm.get_string(1), mm.get_string(1).to_int()])

	var key_map := {"左端寬": "end_l", "右端寬": "end_r", "中段圖塊寬": "tile_w", "完整圖寬": "full_w"}
	for key in dims:
		var srcs: Array = dims[key]
		if srcs.is_empty():
			errors.append("%s 找不到「%s N」" % [PADDLE_ITEM, key])
			continue
		var values := {}
		for s in srcs:
			values[s[1]] = true
		if values.size() > 1:
			var desc := PackedStringArray()
			for s in srcs:
				desc.append("%s → %d" % [s[0], s[1]])
			errors.append("%s 規則矛盾：%s 有不同的值(%s)" % [PADDLE_ITEM, key, ";".join(desc)])
			continue
		r[key_map[key]] = srcs[0][1]
	if formula >= 0 and r.has("end_l") and r.has("end_r") and r["end_l"] + r["end_r"] != formula:
		errors.append("%s 規則矛盾：左端寬 %d + 右端寬 %d ≠ 組成列中段公式的 %d" % [PADDLE_ITEM, r["end_l"], r["end_r"], formula])

	# 長度
	var lengths := {}
	for pat in ["基準長度\\s*(\\d+)", "最大長度\\s*(\\d+)", "最短暫定\\s*(\\d+)"]:
		var m := RegEx.create_from_string(pat).search(text)
		if m == null:
			errors.append("%s 找不到長度說明「%s」" % [PADDLE_ITEM, pat.get_slice("\\", 0)])
		else:
			lengths[pat.get_slice("\\", 0)] = m.get_string(1).to_int()
	var item_names := {}
	for mm in RegEx.create_from_string("(小增|大增|小減|大減)\\s*(\\d+)").search_all(text):
		item_names[mm.get_string(1)] = mm.get_string(2).to_int()
	for need in ["小增", "大增", "小減", "大減"]:
		if not item_names.has(need):
			errors.append("%s 找不到道具長度「%s N」" % [PADDLE_ITEM, need])
	if lengths.has("基準長度"):
		r["base"] = lengths["基準長度"]

	# 長度範圍
	var rng := find_rule(rule_rows, "長度取整與範圍", errors, PADDLE_ITEM)
	if rng != "":
		var mm := RegEx.create_from_string("限制在\\s*(\\d+)\\s*" + RE_TILDE + "\\s*(\\d+)").search(rng)
		if mm == null:
			errors.append("%s 規則「長度取整與範圍」找不到「限制在 a~b」: %s" % [PADDLE_ITEM, rng])
		else:
			r["min"] = mm.get_string(1).to_int()
			r["max"] = mm.get_string(2).to_int()
			if lengths.has("最短暫定") and lengths["最短暫定"] != r["min"]:
				errors.append("%s 規則矛盾：最短暫定 %d 與範圍下限 %d 不同" % [PADDLE_ITEM, lengths["最短暫定"], r["min"]])
			if lengths.has("最大長度") and lengths["最大長度"] != r["max"]:
				errors.append("%s 規則矛盾：最大長度 %d 與範圍上限 %d 不同" % [PADDLE_ITEM, lengths["最大長度"], r["max"]])

	# 被擊中
	var hit := find_rule(rule_rows, "被擊中", errors, PADDLE_ITEM)
	if hit != "":
		var mm := RegEx.create_from_string("除(.+?)以外的像素全部改成\\s*`(.)`").search(hit)
		if mm == null or backticks(mm.get_string(1)).is_empty():
			errors.append("%s 規則「被擊中」格式無法解析(預期「除 `K` 與 `.` 以外的像素全部改成 `W`」): %s" % [PADDLE_ITEM, hit])
		else:
			r["hit_keep"] = backticks(mm.get_string(1))
			r["hit_to"] = mm.get_string(2)

	if errors.size() > before:
		return {}

	# 「例」列：用解析出的參數重算 W、n、r,不一致就是設計稿矛盾
	var ex := find_rule(rule_rows, "例", errors, PADDLE_ITEM)
	if ex != "":
		var re := RegEx.create_from_string("`L\\s*=\\s*(\\d+)`\\S*?`W\\s*=\\s*(\\d+)`\\S*?`n\\s*=\\s*(\\d+)`\\S*?`r\\s*=\\s*(\\d+)`")
		var found := re.search_all(ex)
		if found.is_empty():
			errors.append("%s 規則「例」格式無法解析: %s" % [PADDLE_ITEM, ex])
		for mm in found:
			var L := mm.get_string(1).to_int()
			var w: int = L - r["end_l"] - r["end_r"]
			var calc := [w, w / r["tile_w"], w % r["tile_w"]]
			var given := [mm.get_string(2).to_int(), mm.get_string(3).to_int(), mm.get_string(4).to_int()]
			if calc != given:
				errors.append("%s 規則「例」矛盾:L = %d 依規則(中段圖塊寬 %d)應為 W = %d、n = %d、r = %d,設計稿寫 W = %d、n = %d、r = %d" % [PADDLE_ITEM, L, r["tile_w"], calc[0], calc[1], calc[2], given[0], given[1], given[2]])

	# 要產生的長度：最短、各道具長度、基準、最大，去重後由小到大
	var all := {r["min"]: true, r["max"]: true, r["base"]: true}
	for k in item_names:
		all[item_names[k]] = true
	var list := all.keys()
	list.sort()
	for L in list:
		if L < r["min"] or L > r["max"]:
			errors.append("%s 長度 %d 超出範圍 %d~%d" % [PADDLE_ITEM, L, r["min"], r["max"]])
		if L < r["end_l"] + r["end_r"]:
			errors.append("%s 長度 %d 小於左右兩端寬度和 %d" % [PADDLE_ITEM, L, r["end_l"] + r["end_r"]])
	if not list.has(BOARD_PADDLE_LEN):
		errors.append("示意盤面需要長度 %d 的擋板，但 %s 的長度清單沒有" % [BOARD_PADDLE_LEN, PADDLE_ITEM])
	r["lengths"] = list
	if errors.size() > before:
		return {}
	return r


## 把「圖高(對象):N」的對象對應到分段 id,回傳 {id: 應有高度}。
## 對應方式(依設計稿固定句型的字詞，寫死於此):
##   含「完整圖」→ 依「正常」「吸附」「槍」對應 paddle_normal_64 / paddle_sticky_64 / paddle_gun_64;
##   含「槍左端」「槍右端」→ paddle_gun_left / paddle_gun_right;
##   「本體」→ 其餘尚未指定的分段(本體段、中段圖塊)。
## 看不懂的對象、同一分段兩個不同高度、有分段沒有對應高度，都記錄為錯誤。specs 為空時回傳空字典。
func height_targets(ids: Array, specs: Array, errors: PackedStringArray) -> Dictionary:
	var out := {}
	if specs.is_empty():
		return out
	var body := -1
	for s in specs:
		var target: String = s[0]
		var hit_ids := []
		if target.contains("完整圖"):
			for pair in [["正常", "paddle_normal_64"], ["吸附", "paddle_sticky_64"], ["槍", "paddle_gun_64"]]:
				if target.contains(pair[0]):
					hit_ids.append(pair[1])
		elif target.contains("槍左端"):
			hit_ids.append("paddle_gun_left")
		elif target.contains("槍右端"):
			hit_ids.append("paddle_gun_right")
		elif target == "本體":
			if body >= 0 and body != s[1]:
				errors.append("%s 規則矛盾：圖高(本體)出現兩個值 %d 與 %d" % [PADDLE_ITEM, body, s[1]])
			body = s[1]
			continue
		if hit_ids.is_empty():
			errors.append("%s 看不懂「圖高(%s)」的對象(可用：本體、槍左端、槍右端、完整圖 + 正常/吸附/槍)" % [PADDLE_ITEM, target])
		for id in hit_ids:
			if out.has(id) and out[id] != s[1]:
				errors.append("%s 規則矛盾:%s 的圖高同時寫了 %d 與 %d" % [PADDLE_ITEM, id, out[id], s[1]])
			out[id] = s[1]
	for id in ids:
		if out.has(id):
			continue
		if body >= 0:
			out[id] = body
		else:
			errors.append("%s 找不到分段 %s 的圖高(沒有「圖高(本體):N」)" % [PADDLE_ITEM, id])
	return out


## 在網格上方補 rows 列透明，使其高度變成 h(底部對齊用)。
func pad_top(grid: PackedStringArray, h: int) -> PackedStringArray:
	var out := PackedStringArray()
	var blank := ".".repeat(grid[0].length())
	for i in h - grid.size():
		out.append(blank)
	out.append_array(grid)
	return out


## 依拼接規則組出長度 L 的擋板網格。
## 三段底部對齊：整條高 = 三段的最大高，較矮的段上方補透明(使用者決定，設計稿未寫)。
## 中段 = 中段圖塊重複 n 次，再補中段圖塊最左邊 r 欄的裁切圖塊。
func compose_paddle(left: PackedStringArray, mid: PackedStringArray, right: PackedStringArray, L: int, r: Dictionary) -> PackedStringArray:
	var h: int = max(left.size(), mid.size(), right.size())
	var lg := pad_top(left, h)
	var mg := pad_top(mid, h)
	var rg := pad_top(right, h)
	var w: int = L - r["end_l"] - r["end_r"]
	var n: int = w / r["tile_w"]
	var rem: int = w % r["tile_w"]
	var out := PackedStringArray()
	for y in h:
		out.append(lg[y] + mg[y].repeat(n) + mg[y].substr(0, rem) + rg[y])
	return out


## 產生 PADDLE_SETS 的各張擋板圖。每張由上到下：各長度正常版，再各長度被擊中版;
## 每列寬 = 最大長度、高 = 該狀態整條高，擋板靠左，其餘透明。
## 回傳格式同 build_sprite_sheets,另含 by_length(正常版)與 height。
func build_paddle_sheets(blocks: Array, r: Dictionary, palette: Dictionary, errors: PackedStringArray) -> Dictionary:
	var g := {}
	for b in blocks:
		if b["item"] == PADDLE_ITEM:
			g[b["name"].trim_prefix(PADDLE_ITEM + "_")] = b["grid"]
	var before := errors.size()

	# 每個分段的寬須等於對應尺寸;高須在「圖高」清單內
	var need_w := {}
	for set_name in PADDLE_SETS:
		for k in 3:
			need_w[PADDLE_SETS[set_name][k]] = [r["end_l"], r["tile_w"], r["end_r"]][k]
	for set_name in PADDLE_REFERENCE:
		need_w[PADDLE_REFERENCE[set_name]] = r["full_w"]
	var need_h := height_targets(need_w.keys(), r["height_specs"], errors)
	var used_heights := {}
	for id in need_w:
		if not g.has(id):
			errors.append("%s 缺少分段 %s(標題須含「(id: %s)」)" % [PADDLE_ITEM, id, id])
			continue
		var gw: int = g[id][0].length()
		var gh: int = g[id].size()
		used_heights[gh] = true
		if gw != need_w[id]:
			errors.append("%s_%s 寬 %d,應為 %d" % [PADDLE_ITEM, id, gw, need_w[id]])
		if need_h.has(id):
			if gh != need_h[id]:
				errors.append("%s_%s 高 %d,但設計稿寫圖高 %d" % [PADDLE_ITEM, id, gh, need_h[id]])
		elif not r["heights"].has(gh):
			errors.append("%s_%s 高 %d,不在設計稿的圖高清單 %s 內" % [PADDLE_ITEM, id, gh, str(r["heights"])])
	if errors.size() == before:
		for h in r["heights"]:
			if not used_heights.has(h):
				errors.append("%s 規則矛盾：圖高清單有 %d,但沒有任何分段是這個高度" % [PADDLE_ITEM, h])
	if errors.size() > before:
		return {}
	var max_h: int = r["heights"].max()
	if BOARD_PADDLE_Y < 0 or BOARD_PADDLE_Y + max_h > BOARD_H:
		errors.append("BOARD_PADDLE_Y = %d 使擋板超出畫布高度 %d" % [BOARD_PADDLE_Y, BOARD_H])
		return {}

	var out := {}
	for set_name in PADDLE_SETS:
		var ids: Array = PADDLE_SETS[set_name]
		var by_length := {}
		var normal_rows := PackedStringArray()
		var hit_rows := PackedStringArray()
		var height := 0
		for L in r["lengths"]:
			var p := compose_paddle(g[ids[0]], g[ids[1]], g[ids[2]], L, r)
			height = p.size()
			by_length[L] = p
			var hp := hit_grid(p, r["hit_keep"], r["hit_to"])
			var pad := ".".repeat(r["max"] - L)
			for y in p.size():
				normal_rows.append(p[y] + pad)
				hit_rows.append(hp[y] + pad)
		if PADDLE_REFERENCE.has(set_name):
			var ref_id: String = PADDLE_REFERENCE[set_name]
			var ref: PackedStringArray = g[ref_id]
			var built := compose_paddle(g[ids[0]], g[ids[1]], g[ids[2]], ref[0].length(), r)
			if built != ref:
				errors.append("%s 規則矛盾：依拼接規則(底部對齊)組出的 %s 長度 %d(%d×%d)與完整圖 %s(%d×%d)不同" % [PADDLE_ITEM, set_name, ref[0].length(), built[0].length(), built.size(), ref_id, ref[0].length(), ref.size()])
		if r["set_heights"].has(set_name) and r["set_heights"][set_name] != height:
			errors.append("%s 規則矛盾：「高度與對齊」寫 %s 整條高 %d,但依各段底部對齊組出 %d" % [PADDLE_ITEM, set_name, r["set_heights"][set_name], height])
		var grid := normal_rows + hit_rows
		var msg := validate_grid(grid, palette)
		if msg != "":
			errors.append("產生的 %s: %s" % [set_name, msg])
		out[set_name] = {"grid": grid, "by_length": by_length, "height": height}
	if errors.size() > before:
		return {}
	return out


# ---------------------------------------------------------------- 繪製

func render_grid(grid: PackedStringArray, palette: Dictionary) -> Image:
	var img := Image.create_empty(grid[0].length(), grid.size(), false, Image.FORMAT_RGBA8)
	for y in grid.size():
		var row := grid[y]
		for x in row.length():
			img.set_pixel(x, y, palette[row[x]])
	return img


## 最近鄰放大，像素邊緣不會模糊。
func scaled(img: Image, factor: int) -> Image:
	var out := img.duplicate() as Image
	out.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	return out


func save(img: Image, path: String) -> int:
	var err := img.save_png(path)
	if err != OK:
		printerr("寫入失敗: %s (%s)" % [path, error_string(err)])
	return err


## 寫出 JSON(UTF-8,保留鍵的插入順序)。回傳 OK 或錯誤碼。
func save_json(data: Dictionary, path: String) -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		var err := FileAccess.get_open_error()
		printerr("寫入失敗: %s (%s)" % [path, error_string(err)])
		return err
	f.store_string(JSON.stringify(data, "  ", false) + "\n")
	f.close()
	return OK


## 只刪除本工具產生的檔名格式，避免設計稿改名後留下過期的 PNG;其他檔案不動。
func clean_old_outputs(out_dir: String, sprite_dir: String) -> void:
	var targets := [[out_dir, "^(D\\d+_.+|overview|board_sample(_x\\d+)?)\\.png$"],
		[sprite_dir, "^((bricks?|paddle|laser_beam|rainbow)_[a-z0-9_]+(_x\\d+)?\\.png|layer_map\\.json|laser_beam_layout\\.json)$"]]
	for t in targets:
		var own_re := RegEx.create_from_string(t[1])
		var dir := DirAccess.open(t[0])
		if dir == null:
			continue
		for fname in dir.get_files():
			if own_re.search(fname):
				dir.remove(fname)


func text_width(text: String, scale: int) -> int:
	return max(text.length() * 4 - 1, 0) * scale


## 用自繪 3×5 字在圖上寫字。找不到的字元以大寫查，仍沒有就留空。
func draw_text(img: Image, text: String, x: int, y: int, scale: int, color: Color) -> void:
	var cx := x
	for ch in text:
		var glyph = FONT.get(ch, FONT.get(ch.to_upper(), FONT[" "]))
		for gy in 5:
			for gx in 3:
				if glyph[gy][gx] == "#":
					img.fill_rect(Rect2i(cx + gx * scale, y + gy * scale, scale, scale), color)
		cx += 4 * scale


## 總覽圖：依 D 項目分區，每區先放標題，再由左到右排列圖片(×6),每張下方標檔名。
## D01 區放色票(代號 + HEX)。先算版面高度再一次繪製。
func build_overview(blocks: Array, images: Dictionary, palette: Dictionary) -> Image:
	var label_h := 5 * LABEL_SCALE
	var header_h := 5 * HEADER_SCALE

	# 依出現順序分組;D01 色票排在最前面
	var sections := [{"item": "D01", "entries": []}]
	for code in palette:
		if palette[code].a8 == 0:
			continue
		var c: Color = palette[code]
		var sw := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
		sw.fill(c)
		sections[0]["entries"].append({"img": sw, "label": code, "label2": c.to_html(false).to_upper(), "keep_case": true})
	for b in blocks:
		if sections[-1]["item"] != b["item"]:
			sections.append({"item": b["item"], "entries": []})
		sections[-1]["entries"].append({"img": images[b["name"]], "label": b["name"], "label2": "", "keep_case": false})

	# 第一遍：計算每個項目的位置
	var placements := []  # [類型, 資料, x, y]
	var y := OVERVIEW_MARGIN
	for sec in sections:
		placements.append(["header", sec["item"], OVERVIEW_MARGIN, y])
		y += header_h + 12
		var x := OVERVIEW_MARGIN
		var row_h := 0
		for e in sec["entries"]:
			var img: Image = e["img"]
			var iw: int = img.get_width() * SCALE_OVERVIEW
			var ih: int = img.get_height() * SCALE_OVERVIEW
			var lw := text_width(e["label"] if e["keep_case"] else e["label"].to_upper(), LABEL_SCALE)
			lw = max(lw, text_width(e["label2"], LABEL_SCALE))
			var item_w: int = max(iw, lw)
			var item_h: int = ih + 6 + label_h + (label_h + 4 if e["label2"] != "" else 0)
			if x > OVERVIEW_MARGIN and x + item_w > OVERVIEW_WIDTH - OVERVIEW_MARGIN:
				x = OVERVIEW_MARGIN
				y += row_h + OVERVIEW_GAP_Y
				row_h = 0
			placements.append(["entry", e, x, y])
			x += item_w + OVERVIEW_GAP_X
			row_h = max(row_h, item_h)
		y += row_h + OVERVIEW_SECTION_GAP

	var out := Image.create_empty(OVERVIEW_WIDTH, y - OVERVIEW_SECTION_GAP + OVERVIEW_MARGIN, false, Image.FORMAT_RGBA8)
	out.fill(BG_COLOR)

	# 第二遍：繪製
	for p in placements:
		if p[0] == "header":
			draw_text(out, p[1], p[2], p[3], HEADER_SCALE, HEADER_COLOR)
			continue
		var e: Dictionary = p[1]
		var big := scaled(e["img"], SCALE_OVERVIEW)
		out.fill_rect(Rect2i(p[2], p[3], big.get_width(), big.get_height()), FRAME_COLOR)
		# blend_rect 讓 alpha 0 的像素透出底框，不透明像素維持原色
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(p[2], p[3]))
		var ly: int = p[3] + big.get_height() + 6
		draw_text(out, e["label"] if e["keep_case"] else e["label"].to_upper(), p[2], ly, LABEL_SCALE, TEXT_COLOR)
		if e["label2"] != "":
			draw_text(out, e["label2"], p[2], ly + label_h + 4, LABEL_SCALE, TEXT_COLOR)
	return out


## 檢查 BOARD_LAYOUT:每列 10 格、代號有效、層數在 1~LAYER_MAX、魔王 4×3 範圍完整且置中於第 4~7 欄、
## 不超出畫布。回傳錯誤訊息列表(沒問題為空)。在寫任何檔案之前呼叫。
func check_board_requirements() -> PackedStringArray:
	var errors := PackedStringArray()
	var cells := []
	for r in BOARD_LAYOUT.size():
		var tokens: PackedStringArray = BOARD_LAYOUT[r].split(" ", false)
		if tokens.size() != BOARD_COLS:
			errors.append("BOARD_LAYOUT(從 0 起算)第 %d 列有 %d 格，應為 %d 格" % [r, tokens.size(), BOARD_COLS])
		cells.append(tokens)
	if not errors.is_empty():
		return errors
	var covered := {}
	for r in cells.size():
		for c in BOARD_COLS:
			if cells[r][c] != "X":
				continue
			if c != 3:
				errors.append("BOARD_LAYOUT 魔王(從 0 起算第 %d 列)應置中於第 3~6 欄(從 0 起算，即 D12 的「第 4~7 欄」),左上角放在第 3 欄" % [r])
			for yy in range(r, r + 3):
				for xx in range(c, c + 4):
					if yy == r and xx == c:
						continue
					if yy >= cells.size() or xx >= BOARD_COLS or cells[yy][xx] != "-":
						errors.append("BOARD_LAYOUT 魔王(從 0 起算第 %d 列第 %d 欄)的 4×3 範圍內應全為「-」" % [r, c])
					covered[Vector2i(xx, yy)] = true
	for r in cells.size():
		for c in BOARD_COLS:
			var t: String = cells[r][c]
			if t == "-" and not covered.has(Vector2i(c, r)):
				errors.append("BOARD_LAYOUT(從 0 起算)第 %d 列第 %d 欄的「-」不在任何魔王範圍內" % [r, c])
			elif t.is_valid_int() and (t.to_int() < 1 or t.to_int() > LAYER_MAX):
				errors.append("BOARD_LAYOUT(從 0 起算)第 %d 列第 %d 欄的層數 %s 超出 1~%d" % [r, c, t, LAYER_MAX])
			elif not t.is_valid_int() and not BOARD_COLOR_TOKENS.has(t) and not (t in ["C", "$", "@", "X", "-", "."]):
				errors.append("BOARD_LAYOUT(從 0 起算)第 %d 列第 %d 欄的代號「%s」無效" % [r, c, t])
	if BOARD_TOP + cells.size() * CELL_H > BOARD_H:
		errors.append("BOARD_LAYOUT 共 %d 列，超出畫布高度 %d" % [cells.size(), BOARD_H])
	if BOARD_BORDER * 2 + BOARD_COLS * CELL_W != BOARD_W:
		errors.append("盤面寬度設定不一致：邊框 %d×2 + %d 欄×%d ≠ %d" % [BOARD_BORDER, BOARD_COLS, CELL_W, BOARD_W])
	return errors


## 示意盤面(360×640):左右各 20 px 暫用單色邊框，中間 10 欄依 BOARD_LAYOUT 拼上各磚的「正常」幀。
## 呼叫前須先通過 check_board_requirements 與精靈圖產生。
func build_board(sheets: Dictionary, palette: Dictionary) -> Image:
	var out := Image.create_empty(BOARD_W, BOARD_H, false, Image.FORMAT_RGBA8)
	out.fill(BG_COLOR)
	out.fill_rect(Rect2i(0, 0, BOARD_BORDER, BOARD_H), BORDER_COLOR)
	out.fill_rect(Rect2i(BOARD_W - BOARD_BORDER, 0, BOARD_BORDER, BOARD_H), BORDER_COLOR)
	for row in BOARD_LAYOUT.size():
		var tokens: PackedStringArray = BOARD_LAYOUT[row].split(" ", false)
		for col in tokens.size():
			var t := tokens[col]
			var grid: PackedStringArray
			if BOARD_COLOR_TOKENS.has(t):
				grid = sheets["bricks_normal"]["frames"][COLOR_ORDER.find(BOARD_COLOR_TOKENS[t])][0]
			elif t.is_valid_int():
				grid = sheets["bricks_multi"]["frames"][t.to_int() - 1][0]
			elif t == "C":
				grid = sheets["brick_chest"]["frames"][0][0]
			elif t == "$":
				grid = sheets["brick_coin"]["frames"][0][0]
			elif t == "@":
				grid = sheets["brick_round"]["frames"][0][0]
			elif t == "X":
				grid = sheets["brick_boss"]["frames"][0][0]
			else:
				continue  # "." 空格、"-" 魔王覆蓋
			var img := render_grid(grid, palette)
			out.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(BOARD_BORDER + col * CELL_W, BOARD_TOP + row * CELL_H))

	# 下方擋板：基準長度正常版，水平置中
	var paddle := render_grid(sheets["paddle_normal"]["by_length"][BOARD_PADDLE_LEN], palette)
	out.blend_rect(paddle, Rect2i(Vector2i.ZERO, paddle.get_size()), Vector2i((BOARD_W - paddle.get_width()) / 2, BOARD_PADDLE_Y))
	return out
