class_name IRCStatusMessage
extends IRCMessageBase

var code: int
var message: String


@warning_ignore("untyped_declaration")
func _init(new_code: int, new_message: String):
	code = new_code
	message = new_message
