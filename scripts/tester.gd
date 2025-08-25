extends Node

@onready var anim_player = $AnimationPlayer
@onready var main_menu = $CanvasLayer
@onready var address_entry = $CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/addressEntry

const PLAYER = preload("res://scenes/player.tscn")
const PORT = 6969

var ip_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)
var port
var rng = RandomNumberGenerator.new()
var enet_peer = ENetMultiplayerPeer.new()
var player

func _ready() -> void:
	port = int(rng.randf_range(1, 9999))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	anim_player.play("spin")
	$enviroment.play("start")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _on_host_pressed() -> void:
	main_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CanvasLayer2.hide()

	enet_peer.create_server(port)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)

	$CanvasLayer3.show()
	$CanvasLayer3/PanelContainer/MarginContainer/VBoxContainer/IP.text = str(ip_address)
	$CanvasLayer3/PanelContainer/MarginContainer/VBoxContainer/PORT.text = str(port)

	add_player(multiplayer.get_unique_id())

func _on_join_pressed() -> void:
	main_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CanvasLayer2.hide()

	enet_peer.create_client($CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/addressEntry.text, int($CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/addressEntry2.text))
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	player = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)

func _physics_process(delta: float) -> void:
	pass
	#if main_menu.visible == false:
		#if player.transform.origin.y <= -25:
			#player.transform.origin = Vector3(0, 0, 0)  # Move to a new position
