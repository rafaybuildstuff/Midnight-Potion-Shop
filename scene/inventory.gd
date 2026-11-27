extends CanvasLayer

const MAX_HERB_COUNT := 2

@onready var herb_labels: Dictionary = {
	1: $herb1,
	2: $herb2,
	3: $herb3,
	4: $herb4,
	5: $herb5,
	6: $herb6,
}

@onready var select_rects: Dictionary = {
	1: $select1,
	2: $select2,
	3: $select3,
	4: $select4,
	5: $select5,
	6: $select6,
}

var counts: Dictionary = {
	1: 0,
	2: 0,
	3: 0,
	4: 0,
	5: 0,
	6: 0,
}

var selected_slot: int = 0 # 0 = none, 1..6 = slot 1..6


func _ready() -> void:
	add_to_group("inventory_ui")
	_refresh_labels()
	_refresh_selection()


func _unhandled_input(event: InputEvent) -> void:
	for i in range(1, 7):
		var action := "slot_" + str(i)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			if selected_slot == i:
				selected_slot = 0
			else:
				selected_slot = i
			_refresh_selection()
			break


func collect_herb(herb_id: int) -> void:
	if not counts.has(herb_id):
		return
	if counts[herb_id] >= MAX_HERB_COUNT:
		return
	counts[herb_id] += 1
	_refresh_labels()


func use_selected_herb() -> int:
	if selected_slot < 1 or selected_slot > 6:
		print("Pot check: No inventory slot (1-6) selected.")
		return 0
	if counts.get(selected_slot, 0) <= 0:
		print("Pot check: Selected slot ", selected_slot, " has 0 herbs.")
		return 0
	counts[selected_slot] -= 1
	_refresh_labels()
	return selected_slot


func get_herb_count(herb_id: int) -> int:
	return counts.get(herb_id, 0)


func _refresh_labels() -> void:
	for herb_id in herb_labels:
		var lbl: Label = herb_labels[herb_id]
		if lbl != null:
			lbl.text = str(counts[herb_id])


func _refresh_selection() -> void:
	for slot_id in select_rects:
		var rect: CanvasItem = select_rects[slot_id]
		if rect != null:
			rect.visible = (slot_id == selected_slot)
