extends Area2D

@export var wardrobe_inside_scene: PackedScene = preload("res://scene/wardrobe_inside.tscn")

@onready var interact_label: Label = $InteractLabel

var player_in_range: bool = false
var active_wardrobe: Node = null
var active_player: Node = null


func _ready() -> void:
	interact_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" or body.is_in_group("player"):
		active_player = body
		player_in_range = true
		if active_wardrobe == null:
			interact_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "player" or body.is_in_group("player"):
		if body == active_player:
			active_player = null
		player_in_range = false
		interact_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if active_wardrobe != null:
		return
	if player_in_range and event.is_action_pressed("interact"):
		if wardrobe_inside_scene == null:
			push_warning("Wardrobe inside scene is not assigned.")
			return
		get_viewport().set_input_as_handled()
		interact_label.visible = false
		_set_player_active(false)
		active_wardrobe = wardrobe_inside_scene.instantiate()
		active_wardrobe.closed.connect(_on_wardrobe_closed)
		get_tree().current_scene.add_child(active_wardrobe)


func _on_wardrobe_closed() -> void:
	active_wardrobe = null
	_set_player_active(true)
	if player_in_range:
		interact_label.visible = true


func _set_player_active(enabled: bool) -> void:
	if active_player == null or not is_instance_valid(active_player):
		return
	active_player.set_physics_process(enabled)
	active_player.set_process_input(enabled)
	active_player.set_process_unhandled_input(enabled)
