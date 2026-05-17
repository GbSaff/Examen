extends Node

@export var enemyScene : PackedScene
@export var spawnPoints : Array[NodePath]
@export var timeBetweenWaves : float = 10.0

var waveCounts : Array[int] = [2, 3, 2, 4, 3, 5, 4, 6, 5, 7, 6, 8]

var currentWave : int = 0
var enemiesAlive : int = 0
var waveActive : bool = false
var countdownTimer : float = 0.0
var waitingForNextWave : bool = false
var spawnedEnemies : Array = []

signal wave_started(waveNumber, enemyCount)
signal wave_ended(waveNumber)
signal enemy_died(enemiesRemaining)

@onready var waveTimer : Timer = $WaveTimer

func _ready():
	waveTimer.wait_time = timeBetweenWaves
	waveTimer.one_shot = true
	waveTimer.timeout.connect(_on_wave_timer_timeout)
	waveTimer.start()
	waitingForNextWave = true
	countdownTimer = timeBetweenWaves

func _process(delta):
	if waitingForNextWave:
		countdownTimer -= delta
		countdownTimer = max(countdownTimer, 0.0)

func _on_wave_timer_timeout():
	waitingForNextWave = false
	startNextWave()

func startNextWave():
	print("Starting wave ", currentWave + 1)
	if currentWave >= waveCounts.size():
		currentWave = waveCounts.size() - 1
	
	var count = waveCounts[currentWave]
	currentWave += 1
	waveActive = true
	enemiesAlive = count
	
	spawnWave(count)
	wave_started.emit(currentWave, count)

func spawnWave(count : int):
	var resolved = []
	for path in spawnPoints:
		resolved.append(get_node(path))
	
	spawnedEnemies.clear()
	
	for i in range(count):
		var spawnPoint = resolved[i % resolved.size()]
		var enemy = enemyScene.instantiate()
		get_tree().get_root().add_child(enemy)
		enemy.global_position = spawnPoint.global_position
		enemy.tree_exited.connect(_on_enemy_died)
		spawnedEnemies.append(enemy)

func _on_enemy_died():
	enemiesAlive -= 1
	enemiesAlive = max(enemiesAlive, 0)
	enemy_died.emit(enemiesAlive)
	print("Enemy died, remaining: ", enemiesAlive)
	
	if enemiesAlive <= 0 and waveActive:
		waveActive = false
		wave_ended.emit(currentWave)
		print("Wave ", currentWave, " ended, starting countdown")
		countdownTimer = timeBetweenWaves
		waitingForNextWave = true
		waveTimer.start()

func getEnemiesAlive() -> int:
	return enemiesAlive

func getCurrentWave() -> int:
	return currentWave

func getCountdown() -> float:
	return countdownTimer
