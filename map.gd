extends TileMapLayer

signal restart_game

var is_game_over = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("start") and is_game_over:
		print("Game Restarted")
		restart_game.emit()

func recenter(rows, cols, size):
	var pos = Vector2((rows * size)/2, (cols * size)/2)
	$CenterPoint.position = pos
