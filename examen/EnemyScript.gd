extends CharacterBody3D

@export_group("Stats")
@export var maxHealth : float = 100.0
@export var moveSpeed : float = 3.5
@export var damage : float = 10.0
@export var shootRange : float = 20.0
@export var shootInterval : float = 1.5
@export var shootSound : AudioStream

@export_group("Behavior")
@export var idealDistance : float = 10.0
@export var tooCloseDistance : float = 5.0
@export var strafeSpeed : float = 3.0
@export var strafeChangeInterval : float = 1.5
@export var searchDuration : float = 8.5

@onready var navAgent : NavigationAgent3D = $NavAgent
@onready var shootTimer : Timer = $ShootTimer
@onready var sightRay : RayCast3D = $SightRay

var health : float
var player : CharacterBody3D
var canSeePlayer : bool = false
var strafeDirection : float = 1.0
var strafeTimer : float = 0.0
var lastKnownPlayerPos : Vector3
var searchTimer : float = 0.0
var state : String = "idle"

func _ready():
	health = maxHealth
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	sightRay.add_exception(self)
	
	shootTimer.wait_time = shootInterval
	shootTimer.timeout.connect(_on_shoot_timer_timeout)
	shootTimer.start()
	
	strafeDirection = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta):
	if player == null:
		return
	
	checkLineOfSight()
	
	if canSeePlayer:
		lastKnownPlayerPos = player.global_position
		searchTimer = searchDuration
		state = "combat"
		facePlayer()
		manageMovement(delta)
	elif searchTimer > 0.0:
		state = "search"
		searchTimer -= delta
		searchForPlayer(delta)
	else:
		state = "idle"
		velocity = Vector3.ZERO
		move_and_slide()

func checkLineOfSight():
	var distToPlayer = global_position.distance_to(player.global_position)
	if distToPlayer > shootRange:
		canSeePlayer = false
		return
	
	sightRay.target_position = to_local(player.global_position)
	sightRay.force_raycast_update()
	
	if sightRay.is_colliding():
		var hit = sightRay.get_collider()
		canSeePlayer = (hit == player)
	else:
		canSeePlayer = true

func searchForPlayer(delta):
	var distToLastKnown = global_position.distance_to(lastKnownPlayerPos)
	
	if distToLastKnown > 2.0:
		navAgent.target_position = lastKnownPlayerPos
		var nextPos = navAgent.get_next_path_position()
		var direction = (nextPos - global_position).normalized()
		velocity = direction * moveSpeed
	else:
		# reached last known position — rotate slowly looking around
		velocity = Vector3.ZERO
		rotate_y(delta * 1.5)
	
	move_and_slide()

func manageMovement(delta):
	var distToPlayer = global_position.distance_to(player.global_position)
	
	strafeTimer -= delta
	if strafeTimer <= 0.0:
		strafeTimer = strafeChangeInterval
		strafeDirection *= -1.0
	
	var toPlayer = (player.global_position - global_position).normalized()
	toPlayer.y = 0.0
	var strafeVec = toPlayer.cross(Vector3.UP).normalized()
	
	if distToPlayer < tooCloseDistance:
		velocity = (-toPlayer * moveSpeed) + (strafeVec * strafeDirection * strafeSpeed)
		
	elif distToPlayer > idealDistance:
		navAgent.target_position = player.global_position
		var nextPos = navAgent.get_next_path_position()
		var navDirection = (nextPos - global_position).normalized()
		navDirection.y = 0.0
		velocity = (navDirection * moveSpeed) + (strafeVec * strafeDirection * strafeSpeed)
		
	else:
		velocity = strafeVec * strafeDirection * strafeSpeed
	
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
