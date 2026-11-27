extends Area2D

signal potion_trashed(potion_color: String)

var interact_zone: Area2D
var prompt_label: Label
var e_label: Label

var player_in_range: bool = false
var current_player: Node = null


func _ready() -> void:
	interact_zone = find_child("InteractZone", true, false) as Area2D
	prompt_label = find_child("PromptLabel", true, false) as Label
	e_label = find_child("ELabel", true, false) as Label

	if e_label == null:
		e_label = find_child("e_label", true, false) as Label

	if prompt_label == null and e_label == null:
		for child in get_children():
			if child is Label:
				e_label = child as Label
				break

	_hide_labels()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	if interact_zone != null:
		if not interact_zone.body_entered.is_connected(_on_body_entered):
			interact_zone.body_entered.connect(_on_body_entered)
		if not interact_zone.body_exited.is_connected(_on_body_exited):
			interact_zone.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	var player := _get_player()
	var holding_potion: bool = player != null and "held_potion" in player and player.held_potion != "none"

	if player_in_range:
		if e_label != null:
			if holding_potion:
				e_label.visible = true
				e_label.text = "Trash " + str(player.held_potion).to_upper() + " [E]"
			else:
				e_label.visible = true
				e_label.text = "[E]"
		if prompt_label != null:
			if holding_potion:
				prompt_label.visible = true
				prompt_label.text = "Trash " + str(player.held_potion).to_upper() + " [E]"
			else:
				prompt_label.visible = false
				prompt_label.text = ""
	else:
		_hide_labels()


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return

	if event.is_action_pressed("interact"):
		var player := _get_player()
		if player != null and "held_potion" in player and player.held_potion != "none":
			var trashed_color: String = str(player.held_potion)
			if player.has_method("set_held_potion"):
				player.set_held_potion("none")
			else:
				player.held_potion = "none"
			_hide_labels()
			potion_trashed.emit(trashed_color)
			get_viewport().set_input_as_handled()


func _hide_labels() -> void:
	if prompt_label != null:
		prompt_label.visible = false
		prompt_label.text = ""
	if e_label != null:
		e_label.visible = false
		e_label.text = ""


func _get_player() -> Node:
	if current_player != null:
		return current_player
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		p = get_tree().root.find_child("Player", true, false)
	return p


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = true
		current_player = body


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = false
		if current_player == body:
			current_player = null
		_hide_labels()
