extends CharacterBody2D

@export var speed : float = 200.0
@export var jump_velocity : float = -350.0
@export var gravity : float = 900.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# "none", "red", "green", or "blue"
var held_potion: String = "none"
var facing: String = "right" # "left" or "right"


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction: float = Input.get_axis("left", "right")
	if direction != 0.0:
		velocity.x = direction * speed
		facing = "left" if direction < 0.0 else "right"
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()
	_update_animation()


func set_held_potion(potion_color: String) -> void:
	var clean_color := potion_color.strip_edges().to_lower()
	if clean_color in ["none", "red", "green", "blue"]:
		held_potion = clean_color
	else:
		held_potion = "none"
	_update_animation()


func _update_animation() -> void:
	var anim_name: String = ""

	if held_potion != "none":
		var potion_anim := facing + " " + held_potion + " potion"
		if anim.sprite_frames != null and anim.sprite_frames.has_animation(potion_anim):
			anim_name = potion_anim

	if anim_name == "":
		if not is_on_floor():
			anim_name = facing + " jump"
		elif abs(velocity.x) > 1.0:
			anim_name = "walking " + facing
		else:
			anim_name = facing + " idle"

	if anim.sprite_frames != null and anim.sprite_frames.has_animation(anim_name):
		if anim.animation != anim_name or not anim.is_playing():
			anim.play(anim_name)
