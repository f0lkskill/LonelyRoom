## 以 .tres 文件保存的对话数据。
## 每个资源表示一个物体的独白或一段旁白。
class_name DialogueData
extends Resource

## 显示在文本上方的说话人名字；旁白留空。
@export var speaker_name: String = ""
## 为 true 时隐藏说话人并居中显示文本。
@export var narration: bool = false
## 点击后逐条显示的对白。
@export var lines: Array[String] = []
