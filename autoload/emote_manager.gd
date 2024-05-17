extends Node

const EMOTE_DATA_URL := "https://api.twitch.tv/helix/chat/emotes/global"
const EMOTE_STORAGE := "user://emotes/"
const EMOTE_1X_SIZE := 28

const RES_KEY_DATA := "data"
const RES_KEY_EMOTE_NAME := "name"
const RES_KEY_IMAGES := "images"
const RES_KEY_EMOTE_ID := "id"
const RES_KEY_FORMATS := "format"
const RES_KEY_TEMPLATE := "template"

const EMOTE_TEMPLATE_ID := "id"
const EMOTE_TEMPLATE_FORMAT := "format"
const EMOTE_TEMPLATE_THEME_MODE := "theme_mode"
const EMOTE_TEMPLATE_SCALE := "scale"

var _client_id: String
var _emote_url_template: String

var _request_container: Node # TODO(rp): node cleanup in container (max treshold?)

## String -> EmoteData
var _emote_data: Dictionary = {}

# TODO(rp): ANIMATED GIFS: https://github.com/BOTLANNER/godot-gif

func _ready() -> void:
	TokenServer.token_acquired.connect(
		func (_token: String) -> void: _get_emotes()
	)

	if not DirAccess.dir_exists_absolute(EMOTE_STORAGE):
		DirAccess.make_dir_absolute(EMOTE_STORAGE)

	_client_id = ConfigurationManager.client_id
	_request_container = Node.new()
	add_child(_request_container)


func is_emote(emote_key_candidate: String) -> bool:
	return _emote_data.has(_get_normalized_emote_key(emote_key_candidate))


func get_emote_texture(emote_key: String, texture_callback: Callable) -> void:
	var normalized_key: String = _get_normalized_emote_key(emote_key)

	if normalized_key not in _emote_data:
		return

	var data: EmoteData = _emote_data.get(normalized_key) as EmoteData
	if data.texture is Texture2D:
		return texture_callback.call(data.texture)

	var request_callback: Callable = func (_r: Error, _c: int, _h: PackedStringArray, body: PackedByteArray) -> void:
		texture_callback.call(_get_texture_for(normalized_key, body))

	var path: String = _get_emote_cache_path(normalized_key)
	if FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		texture_callback.call(ImageTexture.create_from_image(image))
	else:
		_request_emote(_get_emote_url(data.id), request_callback)


func _request_emote(url: String, response_handler: Callable) -> void:
	var http_request := _get_http_request()
	var result: Error = http_request.request(url)
	if result != OK:
		push_error("An error occurred in the HTTP request: %s" % url)
	http_request.request_completed.connect(response_handler, CONNECT_ONE_SHOT)


func _get_emotes() -> void:
	var _http_request := _get_http_request()

	var headers: PackedStringArray = [
		"Authorization: Bearer %s" % TokenServer.access_token,
		"Client-Id: %s" % _client_id,
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

	_emote_url_template = response.get(RES_KEY_TEMPLATE)

	for emote_entry: Dictionary in response[RES_KEY_DATA]:
		var emote_name: String = emote_entry[RES_KEY_EMOTE_NAME]
		var emote_data: EmoteData = EmoteData.new(
			emote_entry.get(RES_KEY_EMOTE_ID) as String,
			emote_name,
		)
		emote_data.is_animated = "animated" in emote_entry.get(RES_KEY_FORMATS)

		_emote_data[_get_normalized_emote_key(emote_name)] = emote_data


func _get_texture_for(emote_key: String, body: PackedByteArray) -> Texture2D:
	var path: String = _get_emote_cache_path(emote_key)
	if not FileAccess.file_exists(path):
		var image_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		image_file.store_buffer(body)
		image_file.close()

	var data: EmoteData = _emote_data.get(emote_key) as EmoteData
	var image: Image = Image.load_from_file(path)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	data.texture = texture
	return texture


## theme mode "default" - return animated emote url if that exists, otherwise
## can be "static" or "animated".
func _get_emote_url(id: String, format: String = "static", theme_mode: String = "dark", scale: float = 1.0) -> String:
	var url: String = String(_emote_url_template)
	var placeholder: String = "{{%s}}"
	url = url.replace(placeholder % EMOTE_TEMPLATE_ID, id)
	url = url.replace(placeholder % EMOTE_TEMPLATE_FORMAT, format)
	url = url.replace(placeholder % EMOTE_TEMPLATE_THEME_MODE, theme_mode)
	url = url.replace(placeholder % EMOTE_TEMPLATE_SCALE, "%2.1f" % scale) # otherwise 1.0 -> "1"
	return url


## emote_key - emote name e.g. Kappa
func _get_emote_cache_path(emote_key: String) -> String:
	return EMOTE_STORAGE + emote_key + ".png"


func _get_normalized_emote_key(emote_key: String) -> String:
	return emote_key.md5_text()


class EmoteData:
	var id: String
	var name: String
	var is_animated: bool

	# cached data
	var texture: Texture2D
	var animated_texture: AnimatedTexture


	func _init(pid: String, pname: String) -> void:
		id = pid
		name = pname
