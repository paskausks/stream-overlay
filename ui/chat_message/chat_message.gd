class_name ChatMessage
extends Container

const NICKNAME_LUMINANCE_THRESHOLD: float = 0.33
const ChatMessageFragmentScene: PackedScene = preload("res://ui/chat_message_fragment.tscn")
const ContentBlockScene: PackedScene = preload("res://ui/content_block/content_block.tscn")
const BadgeScene: PackedScene = preload("res://ui/badge/badge.tscn")
const ChatMessageLabelSettings: Resource = preload("res://ui/chat_message_label_settings.tres")

@export var nick: String:
	set = _set_nick
@export var nick_color: Color = Color.WHITE:
	set = _set_nick_color

var badges: Array[IRCMessage.BadgeEntry]:
	set = _set_badges

@onready var nick_label: Label = %NickLabel
@onready var header_container: Container = %HeaderContainer


func _ready() -> void:
	_set_nick(nick)
	_set_nick_color(nick_color)
	_set_badges(badges)


func destroy() -> void:
	queue_free()


func get_nick_width() -> float:
	if not nick_label:
		return 0

	return nick_label.size.x


func add_content(content: String) -> void:
	var content_block: ContentBlock = ContentBlockScene.instantiate()

	if not content is String:
		return

	var parts: PackedStringArray = content.split(" ")
	for part: String in parts:
		if EmoteManager.is_emote(part):
			var texture_rect: TextureRect = TextureRect.new()
			content_block.add_content_fragment(texture_rect)
			EmoteManager.get_emote_texture(
				part,
				func (texture: Texture2D) -> void:
					texture_rect.texture = texture
			)
			continue

		var label: Label = ChatMessageFragmentScene.instantiate()
		label.text = part
		content_block.add_content_fragment(label)
	add_child(content_block)


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


func _set_badges(v: Array[IRCMessage.BadgeEntry]) -> void:
	badges = v

	if not header_container:
		return

	for badge_entry in badges:
		var badge: Badge = BadgeScene.instantiate()
		header_container.add_child(badge)
		header_container.move_child(badge, 0)
		BadgeManager.get_badge(
			badge_entry.set_id,
			badge_entry.version_id,
			func (texture: Texture2D) -> void:
				badge.texture = texture
		)


func _get_fallback_color(color: Color) -> Color:
	if color == Color.GREEN:
		# avoid nick being chrome keyed
		return Color.WHITE

	if color.get_luminance() < NICKNAME_LUMINANCE_THRESHOLD:
		return Color.WHITE

	return color
