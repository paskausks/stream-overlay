extends Node

## Send HTTP requests to the Twitch API

const AUTHORIZATION_HEADER: String = "Authorization: Bearer %s"
const CLIENT_ID_HEADER: String = "Client-Id: %s"


static func get_default_headers() -> PackedStringArray:
	var token: String = TokenServer.access_token

	if not token:
		push_error("No access token configured!")

	return [
		AUTHORIZATION_HEADER % token,
		CLIENT_ID_HEADER % ConfigurationManager.client_id
	]


static func get_response_dict(body: PackedByteArray) -> Dictionary:
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	return json.get_data()


func get_http_request() -> TwitchHTTPRequest:
	var http_request := HTTPRequest.new()
	var twitch_request: TwitchHTTPRequest = TwitchHTTPRequest.new(http_request)
	add_child(http_request)

	# TODO(rp): This needs to probably be cleaned once in a while
	# to not grow memory after a certain point, e.g. max 5 HttpRequest
	# child nodes.

	return twitch_request
