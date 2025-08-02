class_name CycleTypeButton
extends PanelContainer

signal type_bought(button)

@onready var owned_label = $MarginContainer/TypeButton1/OwnedLabel
@onready var price_label = $MarginContainer/TypeButton1/MarginContainer/VBoxContainer/PriceLabel
@onready var name_label = $MarginContainer/TypeButton1/MarginContainer/VBoxContainer/NameLabel

@export var type = 0
@export var type_price = 100 :
	set(value):
		type_price = value
		if price_label:
			price_label.text = str(type_price, " Cycles")
var type_owned = 0 :
	set(value):
		type_owned = value
		if owned_label:
			owned_label.text = str("x", "%04d" % type_owned)

func _ready() -> void:
	pass
	
func _on_button_pressed() -> void:
	print("Button Pressed")
	type_bought.emit(self)
