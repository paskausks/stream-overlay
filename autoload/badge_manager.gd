extends Node

const BADGE_DATA_URL: String = "https://api.twitch.tv/helix/chat/badges/global"
const BADGE_STORAGE := "user://badges/"

## set id -> BadgeData
var _badge_data: Dictionary = {}


func _ready() -> void:
	TokenServer.token_acquired.connect(
		func (_token: String) -> void: _get_badges()
	)

	if not DirAccess.dir_exists_absolute(BADGE_STORAGE):
		DirAccess.make_dir_absolute(BADGE_STORAGE)


## texture_callback expects to be called witha Texture2D
func get_badge(set_id: String, version_id: String, texture_callback: Callable) -> void:
	if not set_id in _badge_data:
		push_warning("Set id %s not found!" % set_id)
		return

	var badge_data: BadgeData = _badge_data[set_id]

	if not version_id in badge_data.versions:
		push_warning("Version id %s not found in set %s!" % [version_id, set_id])
		return

	var badge_version: BadgeVersion = badge_data.versions[version_id]
	if badge_version.texture:
		texture_callback.call(badge_version.texture)
		return

	var path: String = _create_badge_path(set_id, version_id)
	var cached_texture: Texture2D = ImageUtils.get_texture_from_disk(path)
	if cached_texture is Texture2D:
		texture_callback.call(cached_texture)
		return
	else:
		ImageUtils.cache_texture(
			badge_version.image_url_2x,
			path,
			func (texture: Texture2D) -> void:
				texture_callback.call(texture)
				badge_version.texture = texture
		)


func _create_badge_path(set_id: String, version_id: String) -> String:
	return "%s%s_%s.png" % [BADGE_STORAGE, set_id, version_id]


func _get_badges() -> void:
	var http_request := HTTP.get_http_request()
	http_request.request_completed.connect(_on_badge_data_request_completed, CONNECT_ONE_SHOT)

	var result: Error = http_request.request(BADGE_DATA_URL)
	if result != OK:
		push_error("An error occurred in the HTTP request when fetching Badges")


func _on_badge_data_request_completed(_r: int, _code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	# https://dev.twitch.tv/docs/api/reference/#get-global-chat-badges
	var data: Array = HTTP.get_response_dict(body).get("data", [])
	for set_dict: Dictionary in data:
		var set_id: String = set_dict.get("set_id")

		var versions: Dictionary = {}
		for version_dict: Dictionary in set_dict.get("versions"):
			var set_version: BadgeVersion = BadgeVersion.new()
			var version_id: String = version_dict.get("id")
			set_version.id = version_id
			set_version.image_url_1x = version_dict.get("image_url_1x")
			set_version.image_url_2x = version_dict.get("image_url_2x")
			versions[version_id] = set_version

		var badge_data: BadgeData = BadgeData.new(set_id, versions)
		_badge_data[set_id] = badge_data


class BadgeData:
	var set_id: String

	## version id -> BadgeDataSet
	var versions: Dictionary

	func _init(_set_id: String, _versions: Dictionary) -> void:
		set_id = _set_id
		versions = _versions


class BadgeVersion:
	var id: String
	var image_url_1x: String
	var image_url_2x: String
	var texture: Texture2D
