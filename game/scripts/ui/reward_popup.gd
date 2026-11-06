class_name RewardPopup
extends Control
## 獲得提示框(event-screen D17)與月初補發提示框(D15)共用的元件,含「依序跳出」的佇列。
## 由首頁持有一個(放在最上層),首頁與活動頁都往這裡排框;同一時間只顯示一個。
## 節點放在首頁原點、大小 360×畫面高;遮罩畫滿整個 viewport(比 9:16 寬時兩側也蓋住)。
## 內容格式見 EventLogic 的 popup_* 函式。

## 關閉一個框(按「好」或返回鍵)時發出;item.wallet 由接收端套用到資源列
signal item_closed(item: Dictionary)
## 佇列清空時發出
signal all_closed

const ICONS := {
	"coin": preload("res://assets/ui/resource/coin.png"),
	"heart": preload("res://assets/ui/resource/heart.png"),
	"gold": preload("res://assets/ui/resource/gold.png"),
	"silver": preload("res://assets/ui/resource/silver.png"),
}
const MASK := Color(0, 0, 0, 160.0 / 255.0)
const BG := Color("#222B3A")
const BORDER := Color("#5D6D7E")
const TIER_COLOR := Color("#B0B8C4")
const FRAME_X := 32
const FRAME_W := 296
## 獎勵的兩個橫向位置:[icon x, 數量 x](D15、D17 共用,四列對齊)
const SLOTS := [[16, 45], [110, 139]]
const NO_OUTLINE := Color.TRANSPARENT

var _queue: Array[Dictionary] = []
var _ok: FlatButton
## 排過的補發框 id:補發清單在玩家關框前每次取資料都會帶回(首頁與活動頁可能同時取),同一 id 只彈一次
var _seen_ids := {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ok = FlatButton.new()
	_ok.size = Vector2(216, 44)
	_ok.set_active("好", true)
	_ok.pressed.connect(close_current)
	add_child(_ok)
	resized.connect(_relayout)


func is_open() -> bool:
	return not _queue.is_empty()


## 排一個框;依 D17 順序插隊(正在顯示的那個不會被換掉)。帶 id 且排過的框直接略過
func enqueue(item: Dictionary) -> void:
	var id: String = item.get("id", "")
	if id != "":
		if _seen_ids.has(id):
			return
		_seen_ids[id] = true
	_queue.insert(EventLogic.popup_insert_index(_queue, item.kind), item)
	visible = true
	_relayout()


## 關閉目前的框,下一個立即出現(不做轉場)
func close_current() -> void:
	if _queue.is_empty():
		return
	var item: Dictionary = _queue.pop_front()
	visible = not _queue.is_empty()
	_relayout()
	item_closed.emit(item)
	if _queue.is_empty():
		all_closed.emit()


func current() -> Dictionary:
	return _queue[0] if is_open() else {}


func frame_rect() -> Rect2:
	var h := EventLogic.popup_frame_height(_queue[0])
	# 垂直置中於整個螢幕
	return Rect2(FRAME_X, floorf((size.y - h) / 2.0), FRAME_W, h)


func _relayout() -> void:
	if is_open():
		var fr := frame_rect()
		_ok.position = fr.position + Vector2(40, fr.size.y - 16 - 44)
	queue_redraw()


func _draw() -> void:
	if not is_open():
		return
	draw_rect(Rect2(-global_position, get_viewport_rect().size), MASK)
	var item := _queue[0]
	var fr := frame_rect()
	draw_rect(fr, BORDER)
	draw_rect(fr.grow(-1), BG)
	var o := fr.position
	PixelText.draw(self, o + Vector2(16, 37), item.title, 18, Color.WHITE, NO_OUTLINE, 264, HORIZONTAL_ALIGNMENT_CENTER)
	var y := o.y + EventLogic.POPUP_CONTENT_TOP
	if item.has("tiers"):
		_draw_tiers(item.tiers, o.x, y)
	else:
		_draw_rewards(item, o.x, y)


## D17:每列最多 2 個獎勵(列高 40,icon 在列內 y 8、數量基線 y 26),之後接文字行(行高 22、基線 +16)
func _draw_rewards(item: Dictionary, x: float, y: float) -> void:
	var rewards: Array = item.rewards
	for i in rewards.size():
		var row_y := y + floori(i / 2.0) * EventLogic.POPUP_REWARD_ROW
		_draw_reward(rewards[i], x, row_y + 8, row_y + 26, i % 2)
	y += ceili(rewards.size() / 2.0) * EventLogic.POPUP_REWARD_ROW
	for line in item.lines:
		PixelText.draw(self, Vector2(x + 16, y + 16), line, 14, Color.WHITE, NO_OUTLINE)
		y += EventLogic.POPUP_TEXT_LINE


## D15:每階一個區塊(階名基線 y 14、icon y 22、數量基線 y 40);28 次階第二行隨機道具基線 y 66
func _draw_tiers(tiers: Array, x: float, y: float) -> void:
	for t in tiers:
		PixelText.draw(self, Vector2(x + 16, y + 14), "累積 %d 次" % t.tier, 14, TIER_COLOR, NO_OUTLINE)
		var rewards: Array = EventLogic.TIER_REWARDS[t.tier]
		for i in rewards.size():
			_draw_reward(rewards[i], x, y + 22, y + 40, i)
		if t.tier == EventLogic.ITEM_TIER:
			PixelText.draw(self, Vector2(x + 16, y + 66), EventLogic.item_line(t.item_name), 14, Color.WHITE, NO_OUTLINE)
			y += EventLogic.POPUP_ITEM_TIER_BLOCK
		else:
			y += EventLogic.POPUP_TIER_BLOCK


func _draw_reward(reward: Array, x: float, icon_y: float, baseline: float, slot: int) -> void:
	draw_texture(ICONS[reward[0]], Vector2(x + SLOTS[slot][0], icon_y))
	PixelText.draw(self, Vector2(x + SLOTS[slot][1], baseline), "×%d" % reward[1], 14, Color.WHITE, NO_OUTLINE)
