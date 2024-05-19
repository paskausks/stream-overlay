extends Node

const BADGE_DATA_URL: String = "https://api.twitch.tv/helix/chat/badges/global"
const BADGE_STORAGE := "user://badges/"

## set id -> BadgeData
var _badge_data: Dictionary = {}


func _ready() -> void:
	TokenServer.token_acquired.connect(
		func (_token: String) -> void: _get_badges()
	)


func get_badge(set_id: String, version_id: String, callback: Callable) -> void:
	if not set_id in _badge_data:
		push_warning("Set id %s not found!" % set_id)
		return

	var badge_data: BadgeData = _badge_data[set_id]

	if not version_id in badge_data.versions:
		push_warning("Version id %s not found in set %s!" % [version_id, set_id])
		return

	var badge_version: BadgeVersion = badge_data.versions[version_id]


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
	var texture: Texture2D
