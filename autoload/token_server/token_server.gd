extends Node

signal token_acquired(token: String)

const SCOPES: Array[String] = [
	"chat:edit",
	"chat:read",
	"moderator:read:followers",
]
const LISTEN_PORT: int = 3000
const LISTEN_ADDR: String = "127.0.0.1"
const TOKEN_URL: String = "/token"
const SUCCESS_URL: String = "/success"
const HEADER_SERVER: String = "Server: Godot"
const HEADER_CONTENT_TYPE: String = "Content-Type: text/html; charset=UTF-8"
const TOKEN_RECEIVE_TEMPLATE_PATH: String = "res://autoload/token_server/token_template.html"
const SUCCESS_TEMPLATE_PATH: String = "res://autoload/token_server/success_template.html"
const COLON_URIENCODED: String = "%3A"

var _server: TCPServer = TCPServer.new()
var _listen_thread: Thread = Thread.new()
var access_token: String = ""


static func needs_auth() -> bool:
	return Constants.AUTH_ARG in OS.get_cmdline_args() or not FileAccess.file_exists(Constants.ACCESS_TOKEN_PATH)


func _ready() -> void:
	if not needs_auth():
		var token_file: FileAccess = FileAccess.open(Constants.ACCESS_TOKEN_PATH, FileAccess.READ)
		access_token = token_file.get_line()
		token_file.close()
		token_acquired.emit(access_token)
		return

	OS.shell_open(_format_oauth_url())

	_server.listen(LISTEN_PORT, LISTEN_ADDR)
	_listen_thread.start(_listen_for_connections)


func _listen_for_connections() -> void:
	while _server.is_listening():
		if not _server.is_connection_available():
			continue

		call_deferred("_handle_request")


func _handle_request() -> void:
	var connection: StreamPeerTCP = _server.take_connection()

	if not connection:
		return

	if connection.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return

	var body: String = connection.get_string(connection.get_available_bytes())

	if not len(body):
		return

	if _is_token_post(body):
		_store_token(body)
		_respond(connection)
		return

	if _is_success_request(body):
		_respond(connection, _get_template(SUCCESS_TEMPLATE_PATH))
		_server.stop()
		return

	_respond(connection, _get_template(TOKEN_RECEIVE_TEMPLATE_PATH))


func _is_token_post(body: String) -> bool:
	return "POST %s" % TOKEN_URL in body


func _is_success_request(body: String) -> bool:
	return "GET %s" % SUCCESS_URL in body


func _store_token(request_body: String) -> void:
	var parts: PackedStringArray = request_body.split("\n")
	parts.reverse()

	var token_in_response: String = parts[0].strip_edges()

	access_token = token_in_response

	var token_file: FileAccess = FileAccess.open(Constants.ACCESS_TOKEN_PATH, FileAccess.WRITE)
	token_file.store_line(token_in_response)
	token_file.close()

	token_acquired.emit(access_token)

func _get_template(path: String) -> String:
	var template_file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var template: String = template_file.get_as_text()
	template_file.close()
	return template


func _respond(connection: StreamPeerTCP, content: String = "") -> void:
	var lines: Array[String] = [
		"HTTP/1.1 200 OK",
		HEADER_SERVER,
		HEADER_CONTENT_TYPE,
		"Content-Length: %d" % len(content),
		"",
		content,
	]

	connection.put_data("\n".join(lines).to_ascii_buffer())
	connection.disconnect_from_host()


func _format_oauth_url() -> String:
	var client_id: String = ConfigurationManager.client_id
	var scope_list: Array[String] = []
	for scope in SCOPES:
		scope_list.push_back(scope.replacen(":", COLON_URIENCODED))

	return "https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=%s&redirect_uri=http://%s:%d&scope=%s" % [
		client_id,
		"localhost",
		LISTEN_PORT,
		"+".join(scope_list)
	]


func _exit_tree() -> void:
	if _server.is_listening():
		_server.stop()

	if _listen_thread.is_alive():
		_listen_thread.wait_to_finish()
