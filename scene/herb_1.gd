extends TextureButton

signal herb_clicked(herb_id: int)

@export_range(1, 6) var herb_id: int = 1
@export var flash_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var flash_duration: float = 0.25

var _tween: Tween


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	print("Herb button pressed -> name: ", name, " | herb_id: ", herb_id)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate = flash_color
	_tween = create_tween()
	_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), flash_duration)
	herb_clicked.emit(herb_id)
