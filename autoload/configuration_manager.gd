extends Node

signal config_loaded()

const PATH_CONFIG_FILE = "user://config.ini"
const CONFIG_SECTION_MAIN = "main"
const KEY_NICKNAME: String = "nickname"
const KEY_CHANNEL: String = "channel"
const KEY_CLIENT_ID: String = "client_id"

var _main_config: ConfigFile

var client_id: String:
	get: return _main_config.get_value(CONFIG_SECTION_MAIN, KEY_CLIENT_ID, "")

var nickname: String:
	get: return _main_config.get_value(CONFIG_SECTION_MAIN, KEY_NICKNAME, "")

var channel: String:
	get: return "#%s" % _main_config.get_value(CONFIG_SECTION_MAIN, KEY_CHANNEL, "")


func _ready() -> void:
	_main_config = ConfigFile.new()
	var config_result: Error = _main_config.load(PATH_CONFIG_FILE)
	if config_result != OK:
		push_error("Error loading main config at %s!" % ProjectSettings.globalize_path(PATH_CONFIG_FILE))
		return

	config_loaded.emit()
