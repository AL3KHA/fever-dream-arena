extends CharacterBody3D

const JUMP_VELOCITY = 4.5
const FOV_CHANGE = 2.5
const BOB_FREQ = 2.0
const BOB_AMP = 0.08

var t_bob = 0.0
var sensitivity: float = 0.008
var speed = 5
var perspective = 1
var base_fov = 75

@onready var camera = $Node3D
@onready var fpp = $Node3D/Camera3D
@onready var tpp = $Node3D/SpringArm3D/Camera3D2
@onready var anim = $AnimationPlayer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("sprint"):
		speed += 4
	elif event.is_action_released("sprint"):
		speed = 5

func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * sensitivity)
			camera.rotate_x(-event.relative.y * sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if perspective == 4:
		perspective = 1
	if Input.is_action_just_pressed("camera change"):
		perspective += 1

		if perspective == 1 or perspective == 4:
			anim.playback_default_blend_time = 0.0
			fpp.current = true
			tpp.current = false
			anim.play("tpp_1")
		if perspective == 2:
			anim.playback_default_blend_time = 0.5
			fpp.current = false
			tpp.current = true
		if perspective == 3:
			fpp.current = false
			tpp.current = true
			anim.play("tpp_2")

		print(perspective)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 10)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 10)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 4)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 4)

	#head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	fpp.transform.origin = _headbob(t_bob)

	#fov
	var velocity_clamped = clamp(velocity.length(), 0.5, 9 * 2)
	var target_fov = base_fov + FOV_CHANGE * velocity_clamped
	fpp.fov = lerp(fpp.fov, target_fov, delta * 3.0)
	tpp.fov = lerp(fpp.fov, target_fov, delta * 3.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
	pos.x = sin(t_bob * BOB_FREQ / 2) * BOB_AMP
	return pos
