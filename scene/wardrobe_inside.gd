extends Node2D

signal closed
signal potion_brewed(potion_color: String)

@onready var side_labels: Dictionary = {
	1: $herb1,
	2: $herb2,
	3: $herb3,
	4: $herb4,
	5: $herb5,
	6: $herb6,
}

var selected_herbs: Array[int] = []


func _ready() -> void:
	_connect_herbs(self)
	_refresh_side_labels()


func _connect_herbs(node: Node) -> void:
	for child in node.get_children():
		if child.has_signal("herb_clicked") and not child.herb_clicked.is_connected(_on_herb_clicked):
			child.herb_clicked.connect(_on_herb_clicked)
		_connect_herbs(child)


func _on_herb_clicked(herb_id: int) -> void:
	var inv := get_tree().get_first_node_in_group("inventory_ui")
	if inv != null and inv.has_method("collect_herb"):
		inv.collect_herb(herb_id)

	_refresh_side_labels()

	selected_herbs.append(herb_id)
	if selected_herbs.size() == 2:
		var potion := _check_pair(selected_herbs[0], selected_herbs[1])
		selected_herbs.clear()
		if potion != "":
			print("Brewed potion: ", potion)
			potion_brewed.emit(potion)
		else:
			print("No matching potion pair.")


func _refresh_side_labels() -> void:
	var inv := get_tree().get_first_node_in_group("inventory_ui")
	for herb_id in side_labels:
		var lbl: Label = side_labels[herb_id]
		if lbl == null:
			continue
		if inv != null and inv.has_method("get_herb_count"):
			lbl.text = str(inv.get_herb_count(herb_id))
		else:
			lbl.text = "0"


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
