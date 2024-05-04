extends ColorRect

const ChatMessageScene: PackedScene = preload("res://ui/chat_message/chat_message.tscn")
const MAX_MESSAGES: int = 6

@onready var message_container: Container = %MessageContainer


func _ready() -> void:
	ChatManager.chat_messaged.connect(_on_chat_messaged)


func _on_chat_messaged(irc_message: IRCMessage) -> void:
	var chat_message: ChatMessage = ChatMessageScene.instantiate()
	chat_message.nick = irc_message.nick
	chat_message.content = irc_message.content
	chat_message.nick_color = irc_message.nick_color
	message_container.add_child(chat_message)

	if message_container.get_child_count() == MAX_MESSAGES:
		(message_container.get_children()[0] as ChatMessage).destroy()
