class_name IRCMessage
extends IRCMessageBase

var id: String
var nick: String
var nick_color: Color
var content: String
var badges: PackedStringArray


func _init(_id: String, _nick: String, _nick_color: Color, _content: String, _badges: PackedStringArray) -> void:
	id = _id
	nick = _nick
	nick_color = _nick_color
	content = _content
	badges = _badges
