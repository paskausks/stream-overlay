extends Node

const TOKEN_FILE_PATH := "res://access_token"
const CLIENT_ID_FILE_PATH := "res://client_id"

var _token: String
var _client_id: String


func get_token() -> String:
	if len(_token):
		return _token

	var token_file: FileAccess = FileAccess.open(TOKEN_FILE_PATH, FileAccess.READ)
	_token = token_file.get_line().strip_edges()
	token_file.close()
	return _token


func get_client_id() -> String:
	if len(_client_id):
		return _client_id

	var client_id_file: FileAccess = FileAccess.open(CLIENT_ID_FILE_PATH, FileAccess.READ)
	_client_id = client_id_file.get_line().strip_edges()
	client_id_file.close()
	return _client_id

