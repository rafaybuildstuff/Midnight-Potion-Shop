extends Area2D

signal potion_brewed(potion_color: String)
signal potion_claimed(potion_color: String)
signal blast_started
signal blast_cleaned

const BREW_TIME := 3.0
const CLEAN_TIME := 5.0

const RED_HERBS := [1, 4]
const BLUE_HERBS := [2, 5]
const GREEN_HERBS := [3, 6]

var anim_sprite: AnimatedSprite2D
var interact_zone: Area2D
var countdown_label: Label
var brew_timer: Timer
var clean_timer: Timer

var player_in_range: bool = false
var current_player: Node = null
var dropped_herbs: Array[int] = []
var is_brewing: bool = false
var is_blasted: bool = false
var is_cleaning: bool = false
var ready_potion: String = "" # "", "red", "blue", or "green"


func _ready() -> void:
	anim_sprite = find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	interact_zone = find_child("InteractZone", true, false) as Area2D
	countdown_label = find_child("CountdownLabel", true, false) as Label
	brew_timer = find_child("BrewTimer", true, false) as Timer
	clean_timer = find_child("CleanTimer", true, false) as Timer

	if countdown_label == null:
		for child in get_children():
			if child is Label:
				countdown_label = child as Label
				break

	if countdown_label != null:
		countdown_label.visible = false
		countdown_label.text = ""
	else:
		push_warning("Pot: No Label child found! Add a Label node to Pot.")

	if brew_timer != null:
		brew_timer.one_shot = true
		if not brew_timer.timeout.is_connected(_on_brew_timer_timeout):
			brew_timer.timeout.connect(_on_brew_timer_timeout)

	if clean_timer != null:
		clean_timer.one_shot = true
		if not clean_timer.timeout.is_connected(_on_clean_timer_timeout):
			clean_timer.timeout.connect(_on_clean_timer_timeout)

	if interact_zone != null:
		if not interact_zone.body_entered.is_connected(_on_body_entered):
			interact_zone.body_entered.connect(_on_body_entered)
		if not interact_zone.body_exited.is_connected(_on_body_exited):
			interact_zone.body_exited.connect(_on_body_exited)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	_play_anim("idle")


func _process(_delta: float) -> void:
	if is_brewing:
		if brew_timer != null and not brew_timer.is_stopped():
			_set_label_text(str(max(1, ceili(brew_timer.time_left))))
		return

	if ready_potion != "":
		if player_in_range:
			_set_label_text("Potion Ready: " + ready_potion.to_upper() + " (X)")
		else:
			_set_label_text("Potion Ready: " + ready_potion.to_upper())
		return

	if is_cleaning:
		if clean_timer != null and not clean_timer.is_stopped():
			_set_label_text(str(max(1, ceili(clean_timer.time_left))))
		return

	if is_blasted:
		if player_in_range:
			_set_label_text("Press Q to clean")
		else:
			_hide_label()
		return

	if player_in_range:
		_set_label_text(str(dropped_herbs.size()) + "/2")
	else:
		_hide_label()


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return

	# Press Q once when blasted to start 5-second cleaning countdown
	if is_blasted and not is_cleaning:
		var pressed_q := (InputMap.has_action("clean") and event.is_action_pressed("clean"))
		if not pressed_q and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q:
			pressed_q = true
		if pressed_q:
			_start_cleaning()
			get_viewport().set_input_as_handled()
			return

	# Claim ready potion with X
	if ready_potion != "":
		var pressed_x := (InputMap.has_action("claim_potion") and event.is_action_pressed("claim_potion"))
		if not pressed_x and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X:
			pressed_x = true
		if pressed_x:
			_give_potion_to_player()
			get_viewport().set_input_as_handled()
			return

	# Add selected herb with E (up to 2 herbs)
	if event.is_action_pressed("interact") and not is_brewing and not is_blasted and not is_cleaning and ready_potion == "" and dropped_herbs.size() < 2:
		var herb_id := _consume_selected_herb()
		if herb_id > 0:
			_add_herb(herb_id)
			get_viewport().set_input_as_handled()


func _set_label_text(msg: String) -> void:
	if countdown_label != null:
		countdown_label.visible = true
		countdown_label.text = msg


func _hide_label() -> void:
	if countdown_label != null:
		countdown_label.visible = false
		countdown_label.text = ""


func _give_potion_to_player() -> void:
	var player := current_player
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_tree().root.find_child("Player", true, false)

	if player != null and player.has_method("set_held_potion"):
		if "held_potion" in player and player.held_potion != "none":
			return
		player.set_held_potion(ready_potion)
	else:
		push_warning("Pot: Player node not found or missing set_held_potion()!")

	var claimed_color := ready_potion
	ready_potion = ""
	_hide_label()
	_play_anim("idle")
	potion_claimed.emit(claimed_color)


func _consume_selected_herb() -> int:
	var inv := get_tree().get_first_node_in_group("inventory_ui")
	if inv == null:
		inv = get_tree().root.find_child("Inventory", true, false)
	if inv != null and inv.has_method("use_selected_herb"):
		return inv.use_selected_herb()
	push_warning("Pot: Inventory node not found or missing use_selected_herb()!")
	return 0


func _add_herb(herb_id: int) -> void:
	dropped_herbs.append(herb_id)
	if dropped_herbs.size() == 1:
		_set_label_text("1/2")
	elif dropped_herbs.size() == 2:
		is_brewing = true
		_set_label_text(str(int(BREW_TIME)))
		if brew_timer != null:
			brew_timer.start(BREW_TIME)
		else:
			await get_tree().create_timer(BREW_TIME).timeout
			_on_brew_timer_timeout()


func _on_brew_timer_timeout() -> void:
	is_brewing = false

	var a := dropped_herbs[0]
	var b := dropped_herbs[1]
	dropped_herbs.clear()

	var potion := _get_potion_for_pair(a, b)
	if potion != "":
		ready_potion = potion
		potion_brewed.emit(potion)
		_set_label_text("Potion Ready: " + ready_potion.to_upper() + " (X)")
	else:
		_hide_label()
		_trigger_blast()


func _trigger_blast() -> void:
	is_blasted = true
	is_cleaning = false
	_play_anim("blast")
	blast_started.emit()


func _start_cleaning() -> void:
	is_cleaning = true
	_set_label_text(str(int(CLEAN_TIME)))
	if clean_timer != null:
		clean_timer.start(CLEAN_TIME)
	else:
		await get_tree().create_timer(CLEAN_TIME).timeout
		_on_clean_timer_timeout()


func _on_clean_timer_timeout() -> void:
	is_blasted = false
	is_cleaning = false
	dropped_herbs.clear()
	ready_potion = ""
	_hide_label()
	_play_anim("idle")
	blast_cleaned.emit()


func _get_potion_for_pair(a: int, b: int) -> String:
	var pair := [a, b]
	pair.sort()

	var r := RED_HERBS.duplicate()
	r.sort()
	if pair == r:
		return "red"

	var bl := BLUE_HERBS.duplicate()
	bl.sort()
	if pair == bl:
		return "blue"

	var g := GREEN_HERBS.duplicate()
	g.sort()
	if pair == g:
		return "green"

	return ""


func _play_anim(anim_name: String) -> void:
	if anim_sprite != null and anim_sprite.sprite_frames != null and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = true
		current_player = body


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = false
		if current_player == body:
			current_player = null
