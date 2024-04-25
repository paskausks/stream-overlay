extends ColorRect

const ChatMessageScene: PackedScene = preload("res://chat_message.tscn")

@onready var message_container: Container = %MessageContainer


func _ready() -> void:
	ChatManager.chat_messaged.connect(_on_chat_messaged)


func _on_chat_messaged(message: IRCMessage) -> void:
	var chat_message_scene: Label = ChatMessageScene.instantiate()
	chat_message_scene.text = "%s: %s" % [message.nick, message.message]
	message_container.add_child(chat_message_scene)

