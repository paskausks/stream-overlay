extends Node

signal chat_messaged(message: IRCMessage)

const TWITCH_IRC_ADDRESS = "wss://irc-ws.chat.twitch.tv"
const NICK := "rpwtf"
const CHANNEL := "#twitch" # e.g. "#theo"

var _client: WebSocketPeer = WebSocketPeer.new()
var _token: String
var _auth_sent: bool = false
static var _status_message_pattern: RegEx = RegEx.create_from_string(r"^:.*\s(\d{3}).+:(.*)$")


static func parse_line(line: String) -> IRCMessageBase:
	var is_status_message: RegExMatch = _status_message_pattern.search(line)
	if is_status_message:
		var groups: PackedStringArray = is_status_message.strings
		return IRCStatusMessage.new(
			int(groups[1]),
			groups[2],
		)

	if "PRIVMSG %s" % CHANNEL in line:
		return parse_privmsg(line)

	return IRCMessageBase.new()


static func parse_privmsg(line: String) -> IRCMessage:
	var parts: PackedStringArray = line.split(" :")
	var capabilities_dict: Dictionary = parse_capabilities(parts[0])
	var message: String = "".join(parts.slice(2)).strip_edges()
	var color: String = (capabilities_dict.get("color") as String).strip_edges()

	return IRCMessage.new(
		capabilities_dict.get("id") as String,
		capabilities_dict.get("display-name") as String,
		Color.html(color if len(color) else "#FFFFFF"),
		message,
	)


# e.g. "@badge-info=;badges=moderator/1;client-nonce=b8337bc15c306abf835308035601e672;..."
# will be split into {"badge-info": null, "badges": "moderator", ...}
static func parse_capabilities(capabilities_block: String) -> Dictionary:
	var result: Dictionary = {}
	for capability_pair: String in capabilities_block.strip_edges().substr(1).split(";"):
		var part: PackedStringArray = capability_pair.split("=")
		result[part[0]] = part[1]

	return result


func _ready() -> void:
	_client.connect_to_url(TWITCH_IRC_ADDRESS)

	var token_file: FileAccess = FileAccess.open("res://access_token", FileAccess.READ)
	_token = token_file.get_line().strip_edges()
	token_file.close()


func _process(_delta: float) -> void:
	_client.poll()
	var state: int = _client.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _auth_sent:
			_send_auth()
		while _client.get_available_packet_count():
			for line in _client.get_packet().get_string_from_utf8().split("\r\n"):
				_process_line(line)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code: int = _client.get_close_code()
		var reason: String = _client.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false)


func _process_line(line: String) -> void:
	var msg: IRCMessageBase = ChatManager.parse_line(line)

	if msg is IRCStatusMessage:
		var status_msg := msg as IRCStatusMessage
		_log("[%d] %s" % [status_msg.code, status_msg.message])

	if msg is IRCMessage:
		var chat_msg := msg as IRCMessage
		_log("%s: %s" % [chat_msg.nick, chat_msg.message])
		chat_messaged.emit(chat_msg)


func _send_auth() -> void:
	_auth_sent = true
	_client.send_text("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
	_client.send_text("PASS oauth:%s" % _token)
	_client.send_text("NICK %s" % NICK)
	_client.send_text("JOIN %s" % CHANNEL)


func _log(message: String) -> void:
	prints("[", Time.get_datetime_string_from_system() ,"] ", message)
