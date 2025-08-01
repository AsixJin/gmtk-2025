extends Sprite2D

signal restart_game

var is_game_over = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("start") and is_game_over:
		print("Game Restarted")
		restart_game.emit()
