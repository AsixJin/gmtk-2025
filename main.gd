extends Node2D

const STARTING_COLUMNS = 12
const STARTING_ROWS = 8
const STARTING_SPEED = 0.2

@export var snake_scene : PackedScene

# Game variables
var score : int
var game_started : bool = false

# Grid variables
var initial_cell = Vector2(3, 3)
var cells_per_row = STARTING_ROWS
var cells_per_column = STARTING_COLUMNS
var cell_size = 32

# Food variables
var food_pos  : Vector2
var regen_food : bool = true

# Snake variables
var old_data : Array
var snake_data : Array
var snake : Array
var snake_tail

# Movement variables
var start_pos = Vector2(4, 4)
var move_direction : Vector2
var can_move : bool

func _ready() -> void:
	#create_map()
	new_game()
	pass
	
func create_map():
	$Map.clear()
	$Map.position = initial_cell * cell_size
	for x in range(cells_per_row):
		var starting_tile = x + 1
		for y in range(cells_per_column):
			$Map.set_cell(Vector2(x, y), 0, Vector2(starting_tile % 2, 0))
			starting_tile += 1
	
func new_game():
	get_tree().paused = false
	$Map.is_game_over = false
	get_tree().call_group("segments", "queue_free")
	score = 0
	# Reset grid size
	cells_per_column = STARTING_COLUMNS
	cells_per_row = STARTING_ROWS
	create_map()
	# Reset move timer/speed
	$MoveTimer.wait_time = STARTING_SPEED
	# Set HUD
	move_direction = Vector2.UP
	can_move = true
	generate_snake()
	move_food()
	
func generate_snake():
	old_data.clear()
	snake_data.clear()
	snake.clear()
	# Starting with the start_pos, create tail segments vertically down
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))
		
func add_segment(pos):
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	# SnakeSegment.position = (pos * cell_size)
	SnakeSegment.position = calculate_position((pos * cell_size))
	add_child(SnakeSegment)
	snake.append(SnakeSegment)
	# Mark the tail end
	if snake.size() == 9 or snake.size() == 13 or snake.size() == 17:
		#if snake_tail:
			#snake_tail.modulate = Color.WHITE
		snake_tail = snake[-1]
		snake_tail.modulate = Color.RED
	else:
		if snake_tail:
			snake_tail.modulate = Color.WHITE
			snake_tail = null
	
func _process(delta: float) -> void:
	move_snake()
	
func move_snake():
	if can_move:
		# Update movement from keypress
		if Input.is_action_just_pressed("move_up") and move_direction != Vector2.DOWN:
			move_direction = Vector2.UP
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_right") and move_direction != Vector2.LEFT:
			move_direction = Vector2.RIGHT
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_down") and move_direction != Vector2.UP:
			move_direction = Vector2.DOWN
			can_move = false
			if not game_started:
				start_game()
		if Input.is_action_just_pressed("move_left") and move_direction != Vector2.RIGHT:
			move_direction = Vector2.LEFT
			can_move = false
			if not game_started:
				start_game()
		
func start_game():
	game_started = true
	$MoveTimer.start()
	
func _on_move_timer_timeout() -> void:
	# Allow snake movement
	can_move = true
	# Use the snake's previous position to move the segments
	old_data = [] + snake_data
	snake_data[0] += move_direction
	for i in range(len(snake_data)):
		# Move all the segments along by one
		if i > 0:
			snake_data[i] = old_data[i - 1]
		snake[i].position = calculate_position((snake_data[i] * cell_size))
	check_out_of_bounds()
	check_self_eaten()
	check_food_eaten()
	
func check_out_of_bounds():
	if snake_data[0].x < 0 or snake_data[0].x > (cells_per_row) - 1:
		end_game()
	elif snake_data[0].y < 0 or snake_data[0].y > (cells_per_column) - 1:
		end_game()
		
func check_self_eaten():
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()
			# Check if snake ate its own tail
			if snake_data[i] == snake_data[-1]:
				print(get_encapsulation_size())
	 
func check_food_eaten():
	# If snake eats the food, add a segment and move the food
	if snake_data[0] == food_pos:
		score += 1
		# Inscrease the speed of the snake
		$MoveTimer.wait_time = 0.2 - (score * 0.01)
		# Every 5 food increase the play area
		if score % 5 == 0:
			cells_per_column += 1
			cells_per_row += 1
			create_map()
		# Update HUD
		add_segment(old_data[-1])
		move_food()
	
func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells_per_row - 1), randi_range(0, cells_per_column - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$Food.position = calculate_position((food_pos * cell_size))
	regen_food = true
	
func end_game():
	# Show Game Over menu
	$Map.is_game_over = true
	$MoveTimer.stop()
	game_started = false
	get_tree().paused = true
	
func calculate_position(pos):
	return pos + (initial_cell * cell_size)
	
# This should count the square inside an ouroboros
func get_encapsulation_size() -> int:
	var unique_positions = []
	for pos in snake_data:
		if pos not in unique_positions:
			unique_positions.append(pos)
	return unique_positions.size()
	
func _on_map_restart_game() -> void:
	new_game()
