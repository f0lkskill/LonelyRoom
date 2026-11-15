## 房间基类，记录房间名称。
extends Node2D


class_name BaseRoom

## 房间名称，供外部识别当前房间。
@export var RoomName = "UNKNOWN"

## 节点首次进入场景树时调用。
func _ready() -> void:
	pass


## 每帧调用，delta 为距上一帧的时间。
func _process(delta: float) -> void:
	pass
