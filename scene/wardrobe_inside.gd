extends Node2D

signal closed
signal potion_brewed(potion_color: String)

const MAX_HERB_COUNT := 2

var side_counts: Dictionary = {
	1: 0,
	2: 0,
	3: 0,
	4: 0,
	5: 0,
	6: 0,
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


func _get_inventory() -> Node:
	var inv := get_tree().get_first_node_in_group("inventory_ui")
	if inv == null:
		inv = get_tree().root.find_child("Inventory", true, false)
	return inv


func _on_herb_clicked(herb_id: int) -> void:
	if not side_counts.has(herb_id):
		return

	if side_counts[herb_id] >= MAX_HERB_COUNT:
		return

	side_counts[herb_id] += 1

	var inv := _get_inventory()
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


func _find_side_label(herb_id: int) -> Label:
	for candidate_name in ["herb" + str(herb_id), "herb " + str(herb_id)]:
		var node := find_child(candidate_name, true, false)
		if node is Label:
			return node as Label
	return null


func _refresh_side_labels() -> void:
	for herb_id in range(1, 7):
		var lbl := _find_side_label(herb_id)
		if lbl != null:
			lbl.text = str(side_counts.get(herb_id, 0))
			lbl.visible = true


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
