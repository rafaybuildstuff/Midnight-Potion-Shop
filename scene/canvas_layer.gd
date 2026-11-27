extends CanvasLayer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var selected_slot: int = 0 # 0 = none, 1..7 = slot 1..7
var collected_herbs: Array[int] = [] # exact herb IDs in the exact order clicked


func _ready() -> void:
	_update_anim()


func _unhandled_input(event: InputEvent) -> void:
	for i in range(1, 8):
		var action := "slot_" + str(i)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			selected_slot = i
			_update_anim()
			break


func collect_herb(herb_id: int) -> void:
	if herb_id < 1 or herb_id > 6:
		return
	if herb_id not in collected_herbs and collected_herbs.size() < 6:
		collected_herbs.append(herb_id)
		_update_anim()


func set_herb_count(count: int) -> void:
	var clamped := clampi(count, 0, 6)
	collected_herbs.clear()
	for id in range(1, clamped + 1):
		collected_herbs.append(id)
	_update_anim()


func _build_herbs_list_name() -> String:
	if collected_herbs.is_empty():
		return "idle"
	var parts: PackedStringArray = ["herb"]
	for id in collected_herbs:
		parts.append(str(id))
	return " ".join(parts)


func _update_anim() -> void:
	var candidates: Array[String] = []
	var count := collected_herbs.size()
	var herbs_list_name := _build_herbs_list_name()

	if selected_slot >= 1 and selected_slot <= 7:
		if count >= 6 and selected_slot <= 6:
			candidates.append("herb " + str(selected_slot) + " selected full inventory")
		if count >= selected_slot:
			candidates.append("herb selected " + str(selected_slot))
		candidates.append("empty " + str(selected_slot))

	if count == 6:
		candidates.append("full herbs")
		candidates.append("herb 1 2 3 4 5 6")

	if herbs_list_name != "idle":
		candidates.append(herbs_list_name)

	if count >= 1 and count <= 6:
		candidates.append("herb " + str(count))

	candidates.append("idle")

	if anim.sprite_frames == null:
		return

	for anim_name in candidates:
		if anim.sprite_frames.has_animation(anim_name):
			if anim.animation != anim_name or not anim.is_playing():
				anim.play(anim_name)
			return
