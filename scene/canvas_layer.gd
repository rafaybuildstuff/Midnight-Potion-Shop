extends CanvasLayer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var selected_slot: int = 0 # 0 = none, 1..7 = slot 1..7
var herb_count: int = 0 # 0..6 herbs collected


func _ready() -> void:
	_update_anim()


func _unhandled_input(event: InputEvent) -> void:
	for i in range(1, 8):
		var action := "slot_" + str(i)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			selected_slot = i
			_update_anim()
			break


func set_herb_count(count: int) -> void:
	herb_count = clampi(count, 0, 6)
	_update_anim()


func _update_anim() -> void:
	var anim_name := "idle"

	if selected_slot >= 1 and selected_slot <= 6 and herb_count >= selected_slot:
		anim_name = "herb selected " + str(selected_slot)
	elif selected_slot >= 1 and selected_slot <= 7:
		anim_name = "empty " + str(selected_slot)
	elif herb_count == 6:
		anim_name = "full herbs"
	elif herb_count >= 1 and herb_count <= 6:
		anim_name = "herb " + str(herb_count)

	if anim.sprite_frames != null and anim.sprite_frames.has_animation(anim_name):
		anim.play(anim_name)
