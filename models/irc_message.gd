class_name IRCMessage
extends IRCMessageBase

var id: String
var nick: String
var nick_color: Color
var content: String
var badges: Array[BadgeEntry]


func _init(_id: String, _nick: String, _nick_color: Color, _content: String, _badges: Array[BadgeEntry]) -> void:
	id = _id
	nick = _nick
	nick_color = _nick_color
	content = _content
	badges = _badges


class BadgeEntry:
	var set_id: String
	var version_id: String

	func _init(s_id: String, v_id: String) -> void:
		set_id = s_id
		version_id = v_id
