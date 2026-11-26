extends Node2D

signal closed
signal potion_brewed(potion_color: String)

@onready var canvas_layer: CanvasLayer = $CanvasLayer

var selected_herbs: Array[int] = []


func _ready() -> void:
	for child in canvas_layer.get_children():
		if child.has_signal("herb_clicked"):
			child.herb_clicked.connect(_on_herb_clicked)


func _on_herb_clicked(herb_id: int) -> void:
	selected_herbs.append(herb_id)
	if selected_herbs.size() == 2:
		var potion := _check_pair(selected_herbs[0], selected_herbs[1])
		selected_herbs.clear()
		if potion != "":
			print("Brewed potion: ", potion)
			potion_brewed.emit(potion)
		else:
			print("No matching potion pair.")


func _check_pair(a: int, b: int) -> String:
	var pair := [a, b]
	pair.sort()
	if pair == [1, 2]:
		return "red"
	if pair == [3, 4]:
		return "green"
	if pair == [5, 6]:
		return "blue"
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
