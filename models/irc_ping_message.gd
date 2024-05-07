class_name IRCPingMessage
extends IRCMessageBase


## if the PING message is "PING :tmi.twitch.tv"
## we respond with "PONG :tmi.twitch.tv",
## so "content" is " :tmi.twitch.tv"
var content: String


func _init(p_content: String) -> void:
	content = p_content

