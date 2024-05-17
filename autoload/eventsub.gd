extends Node

signal user_followed(event_data: FollowEvent)

# TODO(rp): GET USER ID VIA API
const USER_ID: int = 1070280418 # rpwtf
const EVENTSUB_ADDR: String = "wss://eventsub.wss.twitch.tv/ws"
const EVENTSUB_ADDR_MOCK: String = "ws://127.0.0.1:8080/ws"
const EVENT_NAME_FOLLOW: String = "channel.follow"

const ADDR_SUBSCRIPTIONS_MOCK: String = "http://127.0.0.1:8080/eventsub/subscriptions"
const ADDR_SUBSCRIPTIONS: String = "https://api.twitch.tv/helix/eventsub/subscriptions"

var _http_request: HTTPRequest
var _client: WebSocketPeer = WebSocketPeer.new()
var _session_id: String = ""
var _reconnect_url: String = ""
var _test_mode: bool = Constants.TEST_ARG in OS.get_cmdline_args()


func _ready() -> void:
	set_process(false)
	TokenServer.token_acquired.connect(
		func (_token: String) -> void:
			set_process(true)
			_client.connect_to_url(EVENTSUB_ADDR_MOCK if _test_mode else EVENTSUB_ADDR)
	)


func _process(_delta: float) -> void:
	_client.poll()
	var state: int = _client.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			_process_data(_client.get_packet().get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code: int = _client.get_close_code()
		var reason: String = _client.get_close_reason()
		print("EventSub WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false)


func _process_data(json_string: String) -> void:
	if not len(json_string):
		return

	if not len(_session_id):
		_subscribe(json_string)
	else:
		_handle_follow_event(json_string)


func _subscribe(json_string: String) -> void:
	var response: Dictionary = JSON.parse_string(json_string)
	var session_data: Dictionary = response["payload"]["session"]

	var reconnect_url: Variant = session_data.get("reconnect_url")
	_session_id = session_data["id"]
	_reconnect_url = reconnect_url if reconnect_url else ""

	_http_request = HTTPRequest.new()
	add_child(_http_request)

	var headers: PackedStringArray = [
		# requires the "moderator:read:followers" scope
		"Authorization: Bearer %s" % TokenServer.access_token,
		"Client-Id: %s" % ConfigurationManager.client_id,
		"Content-Type: application/json"
	]

	_http_request.request_completed.connect(_on_sub_req_complete, CONNECT_ONE_SHOT)

	var result: Error = _http_request.request(
		ADDR_SUBSCRIPTIONS_MOCK if _test_mode else ADDR_SUBSCRIPTIONS,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"type": EVENT_NAME_FOLLOW,
			"version": "2",
			"condition": {
				"broadcaster_user_id": str(USER_ID),
				"moderator_user_id": str(USER_ID),
			},
			"transport": {
				"method": "websocket",
				"session_id": _session_id
			}
		})
	)

	if result != OK:
		push_error("An error occurred in the HTTP request.")


func _handle_follow_event(event_json_string: String) -> void:
	var response_dict: Dictionary = JSON.parse_string(event_json_string)
	var payload: Dictionary = response_dict.get("payload", {})

	@warning_ignore("unsafe_method_access") # i swear, i usually dont do this
	var is_follow_event: bool = payload\
		.get("subscription", {})\
		.get("type", "") == EVENT_NAME_FOLLOW

	if not is_follow_event:
		return

	var event_data: Dictionary = payload.get("event", {})
	var follow_event: FollowEvent = FollowEvent.new(
		event_data.get("followed_at") as String,
		event_data.get("user_id") as String,
		event_data.get("user_login") as String,
		event_data.get("user_name") as String,
	)

	ChatManager.send_privmsg("%s, thank you for the follow!" % follow_event.user_name)

	user_followed.emit(follow_event)


func _on_sub_req_complete(_r: Error, _code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	_http_request.queue_free()


class FollowEvent:
	var followed_at: String
	var user_id: String
	var user_login: String
	var user_name: String


	func _init(p_follow_at: String, p_user_id: String, p_user_login: String, p_user_name: String) -> void:
		followed_at = p_follow_at
		user_id = p_user_id
		user_login = p_user_login
		user_name = p_user_name

