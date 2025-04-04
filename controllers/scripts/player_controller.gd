extends CharacterBody3D


@export var SPEED := 5.0
@export var JUMP_VELOCITY := 4.5

@export var FIRST_PERSON_X_MOUSE_SENSITIVITY := 0.3
@export var FIRST_PERSON_Y_MOUSE_SENSITIVITY := 0.2
@export var THIRD_PERSON_X_MOUSE_SENSITIVITY := 0.3
@export var THIRD_PERSON_Y_MOUSE_SENSITIVITY := 0.2

@export var FIRST_PERSON_TILT_LIMIT := deg_to_rad(90)
@export var THIRD_PERSON_TILT_LIMIT := deg_to_rad(60)

@export var CAMERA_ZOOM_OUT_LIMIT := 20.0
@export var CAMERA_ZOOM_IN_LIMIT := 1.0
@export var CAMERA_ZOOM_SPEED := 10.0

@export var CAMERA_PIVOT: Node3D
@export var CAMERA_ARM: SpringArm3D
var is_first_person := true

var _target_camera_distance: float
var _mouse_rotation: Vector3
var _rotation_input: float
var _tilt_input: float
var _camera_rotation: Vector3
var _player_rotation: Vector3


func _ready() -> void:
	CAMERA_PIVOT = $CameraPivot
	CAMERA_ARM = $CameraPivot/SpringArm3D
	_target_camera_distance = CAMERA_ARM.spring_length
	$CameraPivot/FirstPersonCamera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_tree().quit()
	elif event.is_action_pressed("toggle_camera"):
		toggle_camera()
	elif (Input.is_action_just_pressed("third_person_zoom_in") and !is_first_person):
		_target_camera_distance = clamp(_target_camera_distance - 1.0, CAMERA_ZOOM_IN_LIMIT, CAMERA_ZOOM_OUT_LIMIT)
	elif (Input.is_action_just_pressed("third_person_zoom_out") and !is_first_person):
		_target_camera_distance = clamp(_target_camera_distance + 1.0, CAMERA_ZOOM_IN_LIMIT, CAMERA_ZOOM_OUT_LIMIT)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		handle_mouse_motion(event)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	update_camera(delta)

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

func toggle_camera() -> void:
	is_first_person = !is_first_person
	if is_first_person:
		$CameraPivot/FirstPersonCamera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		$CameraPivot/SpringArm3D/ThirdPersonCamera.make_current()
		CAMERA_PIVOT.rotation_degrees.x = 0.0
		CAMERA_PIVOT.rotation_degrees.y = 0.0
		CAMERA_PIVOT.rotation_degrees.z = 0.0

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_first_person:
		_rotation_input = event.relative.x * FIRST_PERSON_X_MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * FIRST_PERSON_Y_MOUSE_SENSITIVITY
	else:
		_rotation_input = event.relative.x * THIRD_PERSON_X_MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * THIRD_PERSON_Y_MOUSE_SENSITIVITY

func update_camera(delta: float) -> void:
	if !is_first_person:
		CAMERA_ARM.spring_length = lerp(CAMERA_ARM.spring_length, _target_camera_distance, CAMERA_ZOOM_SPEED * delta)

	_mouse_rotation.x += _tilt_input * delta

	if is_first_person:
		_mouse_rotation.x = clamp(_mouse_rotation.x, -FIRST_PERSON_TILT_LIMIT, FIRST_PERSON_TILT_LIMIT)
	else:
		_mouse_rotation.x = clamp(_mouse_rotation.x, -THIRD_PERSON_TILT_LIMIT, THIRD_PERSON_TILT_LIMIT)

	_mouse_rotation.y -= _rotation_input * delta

	_player_rotation = Vector3(0, _mouse_rotation.y, 0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0, 0)

	if is_first_person:
		CAMERA_PIVOT.transform.basis = Basis.from_euler(_camera_rotation)
		CAMERA_PIVOT.rotation.z = 0.0
	else:
		CAMERA_PIVOT.transform.basis = Basis.from_euler(_camera_rotation)
		CAMERA_PIVOT.rotation.z = 0.0

	global_transform.basis = Basis.from_euler(_player_rotation)

	_rotation_input = 0
	_tilt_input = 0
