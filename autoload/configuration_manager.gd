extends Node

signal config_loaded()

const PATH_ACCESS_FILE = "user://access.ini"
const SECTION_AUTH: String = "auth"
const KEY_CLIENT_ID: String = "client_id"
const KEY_ACCESS_TOKEN: String = "access_token"

var _access_config: ConfigFile
var client_id: String:
	get: return _access_config.get_value(SECTION_AUTH, KEY_CLIENT_ID, "")

var access_token: String:
	get: return _access_config.get_value(SECTION_AUTH, KEY_ACCESS_TOKEN, "")


func _ready() -> void:
	_access_config = ConfigFile.new()
	var result: Error = _access_config.load(PATH_ACCESS_FILE)
	var access_path: String = ProjectSettings.globalize_path(PATH_ACCESS_FILE)
	if result != OK:
		push_error("Error loading config at %s!" % access_path)
		return

	config_loaded.emit()
