class_name ContentBlock
extends MarginContainer


@onready var content_container: Container = %ContentContainer

var queue: Array[Node] = []


func _ready() -> void:
	for node in queue:
		content_container.add_child(node)
	queue = []


func add_content_fragment(fragment: Node) -> void:
	if not content_container:
		queue.append(fragment)
		return

	content_container.add_child(fragment)
