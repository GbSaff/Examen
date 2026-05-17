extends CharacterBody3D

@export_group("Stats")
@export var maxHealth : float = 100.0
@export var moveSpeed : float = 3.5
@export var damage : float = 10.0
@export var shootRange : float = 20.0
@export var shootInterval : float = 1.5
@export var shootSound : AudioStream

@onready var navAgent : NavigationAgent3D = $NavAgent
@onready var shootTimer : Timer = $ShootTimer

var health : float
var player : CharacterBody3D
var canSeePlayer : bool = false

func _ready():
	health = maxHealth
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	shootTimer.wait_time = shootInterval
	shootTimer.timeout.connect(_on_shoot_timer_timeout)
	shootTimer.start()

func _physics_process(delta):
	if player == null:
		return
	
	checkLineOfSight()
	
	if canSeePlayer:
		moveTowardPlayer()
		facePlayer()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		print("player: ", player, " | canSee: ", canSeePlayer)

func checkLineOfSight():
	var distToPlayer = global_position.distance_to(player.global_position)
	canSeePlayer = distToPlayer <= shootRange

func moveTowardPlayer():
	var distToPlayer = global_position.distance_to(player.global_position)
	if distToPlayer > 3.0:
		navAgent.target_position = player.global_position
		var nextPos = navAgent.get_next_path_position()
		var direction = (nextPos - global_position).normalized()
		velocity = direction * moveSpeed
	else:
		velocity = Vector3.ZERO
	move_and_slide()

func facePlayer():
	var lookTarget = player.global_position
	lookTarget.y = global_position.y
	look_at(lookTarget, Vector3.UP)

func _on_shoot_timer_timeout():
	if canSeePlayer and player != null:
		shoot()

func shoot():
	var distToPlayer = global_position.distance_to(player.global_position)
	if distToPlayer <= shootRange:
		if player.has_method("takeDamage"):
			player.takeDamage(damage)
	if shootSound != null:
		$ShootSound.stream = shootSound
		$ShootSound.play()

func hitscanHit(dmg : float, direction : Vector3, point : Vector3):
	takeDamage(dmg)

func takeDamage(dmg : float):
	health -= dmg
	if health <= 0:
		die()

func die():
	queue_free()
