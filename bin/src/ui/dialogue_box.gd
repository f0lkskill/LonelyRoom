## 自适应阴影对话框。
## 阴影尺寸只跟随对话文本，说话人固定在阴影左上角并允许突出显示。
class_name DialogueBox
extends Control

const CHAR_EFFECT := preload("res://bin/asset/effect/char_fade_rotate.tres")

## 文本区域的最小宽度。
@export var min_content_width: float = 280.0
## 文本区域的最大宽度，超过后自动换行。
@export var max_content_width: float = 720.0
## 阴影左右内边距。
@export var horizontal_padding: float = 80.0
## 阴影上下内边距。
@export var vertical_padding: float = 64.0
## 阴影底部与屏幕底部的距离。
@export var bottom_margin: float = 36.0
## 阴影的最小高度。
@export var min_panel_height: float = 140.0

@onready var panel: ColorRect = $Panel
@onready var content: Control = $Panel/Content
@onready var speaker_label: Label = $Panel/SpeakerLabel

var text_label: RichTextLabel

var _data
var _line_index := 0
var _is_open := false
var _fade_tween: Tween
var _layout_tween: Tween
var _effect
var _line_started_msec := 0
var _line_reveal_ms := 0.0
var _layout_version := 0


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	_create_text_label()
	_effect = CHAR_EFFECT
	if _effect != null:
		text_label.install_effect(_effect)
	panel.resized.connect(_sync_panel_material)
	_sync_panel_material()


## 在代码中创建富文本标签，确保尺寸由对话框完全控制。
func _create_text_label() -> void:
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.bbcode_enabled = true
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("default_color", Color(0.96, 0.97, 1.0, 1.0))
	text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	text_label.add_theme_constant_override("outline_size", 10)
	text_label.add_theme_font_size_override("normal_font_size", 26)
	content.add_child(text_label)


func _process(_delta: float) -> void:
	if visible:
		if content.size.y > 0.0:
			text_label.size = content.size
		_sync_panel_material()


## 将阴影实际尺寸同步给圆角阴影 Shader。
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

	if Time.get_ticks_msec() - _line_started_msec < _line_reveal_ms:
		if _effect != null:
			_effect.force_complete = true
		_line_reveal_ms = 0.0
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
	_fade_to(0.0, true)


## 设置当前行的说话人、尺寸，并启动逐字渐入效果。
func _show_line() -> void:
	if _data == null:
		return

	var character = _data.get("speaker")
	var speaker: String = str(_data.speaker_name).strip_edges()
	if character != null:
		speaker = str(character.get("display_name")).strip_edges()
	_apply_character_style(character)

	var narration: bool = bool(_data.narration) or speaker.is_empty()
	var line_text: String = str(_data.lines[_line_index])

	speaker_label.text = speaker
	speaker_label.visible = not narration
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narration else HORIZONTAL_ALIGNMENT_LEFT

	text_label.clear()
	if _effect != null:
		_effect.force_complete = false
		text_label.push_customfx(_effect, {})
	text_label.add_text(line_text)
	if _effect != null:
		text_label.pop()

	var delay := 0.03
	var duration := 0.22
	if _effect != null:
		delay = float(_effect.get("delay_per_character"))
		duration = float(_effect.get("fade_duration"))
	_line_started_msec = Time.get_ticks_msec()
	_line_reveal_ms = maxf(float(line_text.length()) * delay + duration, 0.1) * 1000.0

	_update_panel_layout(line_text)


## 只根据对话文本调整阴影尺寸，说话人不参与计算。
func _update_panel_layout(line_text: String) -> void:
	_layout_version += 1
	var version := _layout_version

	var text_font := text_label.get_theme_font("normal_font")
	var text_size := text_label.get_theme_font_size("normal_font_size")
	var text_width := text_font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var content_width := clampf(text_width, min_content_width, max_content_width)
	var panel_width := content_width + horizontal_padding * 2.0

	content.offset_left = horizontal_padding
	content.offset_top = vertical_padding
	content.offset_right = -horizontal_padding
	content.offset_bottom = -vertical_padding

	_apply_panel_rect(panel_width, maxf(panel.size.y, min_panel_height))

	await get_tree().process_frame
	if version != _layout_version:
		return

	var text_height := float(text_label.get_content_height())
	var panel_height := maxf(text_height + vertical_padding * 2.0, min_panel_height)
	_apply_panel_rect(panel_width, panel_height)


## 平滑应用阴影尺寸和底部居中位置。
func _apply_panel_rect(width: float, height: float) -> void:
	if _layout_tween != null:
		_layout_tween.kill()

	var target_left := -width * 0.5
	var target_right := width * 0.5
	var target_top := -bottom_margin - height
	var target_bottom := -bottom_margin

	if _line_index == 0:
		panel.offset_left = target_left
		panel.offset_right = target_right
		panel.offset_top = target_top
		panel.offset_bottom = target_bottom
		var mat := panel.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("rect_size", Vector2(width, height))
	else:
		_layout_tween = create_tween().set_parallel(true)
		_layout_tween.set_trans(Tween.TRANS_SINE)
		_layout_tween.set_ease(Tween.EASE_OUT)
		_layout_tween.tween_property(panel, "offset_left", target_left, 0.2)
		_layout_tween.tween_property(panel, "offset_right", target_right, 0.2)
		_layout_tween.tween_property(panel, "offset_top", target_top, 0.2)
		_layout_tween.tween_property(panel, "offset_bottom", target_bottom, 0.2)


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
