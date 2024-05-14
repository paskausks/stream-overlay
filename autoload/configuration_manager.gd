extends Node

signal config_loaded()

const PATH_ACCESS_FILE = "user://access.ini"
const ACCESS_SECTION_AUTH: String = "auth"
const KEY_CLIENT_ID: String = "client_id"
const KEY_ACCESS_TOKEN: String = "access_token"
const PATH_CONFIG_FILE = "user://config.ini"
const CONFIG_SECTION_MAIN = "main"
const KEY_NICKNAME = "nickname"
const KEY_CHANNEL = "channel"

var _access_config: ConfigFile
var _main_config: ConfigFile

var client_id: String:
	get: return _access_config.get_value(ACCESS_SECTION_AUTH, KEY_CLIENT_ID, "")

var access_token: String:
	get: return _access_config.get_value(ACCESS_SECTION_AUTH, KEY_ACCESS_TOKEN, "")

var nickname: String:
	get: return _main_config.get_value(CONFIG_SECTION_MAIN, KEY_NICKNAME, "")

var channel: String:
	get: return "#%s" % _main_config.get_value(CONFIG_SECTION_MAIN, KEY_CHANNEL, "")


func _ready() -> void:
	_access_config = ConfigFile.new()
	var result: Error = _access_config.load(PATH_ACCESS_FILE)
	if result != OK:
		push_error("Error loading access config at %s!" % ProjectSettings.globalize_path(PATH_ACCESS_FILE))
		return

	_main_config = ConfigFile.new()
	var config_result: Error = _main_config.load(PATH_CONFIG_FILE)
	if config_result != OK:
		push_error("Error loading main config at %s!" % ProjectSettings.globalize_path(PATH_CONFIG_FILE))
		return

	config_loaded.emit()
