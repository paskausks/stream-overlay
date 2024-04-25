class_name IRCMessage
extends IRCMessageBase

var id: String
var nick: String
var color: Color
var message: String


func _init(_id: String, _nick: String, _color: Color, _message: String) -> void:
	id = _id
	nick = _nick
	color = _color
	message = _message
