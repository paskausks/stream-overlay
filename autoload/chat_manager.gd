extends Node

const TWITCH_IRC_ADDRESS = "wss://irc-ws.chat.twitch.tv"
const NICK := "rpwtf"
const CHANNEL := "#theo" # e.g. "#theo"

var _client: WebSocketPeer = WebSocketPeer.new()
var _token: String
var _auth_sent: bool = false
static var _status_message_pattern: RegEx = RegEx.create_from_string(r"^:[\w\.]*\s(\d{3}).+:(.*)$")


static func parse_line(line: String) -> IRCMessageBase:
	var is_status_message: RegExMatch = _status_message_pattern.search(line)
	if not is_status_message:
		return IRCMessageBase.new()

	var groups: PackedStringArray = is_status_message.strings
	return IRCStatusMessage.new(
		int(groups[1]),
		groups[2],
	)


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
	_log(line)

	# TODO(rp): handle result, ples
	var msg: IRCMessageBase = ChatManager.parse_line(line)


func _send_auth() -> void:
	_auth_sent = true
	_client.send_text("PASS oauth:%s" % _token)
	_client.send_text("NICK %s" % NICK)
	_client.send_text("JOIN %s" % CHANNEL)


func _log(message: String) -> void:
	prints("[", Time.get_datetime_string_from_system() ,"] ", message)
