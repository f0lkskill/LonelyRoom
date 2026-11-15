## 逐字旋转和透明度渐入效果。
## 每个字符根据相对位置延迟出现，从轻微旋转和下方偏移回到正常位置。
class_name CharFadeRotateEffect
extends RichTextEffect

## BBCode 标签名，可在富文本中写作 [char_fade_rotate]...[/char_fade_rotate]。
var bbcode = "char_fade_rotate"

## 相邻字符之间的延迟，单位秒。
@export var delay_per_character: float = 0.03
## 单个字符从透明到完全显示的时长。
@export var fade_duration: float = 0.22
## 初始旋转角度，单位弧度。
@export var rotation_amount: float = 0.14
## 初始向下偏移距离，单位像素。
@export var drop_distance: float = 5.0
## 每个字符随机旋转的种子系数。
@export var random_seed: float = 12.9898

var force_complete := false


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if force_complete:
		char_fx.color.a = 1.0
		char_fx.offset = Vector2.ZERO
		return true

	var start_time := float(char_fx.relative_index) * delay_per_character
	var progress := clampf((char_fx.elapsed_time - start_time) / fade_duration, 0.0, 1.0)
	var eased := progress * progress * (3.0 - 2.0 * progress)

	char_fx.color.a = eased
	char_fx.offset = Vector2(0.0, (1.0 - eased) * drop_distance)

	var noise := sin(float(char_fx.relative_index) * random_seed) * 0.5 + 0.5
	var angle := (noise * 2.0 - 1.0) * rotation_amount * (1.0 - eased)
	char_fx.transform = char_fx.transform.rotated(angle)

	return true
