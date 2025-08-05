extends Node2D

const STARTING_COLUMNS = 10
const STARTING_ROWS = 10
const STARTING_SPEED = 0.2

const CYCLE_PRICES = [100, 1000, 10000, 100000, 1000000]
const CYCLE_GENERATED = [3, 25, 250, 2500]

@export var snake_scene : PackedScene

# Game variables
var score : int
var game_started : bool = false

# Grid variables
var initial_cell = Vector2(1, 1)
var cells_per_row = STARTING_ROWS
var cells_per_column = STARTING_COLUMNS
var cell_size = 32
var map_level = 0

# Food variables
var food_pos  : Vector2
var regen_food : bool = true
var food_eaten = 0

# Snake variables
var old_data : Array
var snake_data : Array
var snake : Array
var next_tail_index = 9
var snake_tail
var ouroboros_chain = 0

# Movement variables
var start_pos = Vector2(4, 4)
var move_direction : Vector2
var can_move : bool

# "Buildings" variables
var tick = 1
var cycle_bank = 0 :
	set(value):
		cycle_bank = value
		$UILayer/PanelContainer/MarginContainer/VBoxContainer/CycleCountLabel.text = str(cycle_bank)

var cycles_per_second = 0 :
	set(value):
		cycles_per_second = value
		$UILayer/PanelContainer/MarginContainer/VBoxContainer/CycleSecondLabel.text = str(cycles_per_second, " CPS")
		
var cycle_types_owned = [0, 0, 0, 0, 0]
var total_cycle_types_owned = 0

func _ready() -> void:
	for button in $UILayer/PanelContainer/MarginContainer/VBoxContainer/ButtonContainer.get_children():
		button.type_bought.connect(purchae_cycle_type)
		button.price_label.text = str(button.type_price, " Cycles")
		var type_name = "Hamster Wheel"
		match button.type:
			1:
				type_name = "Fan"
			2:
				type_name = "While Loop"
			3:
				type_name = "Planet"
			4:
				type_name = "Black Hole"
		button.name_label.text = type_name
	new_game()
	
func create_map():
	$Map.clear()
	$Map.position = initial_cell * cell_size
	for x in range(cells_per_row):
		var starting_tile = x + 1
		for y in range(cells_per_column):
			$Map.set_cell(Vector2(x, y), 0, Vector2(starting_tile % 2, 0))
			starting_tile += 1
	$Map.recenter(cells_per_column, cells_per_row, cell_size)
	
func new_game():
	get_tree().paused = false
	$Map.is_game_over = false
	get_tree().call_group("segments", "queue_free")
	next_tail_index = 9
	score = 0
	ouroboros_chain = 0
	map_level = 0
	food_eaten = 0
	# Reset grid size
	cells_per_column = STARTING_COLUMNS
	cells_per_row = STARTING_ROWS
	create_map()
	# Reset move timer/speed
	$GameScene/MoveTimer.wait_time = STARTING_SPEED
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
	for i in range(5):
		add_segment(start_pos + Vector2(0, i))
		
func add_segment(pos):
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	# SnakeSegment.position = (pos * cell_size)
	SnakeSegment.position = calculate_position((pos * cell_size))
	$GameScene.add_child(SnakeSegment)
	snake.append(SnakeSegment)
	# Mark the tail end
	if snake.size() == next_tail_index:
		#if snake_tail:
			#snake_tail.modulate = Color.WHITE
		snake_tail = snake[-1]
		snake_tail.modulate = Color.RED
		next_tail_index += 4
		ouroboros_chain += 1
	else:
		if snake_tail:
			snake_tail.modulate = Color.WHITE
			snake_tail = null
			if cells_per_column < 20:
				$Audio/EatSFX.stop()
				$Audio/GrowthSFX.play()
				cells_per_column += 1
				cells_per_row += 1
				map_level += 1
				create_map()
	
func _process(delta: float) -> void:
	tick -= delta
	if tick <= 0:
		cycle_bank += cycles_per_second
		tick = 1
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
	$GameScene/MoveTimer.start()
	
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
			if snake_data[i] == snake_data[-1]:
				end_game(true)
			else:
				end_game()
			# Check if snake ate its own tail
			#if snake_data[i] == snake_data[-1]:
				#var cycles_collected = get_encapsulation_size()
				#cycle_bank += cycles_collected
				#print(cycles_collected)
	 
func check_food_eaten():
	# If snake eats the food, add a segment and move the food
	if snake_data[0] == food_pos:
		$Audio/EatSFX.play()
		food_eaten += 1
		score += 3 + floori(cycles_per_second * (0.25 * map_level / 3))
		# Inscrease the speed of the snake
		$GameScene/MoveTimer.wait_time = 0.2 - (food_eaten * 0.005)
		add_segment(old_data[-1])
		move_food()
	
func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells_per_row - 1), randi_range(0, cells_per_column - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$GameScene/Food.position = calculate_position((food_pos * cell_size))
	regen_food = true
	
func end_game(ouroboros_bonus = false):
	# Show Game Over menu
	$Audio/GameOverSFX.play()
	calculate_cycle_score(ouroboros_bonus)
	$Map.is_game_over = true
	$GameScene/MoveTimer.stop()
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
	
func purchae_cycle_type(type_button : CycleTypeButton):
	var price = type_button.type_price
	if cycle_bank >= price:
		cycle_bank -= price
		var cycle_type = type_button.type
		cycle_types_owned[cycle_type] += 1
		total_cycle_types_owned += 1
		if cycle_type != 4:
			$Audio/PurchaseSFX.play()
			type_button.type_owned = cycle_types_owned[cycle_type]
			# Update Price
			type_button.type_price = ceili(type_button.type_price * 1.15)
			calculate_cps()
			#print("Bought Cycle")
		else:
			# They bought the black hole... end it all
			$BlackHoleLayer/Anim.play("activate")
	else:
		#print("Not enough loops")
		$Audio/InvalidSFX.play()
	
func calculate_cps():
	cycles_per_second = 0
	for i in range(4):
		cycles_per_second += CYCLE_GENERATED[i] * cycle_types_owned[i]
	
func calculate_cycle_score(created_ourobors = false):
	var bonus = 1
	if total_cycle_types_owned >= 3:
		bonus += 0.5 * (total_cycle_types_owned/3)
		score *= bonus
		print(str("Bonus: ", bonus))
	if created_ourobors:
		var ouroboros_bonus = 2 * ouroboros_chain
		print(str("Ouro Bonus: ", ouroboros_bonus))
		score *= ouroboros_chain
		cycle_bank += floori(score)
	else:
		cycle_bank += score
	print(str("Gained ", score, " Cycles"))
	score = 0
	
func _on_map_restart_game() -> void:
	new_game()
