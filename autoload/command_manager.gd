extends Node

const PREFIX: String = "!"
const COMMAND_FILE: String = "user://commands.csv"
const COMMAND_FILE_COL_TRIGGER: int = 0
const COMMAND_FILE_COL_RESPONSE: int = 1

const TEMPL_USER = "user"

## String (the trigger) -> BotCommand
var commands: Dictionary = {}


func _ready() -> void:
	if not FileAccess.file_exists(COMMAND_FILE):
		return

	var command_file: FileAccess = FileAccess.open(COMMAND_FILE, FileAccess.READ)
	while not command_file.eof_reached():
		var line: PackedStringArray = command_file.get_csv_line()

		if len(line) < 2:
			# EOF
			break

		var trigger: String = line[COMMAND_FILE_COL_TRIGGER]
		var response: String = line[COMMAND_FILE_COL_RESPONSE]
		commands[trigger.to_lower()] = BotCommand.with_response(trigger, response)

	command_file.close()

	ChatManager.chat_messaged.connect(_on_chat_messaged)


func _on_chat_messaged(irc_message: IRCMessage) -> void:
	var content: String = irc_message.content

	if not len(content):
		return

	if not content[0] == PREFIX:
		# probably not a command
		return

	if irc_message.nick == ChatManager.NICK:
		# ignore own messages
		return

	var trigger: String = content.split(" ")[0].substr(1).to_lower()

	var command: BotCommand = commands.get(trigger)

	if not command is BotCommand:
		return

	command.handle(irc_message)


class BotCommand:
	var trigger: String = ""
	var response: String = ""


	static func with_response(p_trigger: String, p_response: String) -> BotCommand:
		var instance: BotCommand = BotCommand.new()
		instance.trigger = p_trigger
		instance.response = p_response
		return instance


	func handle(irc_message: IRCMessage) -> void:
		if not response is String:
			return

		var formatted: String = response.replace(
			_create_template_tag(TEMPL_USER),
			irc_message.nick
		)

		ChatManager.send_privmsg(formatted)


	func _create_template_tag(key: String) -> String:
		return "{{%s}}" % key
