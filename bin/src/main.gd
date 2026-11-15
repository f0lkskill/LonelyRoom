## 主场景控制器。
## 运行时加载配置的房间，用鼠标驱动镜头取景，
## 并把点击事件分发给可交互物体和对话框。
extends Node2D

## SP 跌到不同比例时触发的特殊独白。
const SP_SPECIALS := [
	{"id": "sp35", "ratio": 0.35, "data": preload("res://bin/dialogue/special/sp_low_35.tres")},
	{"id": "sp20", "ratio": 0.20, "data": preload("res://bin/dialogue/special/sp_low_20.tres")},
	{"id": "sp10", "ratio": 0.10, "data": preload("res://bin/dialogue/special/sp_low_10.tres")},
]

## 启动时实例化的房间场景路径。
@export_file("*.tscn") var room_path: String = "res://bin/scence/rooms/hall_room/hall_room.tscn"
## 解离效果的总强度，范围 0.0 到 1.0。
## 强度越高，场景越暗，并解锁噪声条、撕裂和破碎边缘。
@export_range(0.0, 1.0, 0.01) var dissociation_strength: float = 0.65:
	set(value):
		dissociation_strength = clampf(value, 0.0, 1.0)
		if is_node_ready() and _room_loaded:
			_apply_dissociation_strength()
## 镜头最大平移距离的倍率。
@export var pan_strength: float = 1.0
## 视口中心不触发平移的死区比例。
## 较大的值可以让玩家瞄准物体时画面保持稳定。
@export_range(0.0, 0.9, 0.01) var pan_deadzone: float = 0.75
## 镜头跟随平滑度，数值越大对鼠标移动反应越快。
@export var smoothing: float = 10.0

## 用于框住房间并在房间边界内平移的镜头。
@onready var camera: Camera2D = $Camera2D
## 仅在极高强度下出现的屏幕空间灰色噪声层。
@onready var noise_bars: ColorRect = $CanvasLayer/NoiseBars
## 屏幕空间的整体变暗与边缘暗幕层。
@onready var vignette: ColorRect = $CanvasLayer/Vignette
## 用于独白和旁白的底部对话框。
@onready var dialogue_box = $CanvasLayer/DialogueBox

var _room_bounds := Rect2()
var _room_loaded := false
## 每个 Sprite 独立复制的物体材质，用于生成不同的破碎种子。
var _object_materials: Array[ShaderMaterial] = []
## 从已加载房间中收集的可交互物体，按绘制顺序排列。
var _interactables: Array = []
## 当前鼠标悬停的可交互物体，没有则为 null。
var _hovered = null
## 已经触发过的 SP 阈值，避免重复触发。
var _seen_sp_thresholds: Dictionary = {}
## 等待播放的低 SP 特殊对话。
var _special_queue: Array[Resource] = []


## 实例化房间，并准备材质、交互、镜头和视觉效果。
func _ready() -> void:
	var packed := load(room_path) as PackedScene
	if packed == null:
		push_error("Failed to load room: %s" % room_path)
		return

	var room := packed.instantiate()
	add_child(room)
	_setup_object_materials(room)
	_collect_interactables(room)
	_room_bounds = _get_room_bounds(room)
	_room_loaded = true
	camera.make_current()
	_update_camera(0.0, true)
	GameState.sp_changed.connect(_on_sp_changed)
	_on_sp_changed(GameState.sp, GameState.max_sp)


## 先刷新悬停状态，再移动镜头，并处理排队中的特殊对话。
func _process(delta: float) -> void:
	if _room_loaded:
		_update_hover()
		_update_camera(delta, false)
		_try_start_special_dialogue()


## SP 越低，画面解离越强，并在阈值处排队特殊独白。
func _on_sp_changed(value: float, max_value: float) -> void:
	var ratio := clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	dissociation_strength = lerpf(0.15, 1.0, 1.0 - ratio)

	for item in SP_SPECIALS:
		if ratio <= float(item["ratio"]) and not _seen_sp_thresholds.has(item["id"]):
			_seen_sp_thresholds[item["id"]] = true
			_special_queue.append(item["data"])


## 当前没有对话框时，播放排队中的特殊对话。
func _try_start_special_dialogue() -> void:
	if _special_queue.is_empty() or dialogue_box.is_open():
		return

	var data = _special_queue.pop_front()
	dialogue_box.start(data)


## 为每个 Sprite 复制独立材质，并分配稳定的随机破碎种子。
func _setup_object_materials(root: Node) -> void:
	var index := 0
	var stack: Array[Node] = [root]

	while not stack.is_empty():
		var node: Node = stack.pop_back()

		if node is Sprite2D and node.material is ShaderMaterial:
			var material := (node.material as ShaderMaterial).duplicate() as ShaderMaterial
			material.set_shader_parameter("object_seed", fposmod(0.13 + float(index) * 0.173, 1.0))
			node.material = material
			_object_materials.append(material)
			index += 1

		for child in node.get_children():
			stack.append(child)


