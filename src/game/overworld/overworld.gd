extends Node2D


onready var player = $Entities/LargeBoat
onready var islands = $Islands
onready var camera = $Entities/LargeBoat/Camera

onready var creation_tile_scene = preload("res://src/game/overworld/CreationTile.tscn")

export var audio_track: String = ""

var current_island: Island = null

var DEBUG = true

onready var _flag = $Flag

func _ready():
	if audio_track != "":
		AudioEngine.play_sound(audio_track)
		
#	for interaction in get_tree().get_nodes_in_group("interactive"):
#		player.connect("interact", interaction, "_on_player_interacted")
#
#	if Transitions.position_to_transition_to != null:
#		set_player_position(Transitions.position_to_transition_to)
	
	for island in islands.get_children():
		island.connect("island_entered", self, "_body_entered_island")
		island.connect("island_exited", self, "_body_exited_island")
		
	UI.connect("island_named", self, "_on_island_named")
	UI.connect("settle", self, "_on_settle_pressed")
		
	set_physics_process(false)
		

func _body_entered_island(island, body):
	if body is Player:
		current_island = island
		if island.island_name != "":
			UI.show_island_name(island.island_name)
		else:
			UI.show_name_island_dialog()
		set_physics_process(true)
	update()

func _body_exited_island(island, body):
	if body is Player:
		current_island = null
		set_physics_process(false)
		
	update()
		
func _physics_process(delta):
	if current_island.settled:
		update()
		hide_flag()
		return
		
	var interactable_tiles = get_interactable_tiles()
	if interactable_tiles != null:
		show_flag(interactable_tiles["land"]["coordinates"])
#		print(interactable_tiles)
	else:
		hide_flag()
		
	if _flag.visible:
		if Input.is_action_just_pressed("ui_accept"):
			UI.settle()
	
	update()


func get_interactable_tiles():
	var interact_position = player.global_position + 8 * player.direction
	if current_island.has_tile_at_position(interact_position):
		var coast_tile = current_island.get_tile_at_position(interact_position)
		if coast_tile.name == "atlas":
			interact_position += 16 * player.direction
			if current_island.has_tile_at_position(interact_position):
				if current_island.tile_is_occupied(interact_position):
					return
				var land_tile = current_island.get_tile_at_position(interact_position)
				if land_tile.name.begins_with("land"):
					return {
						"coast": coast_tile,
						"land": land_tile,
						"direction": player.direction,
					}
					
func _on_island_named(island_name: String):
	current_island.island_name = island_name
	UI.show_island_name(island_name)
	
func _on_settle_pressed():
	current_island.settled = true
	var interactable_tiles = get_interactable_tiles()
	player.set_physics_process(false)
	var harbor_creation_tile = creation_tile_scene.instance()
	add_child(harbor_creation_tile)
	harbor_creation_tile.position = interactable_tiles.coast.coordinates + Vector2(8, 8)
	if interactable_tiles.direction == Vector2(0, 1):
		harbor_creation_tile.rotation_degrees = 180
	elif interactable_tiles.direction == Vector2(0, -1):
		harbor_creation_tile.rotation_degrees = 0
	elif interactable_tiles.direction == Vector2(1, 0):
		harbor_creation_tile.rotation_degrees = 90
	elif interactable_tiles.direction == Vector2(-1, 0):
		harbor_creation_tile.rotation_degrees = -90
	harbor_creation_tile.set_sprite("harbor")
	harbor_creation_tile.play()
	yield(harbor_creation_tile, "finished")
	harbor_creation_tile.set_sprite("harbor_finished")
	var settlement_creation_tile = creation_tile_scene.instance()
	add_child(settlement_creation_tile)
	settlement_creation_tile.position = interactable_tiles.land.coordinates + Vector2(8, 8)
	settlement_creation_tile.set_sprite("wood_settlement_large")
	settlement_creation_tile.play()
	yield(settlement_creation_tile, "finished")
	current_island.settle(interactable_tiles)
	harbor_creation_tile.queue_free()
	settlement_creation_tile.queue_free()
	player.set_physics_process(true)
	
func _draw():
	if current_island != null and DEBUG == true:
		draw_circle(player.global_position + 8 * player.direction, 2, Color(0, 0, 0))
		draw_circle(player.global_position + 8 * player.direction, 1, Color(1, 1, 1))
		draw_circle(player.global_position + 24 * player.direction, 2, Color(0, 0, 0))
		draw_circle(player.global_position + 24 * player.direction, 1, Color(1, 1, 1))
		
func show_flag(coordinates: Vector2):
	_flag.global_position = coordinates
	_flag.show()
	
func hide_flag():
	_flag.hide()
	
