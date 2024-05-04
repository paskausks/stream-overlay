extends Node

const EMOTE_DATA_URL := "https://api.twitch.tv/helix/chat/emotes/global"
const EMOTE_STORAGE := "user://emotes/"
const EMOTE_1X_SIZE := 28
const RES_KEY_DATA := "data"
const RES_KEY_EMOTE_NAME := "name"
const RES_KEY_IMAGES := "images"
const RES_KEY_EMOTE_1X := "url_1x"
const RES_KEY_EMOTE_2X := "url_2x"
const RES_KEY_EMOTE_4X := "url_4x"

var _client_id: String

var _request_container: Node # TODO(rp): node cleanup in container (max treshold?)

## String -> EmoteData
var _emote_data: Dictionary = {}


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(EMOTE_STORAGE):
		DirAccess.make_dir_absolute(EMOTE_STORAGE)

	_client_id = CredentialManager.get_client_id()
	_request_container = Node.new()
	add_child(_request_container)
	_get_emotes()


func is_emote(emote_key_candidate: String) -> bool:
	return _emote_data.has(emote_key_candidate)


func get_emote_texture(emote_key: String, callback: Callable) -> void:
	if emote_key not in _emote_data:
		return

	var data: EmoteData = _emote_data.get(emote_key) as EmoteData
	if data.texture is Texture2D:
		return callback.call(data.texture)

	var callable: Callable = func (_r: Error, _c: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		callback.call(_get_texture_for(emote_key, body))

	# TODO(rp): check EMOTE_STORAGE so emote doesn't have to be redownloaded

	_request_emote(data.url_1x, callable)


func _request_emote(url: String, response_handler: Callable) -> void:
	var http_request := _get_http_request()
	var result: Error = http_request.request(url)
	if result != OK:
		push_error("An error occurred in the HTTP request: %s" % url)
	http_request.request_completed.connect(response_handler, CONNECT_ONE_SHOT)


func _get_emotes() -> void:
	var _http_request := _get_http_request()

	var headers: PackedStringArray = [
		"Authorization: Bearer %s" % CredentialManager.get_token(),
		"Client-Id: %s" % CredentialManager.get_client_id(),
	]

	_http_request.request_completed.connect(_on_emote_data_request_completed, CONNECT_ONE_SHOT)

	var result: Error = _http_request.request(EMOTE_DATA_URL, headers)
	if result != OK:
		push_error("An error occurred in the HTTP request.")


func _get_http_request() -> HTTPRequest:
	var http_request := HTTPRequest.new()
	_request_container.add_child(http_request)
	return http_request


func _on_emote_data_request_completed(_res: Error, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Dictionary = json.get_data()
	for emote_entry: Dictionary in response[RES_KEY_DATA]:
		var emote_name: String = emote_entry[RES_KEY_EMOTE_NAME]
		var images: Dictionary = emote_entry[RES_KEY_IMAGES]
		_emote_data[emote_name] = EmoteData.new(
			emote_name,
			images.get(RES_KEY_EMOTE_1X) as String,
			images.get(RES_KEY_EMOTE_2X) as String,
			images.get(RES_KEY_EMOTE_4X) as String,
		)


func _get_texture_for(emote_key: String, body: PackedByteArray) -> Texture2D:
	var path: String = EMOTE_STORAGE + emote_key + ".png"
	if not FileAccess.file_exists(path):
		var image_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		image_file.store_buffer(body)
		image_file.close()

	var data: EmoteData = _emote_data.get(emote_key) as EmoteData
	var image: Image = Image.load_from_file(path)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	data.texture = texture
	return texture


class EmoteData:
	var name: String
	var url_1x: String
	var url_2x: String
	var url_4x: String
	var texture: Texture2D

	func _init(pname: String, p1x: String, p2x: String, p4x: String) -> void:
		name = pname
		url_1x = p1x
		url_2x = p2x
		url_4x = p4x

	func _to_string() -> String:
		return "Emote: %s (url: %s)" % [name, url_1x]