## 将当前强度同步到物体、噪声层和暗幕材质。
func _apply_dissociation_strength() -> void:
	for material in _object_materials:
		material.set_shader_parameter("strength", dissociation_strength)

	if noise_bars.material is ShaderMaterial:
		var noise_material := noise_bars.material as ShaderMaterial
		noise_material.set_shader_parameter("strength", dissociation_strength)

	if vignette.material is ShaderMaterial:
		var vignette_material := vignette.material as ShaderMaterial
		vignette_material.set_shader_parameter("strength", dissociation_strength)


## 收集带有对话数据的可点击物体。
## 遍历顺序与绘制顺序一致，因此前景物体会优先被检测到。
func _collect_interactables(root: Node) -> void:
	_interactables.clear()
	var stack: Array[Node] = [root]

	while not stack.is_empty():
		var node: Node = stack.pop_back()

		if node is BaseObj and node.get("dialogue_data") != null:
			_interactables.append(node)

		var children := node.get_children()
		for i in range(children.size() - 1, -1, -1):
			stack.append(children[i])


## 刷新当前悬停物体；对话框打开时禁用悬停。
func _update_hover() -> void:
	if dialogue_box.is_open():
		_set_hovered(null)
		return

	_set_hovered(_find_hovered())


## 返回鼠标下最上层的可交互物体，没有则返回 null。
## 反向遍历以匹配场景的绘制顺序。
func _find_hovered():
	var mouse := get_global_mouse_position()

	for i in range(_interactables.size() - 1, -1, -1):
		var obj = _interactables[i]
		if not is_instance_valid(obj) or obj.texture == null:
			continue

		var local = obj.to_local(mouse)
		if obj.get_rect().has_point(local):
			return obj

	return null


## 悬停目标变化时切换描边和鼠标指针状态。
func _set_hovered(obj) -> void:
	if obj == _hovered:
		return

	if is_instance_valid(_hovered):
		_hovered.set_hovered(false)

	_hovered = obj

	if is_instance_valid(_hovered):
		_hovered.set_hovered(true)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


## 点击物体时开始对话；对话打开时推进或关闭对话。
## Enter/空格推进，Escape 关闭。
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_box.is_open():
			dialogue_box.advance()
			get_viewport().set_input_as_handled()
		elif is_instance_valid(_hovered) and _hovered.dialogue_data != null:
			dialogue_box.start(_hovered.dialogue_data)
			_set_hovered(null)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") and dialogue_box.is_open():
		dialogue_box.advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and dialogue_box.is_open():
		dialogue_box.close()
		get_viewport().set_input_as_handled()


## 将单个归一化鼠标轴重新映射，使内侧死区不产生平移。
func _apply_deadzone(value: float, deadzone: float) -> float:
	if deadzone >= 1.0:
		return 0.0

	var sign_value := signf(value)
	var magnitude := maxf(absf(value) - deadzone, 0.0) / (1.0 - deadzone)
	return sign_value * magnitude


## 朝鼠标位置平移镜头，同时把视野限制在房间内。
func _update_camera(delta: float, snap: bool) -> void:
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return

	var half_view := view_size / (2.0 * camera.zoom)
	var room_center := _room_bounds.get_center()

	var max_offset := Vector2(
		maxf((_room_bounds.size.x - half_view.x * 2.0) * 0.5, 0.0),
		maxf((_room_bounds.size.y - half_view.y * 2.0) * 0.5, 0.0)
	)

	var mouse := get_viewport().get_mouse_position()
	var raw := ((mouse / view_size) * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
	var normalized := Vector2(
		_apply_deadzone(raw.x, pan_deadzone),
		_apply_deadzone(raw.y, pan_deadzone)
	)
	var target := room_center + normalized * max_offset * pan_strength

	var min_pos := _room_bounds.position + half_view
	var max_pos := _room_bounds.end - half_view

	target.x = room_center.x if min_pos.x > max_pos.x else clampf(target.x, min_pos.x, max_pos.x)
	target.y = room_center.y if min_pos.y > max_pos.y else clampf(target.y, min_pos.y, max_pos.y)

	if snap:
		camera.global_position = target
	else:
		var weight := 1.0 - exp(-smoothing * delta)
		camera.global_position = camera.global_position.lerp(target, weight)


## 计算覆盖房间内所有可见 Sprite 的世界坐标矩形。
## 用作镜头边界，确保不会显示房间外的空白。
func _get_room_bounds(root: Node) -> Rect2:
	var bounds := Rect2()
	var found := false
	var stack: Array[Node] = [root]

	while not stack.is_empty():
		var node: Node = stack.pop_back()

		if node is Sprite2D and node.texture != null:
			var rect: Rect2 = node.get_rect()
			var xform: Transform2D = node.get_global_transform()
			var corners := [
				xform * rect.position,
				xform * Vector2(rect.end.x, rect.position.y),
				xform * rect.end,
				xform * Vector2(rect.position.x, rect.end.y),
			]
			var sprite_bounds := Rect2(corners[0], Vector2.ZERO)
			for corner in corners:
				sprite_bounds = sprite_bounds.expand(corner)
			bounds = sprite_bounds if not found else bounds.merge(sprite_bounds)
			found = true

		for child in node.get_children():
			stack.append(child)

	if not found:
		return Rect2(-540.0, -405.0, 1080.0, 810.0)

	return bounds
