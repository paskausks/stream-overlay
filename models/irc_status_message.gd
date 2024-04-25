class_name IRCStatusMessage
extends IRCMessageBase

var code: int
var message: String


func _init(new_code: int, new_message: String) -> void:
	code = new_code
	message = new_message
