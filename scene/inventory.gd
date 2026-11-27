extends CanvasLayer

@onready var herb_labels: Dictionary = {
	1: $herb1,
	2: $herb2,
	3: $herb3,
	4: $herb4,
	5: $herb5,
	6: $herb6,
}

var counts: Dictionary = {
	1: 0,
	2: 0,
	3: 0,
	4: 0,
	5: 0,
	6: 0,
}


func _ready() -> void:
	_refresh_labels()


func collect_herb(herb_id: int) -> void:
	if not counts.has(herb_id):
		return
	counts[herb_id] += 1
	_refresh_labels()


func get_herb_count(herb_id: int) -> int:
	return counts.get(herb_id, 0)


func _refresh_labels() -> void:
	for herb_id in herb_labels:
		var lbl: Label = herb_labels[herb_id]
		if lbl != null:
			lbl.text = str(counts[herb_id])
