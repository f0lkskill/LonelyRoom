## 底部对话框面板。
## 使用圆角矩形渐变作为背景，独白显示说话人，旁白隐藏说话人并居中文本。
class_name DialogueBox
extends Control

@onready var panel: ColorRect = $Panel
@onready var speaker_label: Label = $Panel/Content/VBox/SpeakerLabel
@onready var text_label: Label = $Panel/Content/VBox/TextLabel

var _data
var _line_index := 0
var _is_open := false
var _fade_tween: Tween
var _reveal_tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	panel.resized.connect(_sync_panel_material)
	_sync_panel_material()


## 将面板实际尺寸同步给圆角矩形 Shader。
func _sync_panel_material() -> void:
	var mat := panel.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size", panel.size)


## 返回对话框当前是否正在接收推进输入。
func is_open() -> bool:
	return _is_open


## 打开面板并显示第一条文本。
func start(data) -> void:
	if data == null or data.lines.is_empty():
		return

	_data = data
	_line_index = 0
	_is_open = true
	visible = true
	_show_line()
	_fade_to(1.0)


## 显示下一行；最后一行结束后关闭面板。
func advance() -> void:
	if not _is_open:
		return

	if text_label.visible_ratio < 1.0:
		if _reveal_tween != null:
			_reveal_tween.kill()
		text_label.visible_ratio = 1.0
		return

	_line_index += 1
	if _data == null or _line_index >= _data.lines.size():
		close()
	else:
		_show_line()


## 淡出面板并停止接收推进输入。
func close() -> void:
	if not _is_open:
		return

	_is_open = false
	if _reveal_tween != null:
		_reveal_tween.kill()
	_fade_to(0.0, true)


## 设置当前行的说话人、对齐方式，并启动打字机效果。
func _show_line() -> void:
	if _data == null:
		return

	var character = _data.get("speaker")
	var speaker: String = str(_data.speaker_name).strip_edges()
	if character != null:
		speaker = str(character.get("display_name")).strip_edges()
	_apply_character_style(character)

	var narration: bool = bool(_data.narration) or speaker.is_empty()

	speaker_label.text = speaker
	speaker_label.visible = not narration
	text_label.text = str(_data.lines[_line_index])
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narration else HORIZONTAL_ALIGNMENT_LEFT
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if narration else VERTICAL_ALIGNMENT_TOP
	text_label.visible_ratio = 0.0

	if _reveal_tween != null:
		_reveal_tween.kill()

	var duration := clampf(float(text_label.text.length()) * 0.035, 0.15, 1.5)
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(text_label, "visible_ratio", 1.0, duration)


## 完全使用角色资源中的字体、字号、颜色和描边设置。
func _apply_character_style(character) -> void:
	if character != null:
		var font = character.get("name_font")
		if font is Font:
			speaker_label.add_theme_font_override("font", font)
		else:
			speaker_label.remove_theme_font_override("font")

		var font_size = character.get("name_font_size")
		if font_size != null:
			speaker_label.add_theme_font_size_override("font_size", int(font_size))

		var name_color = character.get("name_color")
		if name_color is Color:
			speaker_label.add_theme_color_override("font_color", name_color)

		var outline_color = character.get("name_outline_color")
		if outline_color is Color:
			speaker_label.add_theme_color_override("font_outline_color", outline_color)

		var outline_size = character.get("name_outline_size")
		if outline_size != null:
			speaker_label.add_theme_constant_override("outline_size", int(outline_size))
	else:
		speaker_label.remove_theme_font_override("font")
		speaker_label.add_theme_font_size_override("font_size", 42)
		speaker_label.add_theme_color_override("font_color", Color(0.63, 0.86, 1.0, 1.0))
		speaker_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		speaker_label.add_theme_constant_override("outline_size", 10)


## 淡入或淡出面板，并在淡出结束后隐藏节点。
func _fade_to(target: float, hide_after := false) -> void:
	if _fade_tween != null:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(self, "modulate:a", target, 0.3)
	if hide_after:
		_fade_tween.tween_callback(func() -> void: visible = false)
