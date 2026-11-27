extends Area2D

@export var recipe_page_scene: PackedScene = preload("res://scene/full_recipe_page.tscn")

var label_node: Label
var player_in_range: bool = false
var active_page: Node = null


func _ready() -> void:
	for child in get_children():
		if child is Label:
			label_node = child as Label
			break

	_hide_label()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if label_node == null:
		return

	if player_in_range and active_page == null:
		label_node.visible = true
		label_node.text = "E"
	else:
		_hide_label()


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or active_page != null:
		return

	if event.is_action_pressed("interact"):
		_open_recipe_page()
		get_viewport().set_input_as_handled()


func _open_recipe_page() -> void:
	if recipe_page_scene == null:
		push_warning("RecipePaper: Assign recipe_page_scene in the Inspector!")
		return

	var page := recipe_page_scene.instantiate()
	active_page = page
	_hide_label()
	page.tree_exited.connect(_on_page_closed)
	get_tree().current_scene.add_child(page)


func _on_page_closed() -> void:
	active_page = null


func _hide_label() -> void:
	if label_node != null:
		label_node.visible = false
		label_node.text = ""


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = false
		_hide_label()
