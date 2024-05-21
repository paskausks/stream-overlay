class_name Badge
extends MarginContainer

@export var texture: Texture:
	set = set_texture


@onready var texture_rect: TextureRect = %TextureRect


func _ready() -> void:
	set_texture(texture)


func set_texture(new_texture: Texture) -> void:
	texture = new_texture

	if not texture_rect:
		return
	texture_rect.texture = texture
