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

var _emote_url_template: String

## String -> EmoteData
var _emote_data: Dictionary = {}

# TODO(rp): ANIMATED GIFS: https://github.com/BOTLANNER/godot-gif

func _ready() -> void:
	TokenServer.token_acquired.connect(
		func (_token: String) -> void: _get_emotes()
	)

	if not DirAccess.dir_exists_absolute(EMOTE_STORAGE):
		DirAccess.make_dir_absolute(EMOTE_STORAGE)


func is_emote(emote_key_candidate: String) -> bool:
	return _emote_data.has(_get_normalized_emote_key(emote_key_candidate))


## texture_callback expects to be called witha Texture2D
func get_emote_texture(emote_key: String, texture_callback: Callable) -> void:
	var normalized_key: String = _get_normalized_emote_key(emote_key)

	if normalized_key not in _emote_data:
		return

	var data: EmoteData = _emote_data.get(normalized_key) as EmoteData
	if data.texture is Texture2D:
		return texture_callback.call(data.texture)

	var path: String = _get_emote_cache_path(normalized_key)

	var cached_texture: Texture2D = ImageUtils.get_texture_from_disk(path)
	if cached_texture is Texture2D:
		texture_callback.call(cached_texture)
	else:
		ImageUtils.cache_texture(
			_get_emote_url(data.id),
			path,
			func (texture: Texture2D) -> void:
				texture_callback.call(texture)
				data.texture = texture
		)


func _get_emotes() -> void:
	var _http_request := HTTP.get_http_request()
	_http_request.request_completed.connect(_on_emote_data_request_completed, CONNECT_ONE_SHOT)

	var result: Error = _http_request.request(EMOTE_DATA_URL)
	if result != OK:
		push_error("An error occurred in the HTTP request when fetching emotes.")


func _on_emote_data_request_completed(_res: Error, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var response: Dictionary = HTTP.get_response_dict(body)

	_emote_url_template = response.get(RES_KEY_TEMPLATE)

	for emote_entry: Dictionary in response[RES_KEY_DATA]:
		var emote_name: String = emote_entry[RES_KEY_EMOTE_NAME]
		var emote_data: EmoteData = EmoteData.new(
			emote_entry.get(RES_KEY_EMOTE_ID) as String,
			emote_name,
		)
		emote_data.is_animated = "animated" in emote_entry.get(RES_KEY_FORMATS)

		_emote_data[_get_normalized_emote_key(emote_name)] = emote_data


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
