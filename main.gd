extends ColorRect

const ChatMessageScene: PackedScene = preload("res://ui/chat_message/chat_message.tscn")
const MAX_MESSAGES: int = 5

@onready var message_container: Container = %MessageContainer


func _ready() -> void:
	if OS.is_debug_build():
		color = Color.BLACK
	ChatManager.chat_messaged.connect(_on_chat_messaged)


func _on_chat_messaged(irc_message: IRCMessage) -> void:
	var chat_message: ChatMessage = ChatMessageScene.instantiate()
	chat_message.nick = irc_message.nick
	chat_message.content = irc_message.content
	chat_message.nick_color = irc_message.nick_color
	chat_message.badges = irc_message.badges
	message_container.add_child(chat_message)

	var child_count: int = message_container.get_child_count()
	var children := message_container.get_children()

	if child_count > MAX_MESSAGES:
		for i in child_count - MAX_MESSAGES:
			(children[i] as ChatMessage).destroy()

	var widest_nick: float = 0
	for message: ChatMessage in message_container.get_children():
		var nick_width: float = message.get_nick_width()
		if nick_width > widest_nick:
			widest_nick = nick_width

	for message: ChatMessage in message_container.get_children():
		message.set_nick_width(widest_nick)
