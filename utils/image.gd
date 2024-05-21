class_name ImageUtils


static func get_texture_from_disk(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.load_from_file(path)
	return ImageTexture.create_from_image(image)


## url - url of image
## path - destination path
## callback - Callable with the Texture2D as argument
static func cache_texture(url: String, path: String, callback: Callable) -> void:
	var http_request := HTTP.get_http_request()
	var result: Error = http_request.request(url)

	if result != OK:
		push_error("An error occurred in the HTTP request: %s" % url)

	http_request.request_completed.connect(
		func (_res: Error, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			if not len(body):
				prints("[", Time.get_datetime_string_from_system() ,"] LOG", _code, _headers)
				return
			var texture: Texture2D = store_image(path, body)
			callback.call(texture),
		CONNECT_ONE_SHOT,
	)


static func store_image(path: String, image_data: PackedByteArray) -> Texture2D:
	if not FileAccess.file_exists(path):
		var image_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		image_file.store_buffer(image_data)
		image_file.close()

	var image: Image = Image.load_from_file(path)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	return texture
