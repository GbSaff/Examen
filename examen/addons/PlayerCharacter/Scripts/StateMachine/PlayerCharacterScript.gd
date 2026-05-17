extends CharacterBody3D

class_name PlayerCharacter 

@export_group("Movement variables")
var moveSpeed : float
var moveAccel : float
var moveDeccel : float
var desiredMoveSpeed : float 
@export var desiredMoveSpeedCurve : Curve
@export var maxSpeed : float
@export var inAirMoveSpeedCurve : Curve
var inputDirection : Vector2 
var moveDirection : Vector3 
@export var hitGroundCooldown : float
var hitGroundCooldownRef : float 
@export var bunnyHopDmsIncre : float
@export var autoBunnyHop : bool = false
var lastFramePosition : Vector3 
var lastFrameVelocity : Vector3
var wasOnFloor : bool
var walkOrRun : String = "WalkState"
@export var baseHitboxHeight : float
@export var baseModelHeight : float
@export var heightChangeSpeed : float

@export_group("Health variables")
@export var maxHealth : float = 100.0
var health : float

@export_group("Crouch variables")
@export var crouchSpeed : float
@export var crouchAccel : float
@export var crouchDeccel : float
@export var continiousCrouch : bool = false
@export var crouchHitboxHeight : float
@export var crouchModelHeight : float

@export_group("Walk variables")
@export var walkSpeed : float
@export var walkAccel : float
@export var walkDeccel : float

@export_group("Run variables")
@export var runSpeed : float
@export var runAccel : float 
@export var runDeccel : float 
@export var continiousRun : bool = false

@export_group("Jump variables")
@export var jumpHeight : float
@export var jumpTimeToPeak : float
@export var jumpTimeToFall : float
@onready var jumpVelocity : float = (2.0 * jumpHeight) / jumpTimeToPeak
@export var jumpCooldown : float
var jumpCooldownRef : float 
@export var nbJumpsInAirAllowed : int 
var nbJumpsInAirAllowedRef : int 
var jumpBuffOn : bool = false
var bufferedJump : bool = false
@export var coyoteJumpCooldown : float
var coyoteJumpCooldownRef : float
var coyoteJumpOn : bool = false
@export_range(0.1, 1.0, 0.05) var inAirInputMultiplier: float = 1.0

@export_group("Gravity variables")
@onready var jumpGravity : float = (-2.0 * jumpHeight) / (jumpTimeToPeak * jumpTimeToPeak)
@onready var fallGravity : float = (-2.0 * jumpHeight) / (jumpTimeToFall * jumpTimeToFall)

@export_group("Footstep variables")
@export var footstepSounds : Array[AudioStream]
@export var walkStepInterval : float = 0.5
@export var runStepInterval : float = 0.3

@export_group("Keybind variables")
@export var moveForwardAction : String = ""
@export var moveBackwardAction : String = ""
@export var moveLeftAction : String = ""
@export var moveRightAction : String = ""
@export var runAction : String = ""
@export var crouchAction : String = ""
@export var jumpAction : String = ""

#references variables
@onready var camHolder : Node3D = $CameraHolder
@onready var model : MeshInstance3D = $Model
@onready var hitbox : CollisionShape3D = $Hitbox
@onready var stateMachine : Node = %StateMachine
@onready var hud : CanvasLayer = $HUD
@onready var ceilingCheck : RayCast3D = $Raycasts/CeilingCheck
@onready var floorCheck : RayCast3D = $Raycasts/FloorCheck
@onready var footstepPlayer : AudioStreamPlayer3D = $FootstepPlayer
@onready var jumpSoundPlayer : AudioStreamPlayer3D = $JumpSoundPlayer

var footstepTimer : float = 0.0

func _ready():
	moveSpeed = walkSpeed
	moveAccel = walkAccel
	moveDeccel = walkDeccel
	
	hitGroundCooldownRef = hitGroundCooldown
	jumpCooldownRef = jumpCooldown
	nbJumpsInAirAllowedRef = nbJumpsInAirAllowed
	coyoteJumpCooldownRef = coyoteJumpCooldown
	
	health = maxHealth
	add_to_group("Player")
	
func _process(_delta: float):
	displayProperties()
	
func _physics_process(_delta : float):
	modifyPhysicsProperties()
	move_and_slide()
	
func displayProperties():
	if hud != null:
		hud.displayCurrentState(stateMachine.currStateName)
		hud.displayCurrentDirection(moveDirection)
		hud.displayDesiredMoveSpeed(desiredMoveSpeed)
		hud.displayVelocity(velocity.length())
		hud.displayNbJumpsInAirAllowed(nbJumpsInAirAllowed)
		
func modifyPhysicsProperties():
	lastFramePosition = position
	lastFrameVelocity = velocity
	wasOnFloor = !is_on_floor()
	
func gravityApply(delta : float):
	if !is_on_floor():
		if velocity.y >= 0.0: velocity.y += jumpGravity * delta
		elif velocity.y < 0.0: velocity.y += fallGravity * delta

func playFootstep(interval : float, delta : float):
	footstepTimer -= delta
	if footstepTimer <= 0.0 and is_on_floor():
		footstepTimer = interval
		if footstepSounds.size() > 0:
			footstepPlayer.stream = footstepSounds[randi() % footstepSounds.size()]
			footstepPlayer.play()

func playJumpSound():
	if jumpSoundPlayer.stream != null:
		jumpSoundPlayer.play()

func takeDamage(dmg : float):
	health -= dmg
	if health <= 0:
		die()

func die():
	# stop player input
	set_process(false)
	set_physics_process(false)
	
	# stop state machine
	stateMachine.set_process(false)
	stateMachine.set_physics_process(false)
	
	# stop weapon manager
	var weaponManager = get_tree().get_first_node_in_group("WeaponManager")
	if weaponManager:
		weaponManager.set_process(false)
		weaponManager.set_physics_process(false)
	
	# free the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# show game over screen
	var gameOver = get_tree().get_first_node_in_group("GameOverScreen")
	if gameOver:
		var waveManager = get_tree().get_first_node_in_group("WaveManager")
		var wave = 0
		if waveManager:
			wave = waveManager.getCurrentWave()
		gameOver.showGameOver(wave)
	else:
		get_tree().reload_current_scene()
