## 单个对话选项。
## 保存选项文本、SP 变化、后续对话以及可选的一次性标记。
class_name DialogueChoice
extends Resource

## 显示在选项卡上的文本。
@export var text: String = ""
## 选择后增加的 SP，负数为减少。
@export var sp_delta: float = 0.0
## 选择后继续播放的对话资源。
@export var next_dialogue: Resource
## 选择后写入 GameState 的标记。
@export var flag: String = ""
## 为 true 时，带有该标记的选项不再出现。
@export var once: bool = false
