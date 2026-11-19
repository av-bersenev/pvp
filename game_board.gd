extends Node2D

@onready var path_p1_node: Node2D = $Cells/Patch_P1
@onready var path_p2_node: Node2D = $Cells/Patch_P2
@onready var path_shared_node: Node2D = $Cells/Patch_Shared

@onready var player1_sprite: Sprite2D = $Players/Player1
@onready var player2_sprite: Sprite2D = $Players/Player2

@onready var status_label: Label = $UI/StatusLabel
@onready var roll_button: Button = $UI/RollButton

var players_data: Array[Dictionary] = []
var current_turn: int = 0
var is_moving: bool = false
var game_over: bool = false

func _ready() -> void:
	roll_button.pressed.connect(_on_roll_button_pressed)
	start_new_game()

func start_new_game() -> void:
	game_over = false
	is_moving = false
	current_turn = 0
	
	var left_route: Array[Vector2] = _build_route(path_p1_node)
	var right_route: Array[Vector2] = _build_route(path_p2_node)
	
	# Пока Patch_P2 пустой, оба игрока временно идут по левой ветке для проверки
	if right_route.is_empty():
		right_route = left_route.duplicate()
	
	var candidates := [
		{"name": "Красный", "sprite": player1_sprite},
		{"name": "Синий", "sprite": player2_sprite}
	]
	candidates.shuffle()
	
	players_data = [
		{
			"name": candidates[0]["name"] + " (Левый)",
			"sprite": candidates[0]["sprite"],
			"route": left_route,
			"step": 0,
			"offset": Vector2(-14, 0)
		},
		{
			"name": candidates[1]["name"] + " (Правый)",
			"sprite": candidates[1]["sprite"],
			"route": right_route,
			"step": 0,
			"offset": Vector2(14, 0)
		}
	]
	
	for p in players_data:
		p["sprite"].global_position = p["route"][0] + p["offset"]
	
	roll_button.text = "Бросить кубик"
	roll_button.disabled = false
	status_label.text = "Ходит: " + players_data[current_turn]["name"]

func _build_route(branch_node: Node2D) -> Array[Vector2]:
	var route: Array[Vector2] = []
	for cell in branch_node.get_children():
		route.append(cell.global_position)
	for cell in path_shared_node.get_children():
		route.append(cell.global_position)
	return route

func _on_roll_button_pressed() -> void:
	if game_over:
		start_new_game()
		return
	if is_moving:
		return
	
	var dice: int = randi_range(1, 6)
	var p: Dictionary = players_data[current_turn]
	var max_index: int = p["route"].size() - 1
	var target_step: int = mini(p["step"] + dice, max_index)
	
	status_label.text = "%s выбросил %d" % [p["name"], dice]
	is_moving = true
	roll_button.disabled = true
	
	if target_step > p["step"]:
		var tween := create_tween()
		for idx in range(p["step"] + 1, target_step + 1):
			var target_pos: Vector2 = p["route"][idx] + p["offset"]
			tween.tween_property(p["sprite"], "global_position", target_pos, 0.18)
		await tween.finished
	
	p["step"] = target_step
	is_moving = false
	
	if target_step == max_index:
		game_over = true
		status_label.text = "Победил: " + p["name"] + "!"
		roll_button.text = "Сыграть еще раз"
		roll_button.disabled = false
		return
	
	current_turn = 1 - current_turn
	roll_button.disabled = false
	status_label.text = "Выпало %d. Ходит: %s" % [dice, players_data[current_turn]["name"]]
