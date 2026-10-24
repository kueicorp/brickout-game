extends SceneTree
## 像素圖預覽轉檔工具。
##
## 讀取設計稿 pixel-art-bricks.md:
##   1. 每個 ```text 區塊(一字元 = 一像素)轉成單張 PNG 與 ×8 放大版;
##   2. 依 D12「自動產生規則」與換色對照表，由母版產生各磚種的精靈圖(sprites/);
##   3. 依 D13 拼接規則，由擋板分段拼出各長度、各狀態的擋板圖(sprites/paddle_*.png);
##   4. 產生總覽圖 overview.png 與示意盤面 board_sample.png。
## 調色盤、換色表、被擊中規則、數字位置、裂痕範圍、層與數字對應、擋板長度與拼接參數都從設計稿解析，
## 設計稿改了重新執行即可更新。任何解析或檢查錯誤都會在刪檔、寫檔之前擋下。
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
##   R O Y G B I V = 一般磚紅橙黃綠藍靛紫;數字 1~14 = 多層磚層數;C = 寶箱;$ = 金幣;
##   @ = 圓形;X = 魔王左上角(佔 4×3 格;置中須放在從 0 起算的第 3 欄，即 D12 的「第 4~7 欄」);- = 被魔王覆蓋;. = 空格
const BOARD_LAYOUT := [
	"R O Y X - - - G B I",
	"V R O - - - - Y G B",
	"I V R - - - - O Y G",
	"1 2 3 C 5 $ 9 10 13 14",
	"B I V @ R @ O Y G R",
	"G C Y 10 11 12 Y $ O V",
	"R O Y G B I V R O Y",
	". 4 . 7 @ 13 . 6 . 8",
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
	if errors.is_empty():
		var rules := parse_rules(section_lines(lines, RULE_ITEM), palette, errors)
		if errors.is_empty():
			sheets = build_sprite_sheets(blocks, rules, palette, errors)
		# 擋板規則與磚塊規則各自獨立，兩邊的錯誤一起列出
		var prules := parse_paddle_rules(section_lines(lines, PADDLE_ITEM), errors)
		if not prules.is_empty():
			var psheets := build_paddle_sheets(blocks, prules, palette, errors)
			for k in psheets:
				sheets[k] = psheets[k]
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

	for sheet_name in sheets:
		var img := render_grid(sheets[sheet_name]["grid"], palette)
		if save(img, sprite_dir.path_join(sheet_name + ".png")) != OK:
			return 1
		if save(scaled(img, SCALE_SPRITE), sprite_dir.path_join("%s_x%d.png" % [sheet_name, SCALE_SPRITE])) != OK:
			return 1
		print("%-26s %dx%d" % [SPRITE_DIR + "/" + sheet_name, img.get_width(), img.get_height()])

	if save(build_overview(blocks, images, palette), out_dir.path_join("overview.png")) != OK:
		return 1

	var board := build_board(sheets, palette)
	if save(board, out_dir.path_join("board_sample.png")) != OK:
		return 1
	if save(scaled(board, SCALE_BOARD), out_dir.path_join("board_sample_x%d.png" % SCALE_BOARD)) != OK:
		return 1

	print("完成：%d 個區塊、%d 張精靈圖，輸出到 %s" % [blocks.size(), sheets.size(), out_dir])
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
## 回傳欄位：
##   source(母版色階代號陣列，T1~T5)、tiers({顏色名: 5 個代號})、
##   hit_keep(被擊中不變的字元)、hit_to(被擊中改成的字元)、swap_keep(換色時不變的字元)、
##   frame_colors({寶箱/金幣/圓形: 顏色名})、digit_ink、digit_w、digit_h、digit_x、digit_y、
##   crack(x0,x1,y0,y1,from,to)、layers(Array[{from,to,digit_from,color}])
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

	parse_swap_table(sec, palette, rules, errors)

	# 被擊中：「除 `K`、`.` 以外的像素全部改成 `W`」
	var text := find_rule(rule_rows, "被擊中", errors)
	if text != "":
		var m := RegEx.create_from_string("除(.+?)以外的像素全部改成\\s*`(.)`").search(text)
		if m == null or backticks(m.get_string(1)).is_empty():
			errors.append("%s 規則「被擊中」格式無法解析(預期「除 `K`、`.` 以外的像素全部改成 `W`」): %s" % [RULE_ITEM, text])
		else:
			rules["hit_keep"] = backticks(m.get_string(1))
			rules["hit_to"] = m.get_string(2)

	# 一般磚七色：「`K`、`W`、`G`、`.` 不變」
	text = find_rule(rule_rows, "一般磚七色", errors)
	if text != "":
		var m := RegEx.create_from_string("((?:`.`\\s*" + RE_COMMA + "?\\s*)+)不變").search(text)
		if m == null:
			errors.append("%s 規則「一般磚七色」找不到「…不變」的字元清單: %s" % [RULE_ITEM, text])
		else:
			rules["swap_keep"] = backticks(m.get_string(1))

	# 通用破壞：基準色階須與換色表母版欄一致;各特殊磚的色階
	text = find_rule(rule_rows, "通用破壞", errors)
	if text != "":
		var m := RegEx.create_from_string("以\\S*色階\\s*`([^`]+)`").search(text)
		if m == null:
			errors.append("%s 規則「通用破壞」找不到基準色階: %s" % [RULE_ITEM, text])
		elif rules.has("source") and m.get_string(1).split(" ", false) != rules["source"]:
			errors.append("%s 規則矛盾：通用破壞的基準色階 `%s` 與換色對照表母版欄 %s 不同" % [RULE_ITEM, m.get_string(1), " ".join(rules["source"])])
		var colors := {}
		var re := RegEx.create_from_string("(寶箱|金幣|圓形)\\s*" + RE_LPAREN + "\\s*([^)\uFF09]+?)\\s*" + RE_RPAREN)
		for mm in re.search_all(text):
			colors[mm.get_string(1)] = mm.get_string(2)
		for need in ["寶箱", "金幣", "圓形"]:
			if not colors.has(need):
				errors.append("%s 規則「通用破壞」沒有寫明%s的色階(預期如「%s(%s)」)" % [RULE_ITEM, need, need, {"寶箱": "橙", "金幣": "黃", "圓形": "紫"}[need]])
			elif rules.has("tiers") and not rules["tiers"].has(colors[need]):
				errors.append("%s 規則「通用破壞」的%s色階「%s」不在換色對照表內" % [RULE_ITEM, need, colors[need]])
		rules["frame_colors"] = colors

	# 多層磚組合：數字墨色、字形尺寸、左上角位置、裂痕範圍
	text = find_rule(rule_rows, "多層磚組合", errors)
	if text != "":
		var m := RegEx.create_from_string("數字墨色\\s*`(.)`").search(text)
		if m == null:
			errors.append("%s 規則「多層磚組合」找不到「數字墨色 `K`」" % RULE_ITEM)
		else:
			rules["digit_ink"] = m.get_string(1)
		m = RegEx.create_from_string("字形\\s*(\\d+)\\s*[×x\u00D7]\\s*(\\d+)").search(text)
		if m == null:
			errors.append("%s 規則「多層磚組合」找不到「字形 5×7」" % RULE_ITEM)
		else:
			rules["digit_w"] = m.get_string(1).to_int()
			rules["digit_h"] = m.get_string(2).to_int()
		m = RegEx.create_from_string("左上角放在第\\s*(\\d+)\\s*欄" + RE_COMMA + "\\s*第\\s*(\\d+)\\s*列").search(text)
		if m == null:
			errors.append("%s 規則「多層磚組合」找不到「左上角放在第 N 欄、第 N 列」" % RULE_ITEM)
		else:
			# 欄列編號為 0 起算：依 D12「層 7 藍範例」「層 3 綠範例」網格反推(第 13 欄 = 索引 13)
			rules["digit_x"] = m.get_string(1).to_int()
			rules["digit_y"] = m.get_string(2).to_int()
		m = RegEx.create_from_string("第\\s*(\\d+)\\s*" + RE_TILDE + "\\s*(\\d+)\\s*欄" + RE_COMMA + "\\s*第\\s*(\\d+)\\s*" + RE_TILDE + "\\s*(\\d+)\\s*列的\\s*T(\\d)\\s*像素\\S*\\s*換成\\s*T(\\d)").search(text)
		if m == null:
			errors.append("%s 規則「多層磚組合」找不到裂痕範圍(預期「第 a~b 欄、第 c~d 列的 T5 像素)換成 T3」)" % RULE_ITEM)
		else:
			rules["crack"] = {"x0": m.get_string(1).to_int(), "x1": m.get_string(2).to_int(),
				"y0": m.get_string(3).to_int(), "y1": m.get_string(4).to_int(),
				"from_tier": m.get_string(5).to_int(), "to_tier": m.get_string(6).to_int()}

	# 數字與層對應：「層 1~9 顯示 1~9(藍);層 10~14 顯示 0~4(綠)」
	text = find_rule(rule_rows, "數字與層對應", errors)
	if text != "":
		var re := RegEx.create_from_string("層\\s*(\\d+)\\s*" + RE_TILDE + "\\s*(\\d+)\\s*顯示\\s*(\\d+)\\s*" + RE_TILDE + "\\s*(\\d+)\\s*" + RE_LPAREN + "\\s*([^)\uFF09]+?)\\s*" + RE_RPAREN)
		var layers := []
		for mm in re.search_all(text):
			var seg := {"from": mm.get_string(1).to_int(), "to": mm.get_string(2).to_int(),
				"digit_from": mm.get_string(3).to_int(), "digit_to": mm.get_string(4).to_int(), "color": mm.get_string(5)}
			if seg["to"] - seg["from"] != seg["digit_to"] - seg["digit_from"]:
				errors.append("%s 規則矛盾：層 %d~%d 有 %d 層，但數字 %d~%d 有 %d 個" % [RULE_ITEM, seg["from"], seg["to"], seg["to"] - seg["from"] + 1, seg["digit_from"], seg["digit_to"], seg["digit_to"] - seg["digit_from"] + 1])
			if seg["digit_from"] < 0 or seg["digit_to"] >= DIGIT_COUNT:
				errors.append("%s 規則「數字與層對應」的數字超出 0~9" % RULE_ITEM)
			if rules.has("tiers") and not rules["tiers"].has(seg["color"]):
				errors.append("%s 規則「數字與層對應」的顏色「%s」不在換色對照表內" % [RULE_ITEM, seg["color"]])
			layers.append(seg)
		# 層須從 1 開始連續、不重疊
		layers.sort_custom(func(a, b): return a["from"] < b["from"])
		var expect := 1
		for seg in layers:
			if seg["from"] != expect:
				errors.append("%s 規則「數字與層對應」的層數不連續：預期從層 %d 開始，實際為層 %d" % [RULE_ITEM, expect, seg["from"]])
			expect = seg["to"] + 1
		if layers.is_empty():
			errors.append("%s 規則「數字與層對應」格式無法解析(預期「層 1~9 顯示 1~9(藍)」): %s" % [RULE_ITEM, text])
		rules["layers"] = layers

	# 裂痕的 T 階換成實際代號(母版為紅色階)
	if rules.has("crack") and rules.has("source"):
		var c: Dictionary = rules["crack"]
		for k in ["from_tier", "to_tier"]:
			if c[k] < 1 or c[k] > rules["source"].size():
				errors.append("%s 規則「多層磚組合」的裂痕色階 T%d 超出範圍" % [RULE_ITEM, c[k]])
				return rules
		c["from"] = rules["source"][c["from_tier"] - 1]
		c["to"] = rules["source"][c["to_tier"] - 1]
	return rules


## 解析換色對照表：表頭第一欄為「目標」,其後各欄含 `T 階` 與母版代號(如「T1(`h`)」)。
## 結果寫入 rules["source"] 與 rules["tiers"]。
func parse_swap_table(sec: PackedStringArray, palette: Dictionary, rules: Dictionary, errors: PackedStringArray) -> void:
	var header_at := -1
	for k in sec.size():
		var cells := table_cells(sec[k])
		if cells.size() > 0 and cells[0] == "目標":
			if header_at >= 0:
				errors.append("%s 有兩個以上「目標」開頭的換色對照表" % RULE_ITEM)
				return
			header_at = k
	if header_at < 0:
		errors.append("%s 找不到換色對照表(表頭第一欄應為「目標」)" % RULE_ITEM)
		return

	var header := table_cells(sec[header_at])
	var source := PackedStringArray()
	for k in range(1, header.size()):
		var codes := backticks(header[k])
		var tm := RegEx.create_from_string("T(\\d)").search(header[k])
		if codes.size() != 1 or codes[0].length() != 1 or tm == null or tm.get_string(1).to_int() != k:
			errors.append("%s 換色對照表表頭(從 0 起算)第 %d 欄格式錯誤(預期「T%d(`代號`)」): %s" % [RULE_ITEM, k, k, header[k]])
			return
		source.append(codes[0])
	if source.is_empty():
		errors.append("%s 換色對照表表頭沒有色階欄" % RULE_ITEM)
		return

	var tiers := {}
	var k2 := header_at + 1
	while k2 < sec.size():
		var cells := table_cells(sec[k2])
		if cells.is_empty():
			break
		k2 += 1
		if cells[0].begins_with("---"):
			continue
		if cells.size() != source.size() + 1:
			errors.append("%s 換色對照表「%s」列有 %d 欄，應為 %d 欄" % [RULE_ITEM, cells[0], cells.size(), source.size() + 1])
			continue
		var codes := PackedStringArray()
		for c in range(1, cells.size()):
			var b := backticks(cells[c])
			if b.size() != 1 or b[0].length() != 1:
				errors.append("%s 換色對照表「%s」列(從 0 起算)第 %d 欄格式錯誤: %s" % [RULE_ITEM, cells[0], c, cells[c]])
				break
			if not palette.has(b[0]):
				errors.append("%s 換色對照表「%s」列的代號 `%s` 不在 D01 調色盤" % [RULE_ITEM, cells[0], b[0]])
			codes.append(b[0])
		if codes.size() != source.size():
			continue
		if tiers.has(cells[0]):
			errors.append("%s 換色對照表的「%s」重複出現" % [RULE_ITEM, cells[0]])
		tiers[cells[0]] = codes
	for name in COLOR_ORDER:
		if not tiers.has(name):
			errors.append("%s 換色對照表缺少「%s」" % [RULE_ITEM, name])
	if tiers.has("紅") and tiers["紅"] != source:
		errors.append("%s 換色對照表矛盾：「紅」列 %s 與表頭母版欄 %s 不同" % [RULE_ITEM, " ".join(tiers["紅"]), " ".join(source)])
	rules["source"] = source
	rules["tiers"] = tiers


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


## 依規則產生所有精靈圖。回傳 {檔名: {"grid": 網格, "frames": Array[Array[網格]]}};錯誤附加到 errors。
## 每張圖每列 6 格：正常、被擊中、F1、F2、F3、F4。
func build_sprite_sheets(blocks: Array, rules: Dictionary, palette: Dictionary, errors: PackedStringArray) -> Dictionary:
	var g := {}
	for b in blocks:
		if b["item"] == RULE_ITEM:
			g[b["name"].trim_prefix(RULE_ITEM + "_")] = b["grid"]

	# 母版需求：名稱 → 尺寸
	var need := {"brick_normal": [CELL_W, CELL_H], "chest_normal": [CELL_W, CELL_H], "coin_normal": [CELL_W, CELL_H],
		"round_normal": [CELL_W, CELL_H], "f1": [CELL_W, CELL_H], "f2": [CELL_W, CELL_H], "f3": [CELL_W, CELL_H],
		"f4": [CELL_W, CELL_H], "round_f1": [CELL_W, CELL_H], "round_f2": [CELL_W, CELL_H],
		"boss_normal": [BOSS_W, BOSS_H], "boss_overlay": [BOSS_W, BOSS_H], "boss_f2": [BOSS_W, BOSS_H],
		"boss_f3": [BOSS_W, BOSS_H], "boss_f4": [BOSS_W, BOSS_H]}
	for d in DIGIT_COUNT:
		need["digit%d" % d] = [rules["digit_w"], rules["digit_h"]]
	for n in need:
		if not g.has(n):
			errors.append("%s 缺少母版區塊 %s_%s(依標題命名，見 slug_from_title)" % [RULE_ITEM, RULE_ITEM, n])
		elif g[n][0].length() != need[n][0] or g[n].size() != need[n][1]:
			errors.append("%s_%s 尺寸 %dx%d,應為 %dx%d" % [RULE_ITEM, n, g[n][0].length(), g[n].size(), need[n][0], need[n][1]])
	if not errors.is_empty():
		return {}

	var source: PackedStringArray = rules["source"]
	var keep: PackedStringArray = rules["hit_keep"]
	var hit_to: String = rules["hit_to"]
	var swap_keep: PackedStringArray = rules["swap_keep"]

	# 換色前檢查：會換色的母版只能含母版色階與「不變」清單內的字元，否則換色結果不明確
	for n in ["brick_normal", "f1", "f2", "f3", "f4"]:
		for row in g[n]:
			for c in row:
				if not source.has(c) and not swap_keep.has(c):
					errors.append("%s_%s 含換色規則未涵蓋的代號 `%s`(不在母版色階 %s,也不在「不變」清單)" % [RULE_ITEM, n, c, " ".join(source)])
					return {}

	var maps := {}
	for name in rules["tiers"]:
		var mp := {}
		for k in source.size():
			mp[source[k]] = rules["tiers"][name][k]
		maps[name] = mp
	var generic := func(color: String) -> Array:
		return [swap_grid(g["f1"], maps[color]), swap_grid(g["f2"], maps[color]), swap_grid(g["f3"], maps[color]), swap_grid(g["f4"], maps[color])]

	# 數字：只能有 `.` 與墨色
	var ink: String = rules["digit_ink"]
	for d in DIGIT_COUNT:
		for row in g["digit%d" % d]:
			for c in row:
				if c != "." and c != ink:
					errors.append("%s_digit%d 含墨色 `%s` 以外的字元 `%s`" % [RULE_ITEM, d, ink, c])
					return {}
	var dx: int = rules["digit_x"]
	var dy: int = rules["digit_y"]
	if dx < 0 or dy < 0 or dx + rules["digit_w"] > CELL_W or dy + rules["digit_h"] > CELL_H:
		errors.append("%s 數字位置(從 0 起算第 %d 欄、第 %d 列)加上字形 %dx%d 超出磚格 %dx%d" % [RULE_ITEM, dx, dy, rules["digit_w"], rules["digit_h"], CELL_W, CELL_H])
	var crack: Dictionary = rules["crack"]
	if crack["x0"] < 0 or crack["x1"] >= CELL_W or crack["y0"] < 0 or crack["y1"] >= CELL_H or crack["x0"] > crack["x1"] or crack["y0"] > crack["y1"]:
		errors.append("%s 裂痕範圍(從 0 起算第 %d~%d 欄、第 %d~%d 列)超出磚格" % [RULE_ITEM, crack["x0"], crack["x1"], crack["y0"], crack["y1"]])
	if not errors.is_empty():
		return {}

	var sheets := {}

	# 一般磚七色
	var rows := []
	for color in COLOR_ORDER:
		var normal := swap_grid(g["brick_normal"], maps[color])
		rows.append([normal, hit_grid(normal, keep, hit_to)] + generic.call(color))
	sheets["bricks_normal"] = rows

	# 多層磚：母版去裂痕 → 換色 → 疊數字
	var plain := replace_in_rect(g["brick_normal"], crack["x0"], crack["x1"], crack["y0"], crack["y1"], crack["from"], crack["to"])
	rows = []
	for seg in rules["layers"]:
		for layer in range(seg["from"], seg["to"] + 1):
			var digit: int = seg["digit_from"] + layer - seg["from"]
			var normal := overlay_grid(swap_grid(plain, maps[seg["color"]]), g["digit%d" % digit], dx, dy, ink)
			rows.append([normal, hit_grid(normal, keep, hit_to)] + generic.call(seg["color"]))
	sheets["bricks_multi"] = rows

	# 寶箱、金幣：正常與被擊中用專屬母版，破壞用通用幀換色
	for pair in [["brick_chest", "chest_normal", "寶箱"], ["brick_coin", "coin_normal", "金幣"]]:
		var normal: PackedStringArray = g[pair[1]]
		sheets[pair[0]] = [[normal, hit_grid(normal, keep, hit_to)] + generic.call(rules["frame_colors"][pair[2]])]

	# 圓形：F1、F2 專用幀，F3、F4 通用幀
	var round_frames: Array = generic.call(rules["frame_colors"]["圓形"])
	sheets["brick_round"] = [[g["round_normal"], hit_grid(g["round_normal"], keep, hit_to), g["round_f1"], g["round_f2"], round_frames[2], round_frames[3]]]

	# 魔王:F1 = 正常圖疊上裂痕層
	sheets["brick_boss"] = [[g["boss_normal"], hit_grid(g["boss_normal"], keep, hit_to),
		overlay_grid(g["boss_normal"], g["boss_overlay"], 0, 0), g["boss_f2"], g["boss_f3"], g["boss_f4"]]]

	var out := {}
	for name in sheets:
		var grid := compose_sheet(sheets[name])
		var msg := validate_grid(grid, palette)
		if msg != "":
			errors.append("產生的 %s: %s" % [name, msg])
		out[name] = {"grid": grid, "frames": sheets[name]}
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


## 只刪除本工具產生的檔名格式，避免設計稿改名後留下過期的 PNG;其他檔案不動。
func clean_old_outputs(out_dir: String, sprite_dir: String) -> void:
	var targets := [[out_dir, "^(D\\d+_.+|overview|board_sample(_x\\d+)?)\\.png$"], [sprite_dir, "^(bricks?|paddle)_[a-z_]+(_x\\d+)?\\.png$"]]
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


## 檢查 BOARD_LAYOUT:每列 10 格、代號有效、層數在 1~14、魔王 4×3 範圍完整且置中於第 4~7 欄、
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
			elif t.is_valid_int() and (t.to_int() < 1 or t.to_int() > 14):
				errors.append("BOARD_LAYOUT(從 0 起算)第 %d 列第 %d 欄的層數 %s 超出 1~14" % [r, c, t])
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
