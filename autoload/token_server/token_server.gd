extends Node

const LISTEN_PORT: int = 3000
const LISTEN_ADDR: String = "127.0.0.1"
const TOKEN_URL: String = "/token"
const SUCCESS_URL: String = "/success"
const HEADER_SERVER: String = "Server: Godot"
const HEADER_CONTENT_TYPE: String = "Content-Type: text/html; charset=UTF-8"
const TOKEN_RECEIVE_TEMPLATE_PATH: String = "res://autoload/token_server/token_template.html"
const SUCCESS_TEMPLATE_PATH: String = "res://autoload/token_server/success_template.html"

var _server: TCPServer = TCPServer.new()
var _listen_thread: Thread = Thread.new()


func _ready() -> void:
	if not Constants.AUTH_ARG in OS.get_cmdline_args():
		queue_free()
		return

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

	var token: String = parts[0].strip_edges()

	var token_file: FileAccess = FileAccess.open(Constants.ACCESS_TOKEN_PATH, FileAccess.WRITE)
	token_file.store_line(token)
	token_file.close()


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


func _exit_tree() -> void:
	if _server.is_listening():
		_server.stop()

	if _listen_thread.is_alive():
		_listen_thread.wait_to_finish()
