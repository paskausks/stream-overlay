extends Node

const LISTEN_PORT: int = 3000
const LOCALHOST: String = "127.0.0.1"
const SUCCESS_URL: String = "/success"
const HEADER_SERVER: String = "Server: Godot"
const HEADER_CONTENT_TYPE: String = "Content-Type: text/html; charset=UTF-8"

var _server: TCPServer = TCPServer.new()
var _listen_thread: Thread = Thread.new()


func _ready() -> void:
	if not Constants.AUTH_ARG in OS.get_cmdline_args():
		queue_free()
		return

	_server.listen(LISTEN_PORT, LOCALHOST)
	_listen_thread.start(_listen_for_connections)


func _listen_for_connections() -> void:
	while 1:
		if not _server.is_listening():
			return
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
	var request_head: PackedStringArray = body.split("\n")[0].split(" ")
	var request_address: String = request_head[1]

	var response_body: String = ""
	var lines: Array[String] = []

	if SUCCESS_URL in request_address:
		response_body = "<h1>You can close this tab now!</h1>"
		lines = [
			"HTTP/1.1 200 OK",
			HEADER_SERVER,
			HEADER_CONTENT_TYPE,
			"Content-Length: %d" % len(response_body),
			"",
			response_body,
		]

	else:
		response_body = "Hello! Address is \"%s\"" % request_address
		lines = [
			"HTTP/1.1 200 OK", # TODO(rp): should redirect instead
			HEADER_SERVER,
			HEADER_CONTENT_TYPE,
			"Content-Length: %d" % len(response_body),
			"",
			response_body,
		]

	connection.put_data("\n".join(lines).to_ascii_buffer())
	connection.disconnect_from_host()

	if SUCCESS_URL in request_address:
		_server.stop()


func _exit_tree() -> void:
	if _listen_thread.is_alive():
		_listen_thread.wait_to_finish()
