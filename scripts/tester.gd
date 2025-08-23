extends Node

@onready var player = $player
@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_player.play("spin")
	$enviroment.play("start")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _physics_process(delta: float) -> void:
	if player.transform.origin.y <= -25:
		player.transform.origin = Vector3(0, 0, 0)  # Move to a new position
