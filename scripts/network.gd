extends Node

signal status_changed(message: String)
signal room_ready(code: String)
signal join_failed(reason: String)
signal joined()

# Check the netfox docs for the current public test instance.
const NORAY_HOST := "tomfol.io"
const NORAY_PORT := 8890

const GAME_SCENE := "res://scenes/space/space.tscn"

var is_host := false
var _registered := false
var _room_code := ""
var _target_oid := ""

func _ready() -> void:
	Noray.on_oid.connect(func(oid: String): _room_code = oid)
	Noray.on_connect_nat.connect(_on_noray_connect.bind(false))
	Noray.on_connect_relay.connect(_on_noray_connect.bind(true))
	multiplayer.connected_to_server.connect(func(): joined.emit())
	multiplayer.connection_failed.connect(func(): join_failed.emit("Couldn't connect to the host."))
	multiplayer.peer_connected.connect(func(_id): status_changed.emit("Friend connected!"))

# Every player (host AND client) must do this once.
func _register() -> Error:
	if _registered:
		return OK
	status_changed.emit("Connecting to server...")
	var err: Error = await Noray.connect_to_host(NORAY_HOST, NORAY_PORT)
	if err != OK:
		return err
	Noray.register_host()
	await Noray.on_pid
	if _room_code.is_empty():
		await Noray.on_oid
	err = await Noray.register_remote()
	if err != OK:
		return err
	_registered = true
	return OK

func host() -> void:
	is_host = true
	var err: Error = await _register()
	if err != OK:
		join_failed.emit("Couldn't reach the Noray server.")
		return
	var peer := ENetMultiplayerPeer.new()
	err = peer.create_server(Noray.local_port)
	if err != OK:
		join_failed.emit("Couldn't start room.")
		return
	multiplayer.multiplayer_peer = peer
	room_ready.emit(_room_code)
	status_changed.emit("Waiting for a friend to join...")

func join(code: String) -> void:
	is_host = false
	_target_oid = code
	var err: Error = await _register()
	if err != OK:
		join_failed.emit("Couldn't reach the Noray Server.")
		return
	status_changed.emit("Connecting...")
	Noray.connect_nat(code)

# Noray tells BOTH sides to connect once a join request comes in.
func _on_noray_connect(adress: String, port: int, is_relay: bool) -> void:
	var err: Error
	if is_host:
		var host_peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
		if host_peer == null:
			return
		err = await PacketHandshake.over_enet(host_peer.host, adress, port)
	else:
		var udp := PacketPeerUDP.new()
		udp.bind(Noray.local_port)
		udp.set_dest_address(adress, port)
		err = await PacketHandshake.over_packet_peer(udp)
		udp.close()
		if err == OK:
			var client_peer := ENetMultiplayerPeer.new()
			err = client_peer.create_client(adress, port, 0, 0, 0, Noray.local_port)
			if err == OK:
				multiplayer.multiplayer_peer = client_peer
	if err != OK and not is_host:
		if not is_relay:
			status_changed.emit("Direct connection failed, trying relay...")
			Noray.connect_relay(_target_oid)
		else:
			join_failed.emit("Couldn't connect. Check the code and try again.")

func start_game() -> void:
	if not multiplayer.is_server():
		return
	_load_game.rpc()

@rpc("authority", "call_local", "reliable")
func _load_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

# helper function to get local player, multiplayer purposes only lol
func get_local_player() -> Player:
	for p in get_tree().get_nodes_in_group("players"):
		if p is Player and p.is_multiplayer_authority():
			return p
	return null
