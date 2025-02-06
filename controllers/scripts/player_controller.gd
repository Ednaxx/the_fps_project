extends CharacterBody3D


@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5

@export var X_MOUSE_SENSITIVITY := 0.3
@export var Y_MOUSE_SENSITIVITY := 0.2
@export var TILT_LOWER_LIMIT := -90.0
@export var TILT_UPPER_LIMIT := 90.0
@export var CAMERA_CONTROLLER: Camera3D

var _mouse_rotation: Vector3
var _rotation_input: float
var _tilt_input: float
var _camera_rotation: Vector3
var _player_rotation: Vector3


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		_rotation_input = -event.relative.x * X_MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * Y_MOUSE_SENSITIVITY


func _update_camera(delta: float) -> void:
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x + _tilt_input * delta, deg_to_rad(TILT_LOWER_LIMIT), deg_to_rad(TILT_UPPER_LIMIT))
	_mouse_rotation.y += _rotation_input * delta

	_player_rotation = Vector3(0, _mouse_rotation.y, 0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0, 0)

	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0

	global_transform.basis = Basis.from_euler(_player_rotation)

	_rotation_input = 0
	_tilt_input = 0


func _ready() -> void:
	CAMERA_CONTROLLER = $Camera3D
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	_update_camera(delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	handle_movement(input_direction)

	move_and_slide()


func handle_movement(input_direction: Vector2) -> void:
	var direction := (transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
