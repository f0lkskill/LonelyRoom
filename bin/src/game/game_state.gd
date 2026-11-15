## 全局精神值状态。
## SP 随时间流逝，并供主场景、精神值环形条和对话选项共同使用。
extends Node

signal sp_changed(value: float, max_value: float)

## SP 上限。
@export var max_sp: float = 100.0
## 初始 SP。
@export var starting_sp: float = 100.0
## 每秒自然流失的 SP。
@export var decay_per_second: float = 0.5

var sp: float = 100.0
var flags: Dictionary = {}


func _ready() -> void:
	sp = clampf(starting_sp, 0.0, max_sp)
	sp_changed.emit(sp, max_sp)


func _process(delta: float) -> void:
	if sp > 0.0:
		_set_sp(sp - decay_per_second * delta)


## 增加或减少 SP，正数为恢复，负数为消耗。
func change_sp(amount: float) -> void:
	_set_sp(sp + amount)


## 返回当前 SP 比例，范围 0.0 到 1.0。
func get_ratio() -> float:
	if max_sp <= 0.0:
		return 0.0
	return clampf(sp / max_sp, 0.0, 1.0)


func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name)


func set_flag(flag_name: String) -> void:
	if not flag_name.is_empty():
		flags[flag_name] = true


func _set_sp(value: float) -> void:
	sp = clampf(value, 0.0, max_sp)
	sp_changed.emit(sp, max_sp)
