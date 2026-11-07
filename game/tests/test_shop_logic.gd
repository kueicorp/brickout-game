extends SceneTree
## 商城純規則(ShopLogic)、綠色九宮格按鈕的文字位置與 pressed 來源圖、假商城服務(ShopService)的測試。執行:
##   Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/test_shop_logic.gd
## 有任何失敗時結束碼為 1。

const L := preload("res://scripts/shop_logic.gd")
const S := preload("res://scripts/shop_service.gd")
const ES := preload("res://scripts/event_service.gd")
const EL := preload("res://scripts/event_logic.gd")
const G := preload("res://scripts/ui/green_button.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _eq(actual, expected, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])


## 呼叫假服務並等回應;callback 接在 args 後面
func _call(f: Callable, args := []) -> Dictionary:
	var box := {}
	f.callv(args + [func(r: Dictionary) -> void: box.r = r])
	while not box.has("r"):
		await process_frame
	return box.r


func _run() -> void:
	_test_products()
	_test_rules()
	_test_heights()
	_test_green_button()
	await _test_service()
	ES.reset()
	S.reset()
	print("PASSED %d, FAILED %d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_products() -> void:
	var g := L.product("gold:90")
	_eq([g.kind, g.price, g.gold, g.silver], ["gold", 90, 90, 9], "gold:90")
	_eq(L.product("gold:30").silver, 0, "gold:30 no silver")
	_eq(L.product("gold:31"), {}, "unknown gold pack")
	_eq([L.product("remove_ads").price, L.product("remove_ads").silver], [300, 100], "remove ads")
	var it := L.product("item:3:11")
	_eq([it.kind, it.name, it.count, it.price, it.desc], ["item", "暗殺", 11, 300, "×11"], "item 11")
	_eq([L.product("item:0:1").price, L.product("item:0:1").name], [30, "額外血量"], "item single")
	_eq([L.product("bundle").price, L.product("bundle").desc], [540, "全部 10 種道具各 2 個"], "bundle")
	for pack in [[1, 30], [5, 120], [10, 240], [20, 480]]:
		_eq(L.product("heart:%d" % pack[0]).price, pack[1], "heart %d price" % pack[0])
	for pack in [[1000, 30], [5000, 120], [10000, 240], [20000, 480], [50000, 1350]]:
		_eq(L.product("coin:%d" % pack[0]).price, pack[1], "coin %d price" % pack[0])
	_eq(L.product("nope"), {}, "unknown id")
	_eq([L.is_iap("gold:30"), L.is_iap("remove_ads"), L.is_iap("bundle"), L.is_iap("heart:1")], [true, true, false, false], "is_iap")


func _test_rules() -> void:
	# D23:先扣銀塊,不足再扣金塊(1:1)
	_eq(L.split_cost(540, 50), [50, 490], "split mixed")
	_eq(L.split_cost(30, 300), [30, 0], "split silver only")
	_eq(L.split_cost(30, 0), [0, 30], "split gold only")
	# D24 例:需要 540、有銀塊 50 + 金塊 250 → 不足(還差 240)
	_eq(L.can_afford(540, {"silver": 50, "gold": 250}), false, "short 540")
	_eq(L.can_afford(300, {"silver": 50, "gold": 250}), true, "afford 300 exactly")
	# D15 / D25:持有 92 → 1、5 照常;10、20 超過上限;99 全部「愛心已滿」
	var H := L.HeartCard
	_eq([L.heart_card_state(92, 1), L.heart_card_state(92, 5), L.heart_card_state(92, 10), L.heart_card_state(92, 20)],
		[H.NORMAL, H.NORMAL, H.OVER_CAP, H.OVER_CAP], "heart cards at 92")
	_eq(L.heart_card_state(94, 5), H.NORMAL, "94 + 5 = 99 ok")
	_eq(L.heart_card_state(99, 1), H.FULL, "99 full (over cap has lower priority)")
	# D17 / D18
	_eq(L.free_badge([0, 0, 0, 0]), false, "badge: all used")
	_eq(L.free_badge([0, 0, 0, 1]), true, "badge: item chest left")
	# D07:可捲距離(640 / 800 / 840)
	_eq([0, 1, 2, 3].map(func(t: int) -> int: return L.max_scroll(t, 0)), [150, 430, 158, 0], "max scroll 640")
	_eq([0, 1, 2, 3].map(func(t: int) -> int: return L.max_scroll(t, 160)), [0, 270, 0, 0], "max scroll 800")
	_eq([0, 1, 2, 3].map(func(t: int) -> int: return L.max_scroll(t, 200)), [0, 230, 0, 0], "max scroll 840")
	_eq(L.max_scroll(0, 150), 0, "topup fits from H 790")


func _test_heights() -> void:
	# D23 確認框:1 列 270、2 列 298;D27 詳情:174 + 22n
	_eq([L.confirm_height([30, 0]), L.confirm_height([0, 30]), L.confirm_height([10, 20])], [270, 270, 298], "confirm heights")
	_eq([L.detail_height(0), L.detail_height(1)], [218, 240], "detail heights")
	# D21 / D22 / D25 / D26 沿用 RewardPopup 的框高
	var w := {"heart": 1, "coin": 1, "gold": 1, "silver": 1}
	var cases := [
		[L.popup_purchase(L.product("gold:90"), 0, w), 168, "gold 90"],
		[L.popup_purchase(L.product("gold:30"), 0, w), 168, "gold 30"],
		[L.popup_purchase(L.product("remove_ads"), 0, w), 190, "remove ads"],
		[L.popup_purchase(L.product("item:0:11"), 11, w), 150, "item"],
		[L.popup_purchase(L.product("bundle"), 2, w), 150, "bundle"],
		[L.popup_purchase(L.product("heart:5"), 5, w), 168, "heart"],
		[L.popup_purchase(L.product("coin:5000"), 5000, w), 168, "coin"],
		[L.popup_unpaid(false, w), 150, "unpaid a/b"],
		[L.popup_unpaid(true, w), 172, "unpaid c"],
		[L.popup_heart_cap(92, 10, w), 172, "heart cap"],
	]
	for c in cases:
		_eq(EL.popup_frame_height(c[0]), c[1], "popup height " + c[2])
	var gold := L.popup_purchase(L.product("gold:90"), 0, w)
	_eq(gold.rewards, [["gold", 90], ["silver", 9]], "D21 gold rewards")
	_eq(L.popup_purchase(L.product("gold:30"), 0, w).rewards, [["gold", 30]], "D21 gold 30 no silver")
	_eq(L.popup_purchase(L.product("remove_ads"), 0, w).lines, ["廣告已移除"], "D21 remove ads line")
	_eq(L.popup_purchase(L.product("item:9:1"), 1, w).lines, ["技能大禮包 ×1"], "D26 item line")
	_eq(L.popup_purchase(L.product("bundle"), 2, w).lines, ["商城道具 各 2 個"], "D26 bundle line")
	_eq(L.popup_purchase(L.product("heart:5"), 3, w).rewards, [["heart", 3]], "D26 heart uses granted")
	_eq(L.popup_heart_cap(92, 10, w).lines[1], "你有 92 顆,買 10 顆會超過上限。", "D25 text")
	_eq(L.popup_free(3, 1, "破甲", w).lines, ["隨機道具:破甲 ×1"], "D12 item chest line")
	_eq(L.popup_free(0, 0, "", w).rewards, [["heart", 0]], "D12 heart at 99 shows actual 0")
	# D28:每行 14px 放得進框內 264px(設計稿目標 ≤ 252px,超過的只印出來)
	for lines in L.ITEM_LINES:
		for line: String in lines:
			var px := PixelText.FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			_eq(px <= 264, true, "D28 line fits 264px: %s (%d)" % [line, px])
			if px > 252:
				print("note: D28 line wider than 252px: %s (%d)" % [line, px])
			# 使用者 2026-11-07 決定:說明行一律不加句號
			_eq(line.contains("。"), false, "D28 line has no period: %s" % line)
	_eq(L.ITEM_LINES[4][0], "抵擋 10 次敵方攻擊或負面效果", "D28 coating line 1")
	var coat_px := PixelText.FONT.get_string_size(L.ITEM_LINES[4][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_eq(coat_px <= 252, true, "D28 coating line 1 ≤ 252px (%d)" % coat_px)
	print("D28 coating line 1 width: %d" % coat_px)


func _test_green_button() -> void:
	# 文字置中在平面(按鈕高 − 11):44 高 14px → 21;80×48 兩行 12px → 14 / 31;216×56 18px → 29
	_eq(G.label_baseline(44, 14, 1), 21.0, "baseline 44/14")
	_eq(G.label_baseline(48, 12, 2), 14.0, "baseline 48/12 two lines")
	_eq(G.label_baseline(56, 18, 1), 29.0, "baseline 56/18")
	# pressed 來源圖:左 22 + 乾淨中段 103(x 92~169 + 175~199)+ 右 12;
	# 中段不含淺色斑點 #42B674,平面下緣(y 62 → 拼接圖 y 48)也沒有深色短線 #0C482E
	var img: Image = G._clean_pressed().get_image()
	_eq(img.get_size(), Vector2i(137, 55), "clean pressed size")
	var spot := Color("#42B674")
	var dark := Color("#0C482E")
	var found := false
	var line := false
	for y in img.get_height():
		for x in range(22, 125):
			var c := img.get_pixel(x, y)
			if c.is_equal_approx(spot):
				found = true
			# 上框 y 0~1、下框 y 53~54 本來就是 #0C482E,只檢查中間
			if y >= 2 and y < 53 and c.is_equal_approx(dark):
				line = true
	_eq(found, false, "clean pressed middle has no light spot")
	_eq(line, false, "clean pressed middle has no dark line")
	# 中段每一欄都要逐像素等於原圖對應欄(只取原圖像素、不縮放)
	var src: Image = G.TEX_PRESSED.get_image()
	if src.is_compressed():
		src.decompress()
	var same := true
	var dx := 22
	for s in G.PRESSED_CLEAN_SPANS:
		for sx in range(s.x, s.y):
			for y in img.get_height():
				if img.get_pixel(dx, y) != src.get_pixel(sx, y + 14):
					same = false
			dx += 1
	_eq([same, dx], [true, 125], "clean pressed middle copied from source columns")


func _test_service() -> void:
	ES.reset()
	S.reset()
	S.delay_sec = 0.01
	var w: Dictionary = ES.wallet
	var r := await _call(S.fetch_status)
	_eq([r.ok, r.free_left, r.prices["gold:30"], r.prices["remove_ads"], r.popups], [true, [20, 5, 5, 1], "TWD 30", "TWD 300", []], "fetch")
	# 金塊購買:先扣銀塊;同一個 request id 重送不重複扣款
	r = await _call(S.buy_with_gold, ["item:0:1", "r1"])
	_eq([r.ok, r.granted, w.silver, w.gold], [true, 1, 270, 50], "buy item with silver")
	r = await _call(S.buy_with_gold, ["item:0:1", "r1"])
	_eq([r.ok, w.silver], [true, 270], "same request id not charged twice")
	r = await _call(S.buy_with_gold, ["item:0:11", "r2"])
	_eq([w.silver, w.gold], [0, 20], "mixed charge 300 = silver 270 + gold 30")
	r = await _call(S.buy_with_gold, ["bundle", "r3"])
	_eq([r.ok, r.reason, r.wallet.gold], [false, "short", 20], "short")
	w.gold = 1000
	w.heart = 95
	r = await _call(S.buy_with_gold, ["heart:5", "r4"])
	_eq([r.ok, r.reason, w.heart], [false, "heart_cap", 95], "heart cap")
	r = await _call(S.buy_with_gold, ["heart:1", "r5"])
	_eq([r.ok, r.granted, w.heart, w.gold], [true, 1, 96, 970], "heart 1")
	r = await _call(S.buy_with_gold, ["coin:1000", "r6"])
	_eq([r.ok, w.coin], [true, 12345 + 1000], "coin no cap")
	r = await _call(S.buy_with_gold, ["gold:30", "r7"])
	_eq([r.ok, r.reason], [false, "failed"], "gold pack cannot be bought with gold")
	S.fail_next = 1
	r = await _call(S.buy_with_gold, ["coin:1000", "r8"])
	_eq([r.ok, r.reason, w.coin], [false, "failed", 13345], "server failure: no charge")
	S.offline = true
	r = await _call(S.buy_with_gold, ["coin:1000", "r9"])
	_eq([r.ok, r.reason], [false, "offline"], "offline buy")
	r = await _call(S.fetch_status)
	_eq(r.ok, false, "offline fetch")
	S.offline = false
	# 看廣告:扣次數;愛心 99 照常可看、實際獲得 0
	w.heart = 99
	r = await _call(S.watch_ad, [0])
	_eq([r.ok, r.granted, w.heart, r.free_left[0]], [true, 0, 99, 19], "ad heart at 99")
	r = await _call(S.watch_ad, [1])
	_eq([r.granted >= 50 and r.granted <= 200, r.free_left[1]], [true, 4], "ad coin 50~200")
	r = await _call(S.watch_ad, [2])
	_eq(r.granted >= 1 and r.granted <= 5, true, "ad silver 1~5")
	r = await _call(S.watch_ad, [3])
	_eq([r.ok, EL.SHOP_ITEMS.has(r.item_name), r.free_left[3]], [true, true, 0], "ad item chest")
	r = await _call(S.watch_ad, [3])
	_eq(r.ok, false, "ad item chest used up")
	# Google Play:取消 / 失敗 / 待處理 / 驗證失敗 / 成功
	S.play_result = "canceled"
	r = await _call(S.buy_iap, ["gold:90"])
	_eq([r.ok, r.reason], [false, "canceled"], "iap canceled")
	S.play_result = "failed"
	r = await _call(S.buy_iap, ["gold:90"])
	_eq(r.reason, "failed", "iap failed")
	S.play_result = "pending"
	r = await _call(S.buy_iap, ["gold:90"])
	_eq([r.reason, r.pending_products], ["pending", ["gold:90"]], "iap pending")
	r = await _call(S.buy_iap, ["gold:150"])
	_eq(r.ok, true, "iap paid")
	S.verify_result = "fail"
	var v := await _call(S.verify_iap, [r.order_id])
	_eq([v.ok, v.pending_products], [false, ["gold:90", "gold:150"]], "verify failed -> pending")
	# 補發:入帳,下次取資料帶出補發框(id 有 shop: 前綴);看過後不再帶
	var gold0: int = w.gold
	S.simulate_grant_pending()
	_eq(w.gold, gold0 + 240, "grant pending adds gold")
	r = await _call(S.fetch_status)
	_eq([r.popups.size(), r.popups[0].kind, r.popups[0].id.begins_with(S.ID_PREFIX), r.pending_products], [2, "order", true, []], "reissue popups")
	await _call(S.mark_popup_seen, [r.popups[0].id])
	await _call(S.mark_popup_seen, [r.popups[1].id])
	r = await _call(S.fetch_status)
	_eq(r.popups, [], "reissue shown once")
	# 移除廣告成功
	r = await _call(S.buy_iap, ["remove_ads"])
	var silver0: int = w.silver
	v = await _call(S.verify_iap, [r.order_id])
	_eq([v.ok, v.remove_ads_bought, w.silver], [true, true, silver0 + 100], "remove ads")
