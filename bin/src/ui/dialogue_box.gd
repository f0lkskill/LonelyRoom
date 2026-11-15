## 自适应阴影对话框。
## 阴影和说话人位置实时跟随打字机当前显示出来的文本。
class_name DialogueBox
extends Control

const CHAR_EFFECT := preload("res://bin/asset/effect/char_fade_rotate.tres")

## 文本区域的最小宽度。
@export var min_content_width: float = 96.0
## 文本区域的最大宽度，超过后自动换行。
@export var max_content_width: float = 720.0
## 文本标签的最大高度。
@export var max_text_height: float = 480.0
## 阴影左右内边距。
@export var horizontal_padding: float = 24.0
## 阴影上下内边距。
@export var vertical_padding: float = 24.0
## 阴影底部与屏幕底部的距离。
@export var bottom_margin: float = 36.0
## 阴影的最小高度。
@export var min_panel_height: float = 84.0

@onready var panel: ColorRect = $Panel
@onready var content: Control = $Panel/Content
@onready var speaker_label: Label = $Panel/SpeakerLabel

var text_label: RichTextLabel

var _data
var _line_index := 0
var _is_open := false
var _fade_tween: Tween
var _effect
var _line_started_msec := 0
var _line_reveal_ms := 0.0
var _line_length := 0
var _current_line_text := ""
var _delay_per_character := 0.03
var _fade_duration := 0.22
var _line_text_height := 0.0
var _line_panel_height := 80.0


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	content.offset_left = horizontal_padding
	content.offset_top = vertical_padding
	content.offset_right = -horizontal_padding
	content.offset_bottom = -vertical_padding
	_create_text_label()
	_effect = CHAR_EFFECT
	if _effect != null:
		text_label.install_effect(_effect)
	panel.resized.connect(_sync_panel_material)
	_sync_panel_material()


## 在代码中创建富文本标签，确保尺寸完全由对话框控制。
func _create_text_label() -> void:
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.bbcode_enabled = true
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	text_label.add_theme_color_override("default_color", Color(0.96, 0.97, 1.0, 1.0))
	text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	text_label.add_theme_constant_override("outline_size", 10)
	text_label.add_theme_font_size_override("normal_font_size", 26)
	content.add_child(text_label)
	text_label.position = Vector2.ZERO
	text_label.size = Vector2(max_content_width, max_text_height)


func _process(_delta: float) -> void:
	if visible:
		_update_typewriter()
		_resize_shadow_to_text()
		_sync_panel_material()


## 根据打字机进度更新当前显示的字符数。
func _update_typewriter() -> void:
	if _data == null or text_label == null:
		return

	var count := _line_length
	if _effect == null or not bool(_effect.force_complete):
		var elapsed := maxf((Time.get_ticks_msec() - _line_started_msec) / 1000.0, 0.0)
		count = mini(_line_length, int(elapsed / maxf(_delay_per_character, 0.001)) + 1)

	text_label.visible_characters = count


## 让阴影宽度实时跟随当前已经显示出来的文本，高度保持整行固定。
func _resize_shadow_to_text() -> void:
	var count := text_label.visible_characters
	if count < 0:
		count = _line_length

	var visible_text := _current_line_text.substr(0, count)
	var text_font := text_label.get_theme_font("normal_font")
	var text_size := text_label.get_theme_font_size("normal_font_size")
	var text_width := text_font.get_string_size(visible_text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var content_width := clampf(text_width + 4.0, min_content_width, max_content_width)

	text_label.size = Vector2(content_width, max_text_height)
	var content_height := _line_panel_height - vertical_padding * 2.0
	text_label.position = Vector2(0.0, maxf((content_height - _line_text_height) * 0.5, 0.0))
	_apply_panel_rect(content_width + horizontal_padding * 2.0, _line_panel_height)


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
	_apply_panel_rect(min_content_width + horizontal_padding * 2.0, min_panel_height)
	_show_line()
	_fade_to(1.0)


## 显示下一行；最后一行结束后关闭面板。
func advance() -> void:
	if not _is_open:
		return

	if Time.get_ticks_msec() - _line_started_msec < _line_reveal_ms:
		if _effect != null:
			_effect.force_complete = true
		text_label.visible_characters = _line_length
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


## 设置当前行的说话人，并启动逐字渐入效果。
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
	_current_line_text = line_text
	_line_length = line_text.length()
	_measure_line_height(line_text)

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

	_delay_per_character = 0.03
	_fade_duration = 0.22
	if _effect != null:
		_delay_per_character = float(_effect.get("delay_per_character"))
		_fade_duration = float(_effect.get("fade_duration"))

	_line_started_msec = Time.get_ticks_msec()
	_line_reveal_ms = maxf(float(_line_length) * _delay_per_character + _fade_duration, 0.1) * 1000.0
	text_label.visible_characters = 1


## 根据完整文本计算固定行高，打字过程中高度不再变化。
func _measure_line_height(line_text: String) -> void:
	var text_font := text_label.get_theme_font("normal_font")
	var text_size := text_label.get_theme_font_size("normal_font_size")
	var line_height := text_font.get_height(text_size)
	var lines := 1
	var current_width := 0.0

	for i in line_text.length():
		var character := line_text.substr(i, 1)
		var character_width := text_font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
		if current_width > 0.0 and current_width + character_width > max_content_width:
			lines += 1
			current_width = character_width
		else:
			current_width += character_width

	_line_text_height = line_height * float(lines)
	_line_panel_height = maxf(_line_text_height + vertical_padding * 2.0, min_panel_height)


## 应用阴影尺寸和底部居中位置。
func _apply_panel_rect(width: float, height: float) -> void:
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.offset_top = -bottom_margin - height
	panel.offset_bottom = -bottom_margin

	var mat := panel.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("rect_size", Vector2(width, height))


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
