extends CanvasLayer

@onready var healthLabel : Label = $Container/HealthLabel
@onready var healthProgress : ProgressBar = $Container/HealthProgress

var player : PlayerCharacter

func _ready():
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
		healthProgress.max_value = player.maxHealth
		healthProgress.value = player.health

func _process(_delta):
	if player == null:
		return
	healthProgress.value = player.health
	healthLabel.text = str(int(player.health)) + " / " + str(int(player.maxHealth))
