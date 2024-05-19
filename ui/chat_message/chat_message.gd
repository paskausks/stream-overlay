class_name ChatMessage
extends Container

const NICKNAME_LUMINANCE_THRESHOLD: float = 0.33
const ChatMessageFragmentScene: PackedScene = preload("res://ui/chat_message_fragment.tscn")
const ChatMessageLabelSettings: Resource = preload("res://ui/chat_message_label_settings.tres")

@export var nick: String:
	set = _set_nick
@export var nick_color: Color = Color.WHITE:
	set = _set_nick_color
@export var content: String:
	set = _set_content

var badges: Array[IRCMessage.BadgeEntry]:
	set = _set_badges

@onready var nick_label: Label = %NickLabel
@onready var content_container: Container = %ContentContainer


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

	nick_label.text = v + ":"


func _set_nick_color(v: Color) -> void:
	nick_color = v

	if not nick_label:
		return

	var label_settings: LabelSettings = ChatMessageLabelSettings.duplicate()
	label_settings.font_color = _get_fallback_color(v)
	nick_label.label_settings = label_settings


func _set_content(v: String) -> void:
	content = v

	if not content_container or not v is String:
		return

	var parts: PackedStringArray = v.split(" ")
	for part: String in parts:
		if EmoteManager.is_emote(part):
			var texture_rect: TextureRect = TextureRect.new()
			content_container.add_child(texture_rect)
			EmoteManager.get_emote_texture(
				part,
				func (texture: Texture2D) -> void:
					texture_rect.texture = texture
			)
			continue

		var label: Label = ChatMessageFragmentScene.instantiate()
		label.text = part
		content_container.add_child(label)


func _set_badges(v: Array[IRCMessage.BadgeEntry]) -> void:
	badges = v
	for badge_entry in badges:
		BadgeManager.get_badge(
			badge_entry.set_id,
			badge_entry.version_id,
			func (texture: Texture2D) -> void:
				# assign badge texture to somewhere
				pass
		)


func _get_fallback_color(color: Color) -> Color:
	if color == Color.GREEN:
		# avoid nick being chrome keyed
		return Color.WHITE

	if color.get_luminance() < NICKNAME_LUMINANCE_THRESHOLD:
		return Color.WHITE

	return color
