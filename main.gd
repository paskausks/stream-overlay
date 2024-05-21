extends ColorRect

const ChatMessageScene: PackedScene = preload("res://ui/chat_message/chat_message.tscn")
const MAX_MESSAGES: int = 5

@onready var message_container: Container = %MessageContainer

var _last_message: ChatMessage


func _ready() -> void:
	if OS.is_debug_build():
		color = Color.BLACK
	ChatManager.chat_messaged.connect(_on_chat_messaged)


func _unhandled_input(_event: InputEvent) -> void:
	if not Input.is_action_just_pressed("ui_cancel"):
		return

	_quit()


func _on_chat_messaged(irc_message: IRCMessage) -> void:
	if _last_message is ChatMessage and _last_message.nick == irc_message.nick:
		_last_message.add_content(irc_message.content)
	else:
		var chat_message: ChatMessage = ChatMessageScene.instantiate()
		chat_message.nick = irc_message.nick
		chat_message.nick_color = irc_message.nick_color
		chat_message.badges = irc_message.badges
		chat_message.add_content(irc_message.content)
		message_container.add_child(chat_message)
		_last_message = chat_message

	# FIXME(rp): cleanup needs to take grouped messages in account
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


func _quit() -> void:
	var tree: SceneTree = get_tree()
	tree.root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	tree.quit()
