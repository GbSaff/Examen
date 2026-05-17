extends CanvasLayer

@onready var waveLabel : Label = $Content/WaveLabel
@onready var restartButton : Button = $Content/RestartButton

func _ready():
	visible = false
	restartButton.pressed.connect(_on_restart_pressed)

func showGameOver(wave : int):
	visible = true
	waveLabel.text = "You survived to wave " + str(wave)
	# release mouse so player can click restart
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()
