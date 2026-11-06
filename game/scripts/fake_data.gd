class_name FakeData
## 首頁用的假資料,集中在這裡;之後接上存檔 / 後端時只替換這個檔。
## shortcut: 全部是寫死的常數,沒有存檔;做存檔系統時改成從存檔讀取。

const HEARTS := 3
const COINS := 12345
const GOLD := 50
const SILVER := 300

## 第一個未通關的關卡(1~14 已通關、15 可玩、16~200 未解鎖);全通關時為 201。
const FIRST_UNCLEARED_LEVEL := 15

## 愛心「下一顆」倒數的起始秒數(12:34)。
const HEART_NEXT_SECONDS := 12 * 60 + 34
