extends CanvasLayer

@onready var waveLabel : Label = $WaveLabel
@onready var enemiesLabel : Label = $EnemiesLabel
@onready var countdownLabel : Label = $CountdownLabel

var waveManager : Node

func _ready():
	await get_tree().process_frame
	waveManager = get_tree().get_first_node_in_group("WaveManager")

func _process(_delta):
	if waveManager == null:
		return
	
	waveLabel.text = "Wave: " + str(waveManager.getCurrentWave())
	enemiesLabel.text = "Enemies: " + str(waveManager.getEnemiesAlive())
	
	if waveManager.waitingForNextWave:
		countdownLabel.text = "Next wave in: " + str(snapped(waveManager.getCountdown(), 0.1)) + "s"
		countdownLabel.visible = true
	else:
		countdownLabel.visible = false
