extends Node

@export var snake_scene : PackedScene

# Game variables
var score : int
var game_started : bool = false

# Grid variables
var cells_per_row = 8
var cells_per_column = 12
var cell_size = 32

# Snake variables
var old_data : Array
var snake_data : Array
var snake : Array

# Movement variables
var start_pos = Vector2(4, 4)
var move_direction : Vector2
var can_move : bool

func _ready() -> void:
	new_game()
	pass
	
func new_game():
	score = 0
	# Set HUD
	move_direction = Vector2.UP
	can_move = true
	generate_snake()
	
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
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)
	
func _process(delta: float) -> void:
	pass
