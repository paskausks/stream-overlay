extends Node

signal chat_messaged(message: IRCMessage)

const TWITCH_IRC_ADDRESS: String = "wss://irc-ws.chat.twitch.tv"
const CAPABILITY_BADGES: String = "badges"

var _client: WebSocketPeer = WebSocketPeer.new()
var _auth_sent: bool = false
var _nickname: String = ""
var _channel: String = ""
static var _status_message_pattern: RegEx = RegEx.create_from_string(r"^:.*\s(\d{3}).+:(.*)$")


static func parse_line(line: String) -> IRCMessageBase:
	var is_status_message: RegExMatch = _status_message_pattern.search(line)
	if is_status_message:
		var groups: PackedStringArray = is_status_message.strings
		return IRCStatusMessage.new(
			int(groups[1]),
			groups[2],
		)

	if "PRIVMSG %s" % ConfigurationManager.channel in line:
		return parse_privmsg(line)

	if line.to_lower().substr(0, 4) == "ping":
		return IRCPingMessage.new(line.substr(4))

	return IRCMessageBase.new()


static func parse_privmsg(line: String) -> IRCMessage:
	var parts: PackedStringArray = line.split(" :")
	var capabilities_dict: Dictionary = parse_capabilities(parts[0])
	var message: String = "".join(parts.slice(2)).strip_edges()
	var color: String = (capabilities_dict.get("color") as String).strip_edges()

	# badges are "/"-separated strings e.g. "moderator/1" where "moderator"
	# is the set id and "1" is the "id" of the version in the set.
	var badges: PackedStringArray = (capabilities_dict.get(CAPABILITY_BADGES, "") as String).split(",")
	var badge_entries: Array[IRCMessage.BadgeEntry] = []

	for raw_badge_entry: String in badges:
		var badge_parts: PackedStringArray = raw_badge_entry.split("/")
		badge_entries.append(IRCMessage.BadgeEntry.new(
			badge_parts[0],
			badge_parts[1]
		))

	return IRCMessage.new(
		capabilities_dict.get("id") as String,
		capabilities_dict.get("display-name") as String,
		Color.html(color if len(color) else "#FFFFFF"),
		message,
		badge_entries,
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
	set_process(false)
	if Constants.TEST_ARG in OS.get_cmdline_args():
		_integration_test()
		return

	_nickname = ConfigurationManager.nickname
	_channel = ConfigurationManager.channel

	TokenServer.token_acquired.connect(
		func (_token: String) -> void:
			set_process(true)
			_client.connect_to_url(TWITCH_IRC_ADDRESS)
	)


func send_privmsg(text: String) -> void:
	if not _client:
		return

	var chat_msg: IRCMessage = IRCMessage.new(
		str(Time.get_unix_time_from_system()),
		_nickname,
		Color.WHITE,
		text,
		[],
	)

	if _client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_log("Can't send message \"%s\", not connected!" % text)
		chat_messaged.emit(chat_msg)
		return

	chat_messaged.emit(chat_msg)

	_client.send_text("PRIVMSG %s :%s" % [_channel, text])


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
		_log("%s: %s" % [chat_msg.nick, chat_msg.content])
		chat_messaged.emit(chat_msg)

	if msg is IRCPingMessage:
		_log("Got PINGed by Twitch. PONGing back.")
		_client.send_text("PONG %s" % (msg as IRCPingMessage).content)


func _send_auth() -> void:
	_auth_sent = true
	_client.send_text("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
	_client.send_text("PASS oauth:%s" % TokenServer.access_token)
	_client.send_text("NICK %s" % _nickname)
	_client.send_text("JOIN %s" % _channel)


func _log(message: String) -> void:
	prints("[", Time.get_datetime_string_from_system() ,"] ", message)


func _integration_test() -> void:
	var delay: float = 0.5

	var msg1: IRCMessage = IRCMessage.new("1", "manlypink", Color.RED, "hello world! Kappa", [])
	var msg2: IRCMessage = IRCMessage.new("2", "nat", Color.GRAY, "BabyRage", [IRCMessage.BadgeEntry.new("no_video", "1")])
	var msg3: IRCMessage = IRCMessage.new("3", "vito", Color.GREEN, "this is my favorite stream, LUL ig", [IRCMessage.BadgeEntry.new("no_video", "1")])
	var msg4: IRCMessage = IRCMessage.new("4", "duck", Color.GOLD, "C++ is the GOAT CoolCat", [IRCMessage.BadgeEntry.new("no_video", "1")])
	var msg5: IRCMessage = IRCMessage.new("5", "linus_torwalds", Color.LIME, "Nihil exercitationem est vero placeat fugit laborum. Animi autem amet aut laborum molestiae ut. PogChamp Consequatur deleniti voluptatem et inventore eligendi laboriosam molestias sed. Consectetur ab aut velit blanditiis. Neque enim architecto et eaque esse labore earum.", [IRCMessage.BadgeEntry.new("no_video", "1")])
	var msg6: IRCMessage = IRCMessage.new("6", "linus_tt", Color.PERU, "Nobis non veritatis nihil incidunt magni saepe laudantium. Qui eos dolorum sunt itaque. Autem tenetur beatae tempora. Quo in est reprehenderit corporis molestias ad sint totam. Qui voluptas dolor harum. Aliquid tenetur modi deserunt delectus perferendis assumenda.", [IRCMessage.BadgeEntry.new("no_video", "1")])

	var messages: Array[IRCMessage] = [
		msg1,
		msg2,
		msg5,
		msg3,
		msg4,
		msg6,
	]

	for message: IRCMessage in messages:
		create_tween().tween_callback(func () -> void: chat_messaged.emit(message)).set_delay(delay)
		delay += 0.5
