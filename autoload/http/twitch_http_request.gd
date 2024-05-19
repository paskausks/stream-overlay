
class_name TwitchHTTPRequest
extends RefCounted

var _request: HTTPRequest
var request_completed: Signal:
	get: return _request.request_completed


func _init(req: HTTPRequest) -> void:
	_request = req


func request(url: String, extra_headers: PackedStringArray = PackedStringArray()) -> Error:
	var all_headers: PackedStringArray = HTTP.get_default_headers()
	all_headers.append_array(extra_headers)
	return _request.request(url, all_headers)
