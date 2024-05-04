class_name ChatMessage
extends Container

@export var nick: String:
	set = _set_nick
@export var nick_color: Color = Color.WHITE:
	set = _set_nick_color
@export var content: String:
	set = _set_content


@onready var nick_label: Label = %NickLabel
@onready var content_label: Label = %ContentLabel

# * twitch emotes?

func _ready() -> void:
	_set_nick(nick)
	_set_content(content)
	_set_nick_color(nick_color)


func destroy() -> void:
	queue_free()


func get_nick_width() -> float:
	if not nick_label:
		return 0

	return nick_label.size.x


func set_nick_width(width: float) -> void:
	nick_label.custom_minimum_size.x = width


func _set_nick(v: String) -> void:
	nick = v

	if not nick_label or not v is String:
		return

	nick_label.text = v


func _set_nick_color(v: Color) -> void:
	nick_color = v

	if not nick_label:
		return

	var label_settings: LabelSettings = LabelSettings.new()
	label_settings.font_color = v if v != Color.GREEN else Color.WHITE
	nick_label.label_settings = label_settings


func _set_content(v: String) -> void:
	content = v

	if not content_label or not v is String:
		return

	content_label.text = v
