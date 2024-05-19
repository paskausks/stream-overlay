extends Node

const BADGE_DATA_URL: String = "https://api.twitch.tv/helix/chat/badges/global"
const BADGE_STORAGE := "user://badges/"

## badge_name -> BadgeData
var _badge_data: Dictionary = {}


func _ready() -> void:
	TokenServer.token_acquired.connect(
		func (_token: String) -> void: _get_badges()
	)


func _get_badges() -> void:
	var http_request := HTTP.get_http_request()
	http_request.request_completed.connect(_on_badge_data_request_completed, CONNECT_ONE_SHOT)

	var result: Error = http_request.request(BADGE_DATA_URL)
	if result != OK:
		push_error("An error occurred in the HTTP request when fetching Badges")


func _on_badge_data_request_completed(_r: int, _code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	var data: Dictionary = HTTP.get_response_dict(body)


class BadgeData:
	var set_id: String
	var datasets: Array[BadgeDataSet]

	func _init(_set_id: String, _datasets: Array[BadgeDataSet]) -> void:
		set_id = _set_id
		datasets = _datasets


class BadgeDataSet:
	var id: String
	var image_url_1x: String
