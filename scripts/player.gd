extends CharacterBody3D

const JUMP_VELOCITY = 4.5
const FOV_CHANGE = 2.5
const BOB_FREQ = 2.0
const BOB_AMP = 0.08

var t_bob = 0.0
var sensitivity: float = 0.008
var speed = 1.75
var perspective = 1
var base_fov = 75
var crouch = 1

@onready var player = $"."
@onready var camera = $Node3D
@onready var fpp = $Node3D/Camera3D
@onready var tpp = $Node3D/SpringArm3D/Camera3D2
@onready var anim = $AnimationPlayer
@onready var mov_low = $"basic movement lower body/AnimationPlayer"
@onready var mov_up = $"basic movement upper body/AnimationPlayer"
@onready var col = $CollisionShape3D
@onready var for_crouch = $Node3D/AnimationPlayer
@onready var low_body_rot = $"basic movement lower body/AnimationPlayer2"
@onready var upp_body_rot = $"basic movement upper body/AnimationPlayer2"

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	if not is_multiplayer_authority():
		return

	crouch = 1
	col.transform.origin = Vector3(0.0, 0.9, 0.0)
	col.scale = Vector3(1.0, 1.0, 1.0)
	for_crouch.play("not crouched")
	fpp.current = true
	$"basic movement lower body/Armature/Skeleton3D/Alpha_Joints".hide()
	$"basic movement lower body/Armature/Skeleton3D/Alpha_Surface".hide()
	$"basic movement upper body/Armature/Skeleton3D/Alpha_Joints".hide()
	$"basic movement upper body/Armature/Skeleton3D/Alpha_Surface".hide()
	$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Alpha_Surface".hide()
	$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Cylinder".hide()
	$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Cylinder_001".hide()

func _input(event: InputEvent) -> void:
	#sprinting
	if event.is_action_pressed("sprint"):
		speed += 4.25
	elif event.is_action_released("sprint"):
		speed = 1.75

# handling crouch
	if event.is_action_pressed("crouch"):
		crouch = 2
	if event.is_action_released("crouch"):
		crouch = 1

	if crouch == 1:
		col.transform.origin = Vector3(0.0, 0.9, 0.0)
		col.scale = Vector3(1.0, 1.0, 1.0)
		for_crouch.play("not crouched")
	elif  crouch == 2:
		col.transform.origin = Vector3(0.0, 0.7, 0.0)
		col.scale = Vector3(1.0, 0.8, 1.0)
		for_crouch.play("crouched")

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	# camera control
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * sensitivity)
			camera.rotate_x(-event.relative.y * sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# camera change
	if perspective == 4:
		perspective = 1
	if Input.is_action_just_pressed("camera change"):
		perspective += 1

		if perspective == 1 or perspective == 4:
			anim.playback_default_blend_time = 0.0
			fpp.current = true
			tpp.current = false
			$"basic movement lower body/Armature/Skeleton3D/Alpha_Joints".hide()
			$"basic movement lower body/Armature/Skeleton3D/Alpha_Surface".hide()
			$"basic movement upper body/Armature/Skeleton3D/Alpha_Joints".hide()
			$"basic movement upper body/Armature/Skeleton3D/Alpha_Surface".hide()
			$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Alpha_Surface".hide()
			$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Cylinder".hide()
			$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Cylinder_001".hide()
		if perspective == 2:
			$"basic movement lower body/Armature/Skeleton3D/Alpha_Joints".show()
			$"basic movement lower body/Armature/Skeleton3D/Alpha_Surface".show()
			$"basic movement upper body/Armature/Skeleton3D/Alpha_Joints".show()
			$"basic movement upper body/Armature/Skeleton3D/Alpha_Surface".show()
			$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Alpha_Surface".show()
			$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Cylinder".show()
			$"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head/Cylinder_001".show()
			anim.play("tpp_1")
			fpp.current = false
			tpp.current = true
		if perspective == 3:
			fpp.current = false
			tpp.current = true
			anim.play("tpp_2")

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

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
	tpp.transform.origin = _headbob(t_bob)

	#fov
	var velocity_clamped = clamp(velocity.length(), 0.5, 9 * 2)
	var target_fov = base_fov + FOV_CHANGE * velocity_clamped
	fpp.fov = lerp(fpp.fov, target_fov, delta * 3.0)
	tpp.fov = lerp(fpp.fov, target_fov, delta * 3.0)

	# movement animations for lower body
	if is_on_floor():
		if Input.is_action_pressed("forward") and not Input.is_action_pressed("right") and not Input.is_action_pressed("left") and mov_low.current_animation != "jump" and not Input.is_action_pressed("back"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("walk")
				elif crouch == 2:
					mov_low.play("crouched walking")
			elif speed == 6:
				mov_low.play("running")
				crouch = 1
			low_body_rot.play("normal")
		elif Input.is_action_pressed("forward") and Input.is_action_pressed("right") and mov_low.current_animation != "jump" and not Input.is_action_pressed("back"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("walk")
				elif crouch == 2:
					mov_low.play("crouched walking")
			elif speed == 6:
				mov_low.play("running")
				crouch = 1
			low_body_rot.play("right")
		elif Input.is_action_pressed("forward") and Input.is_action_pressed("left") and mov_low.current_animation != "jump" and not Input.is_action_pressed("back"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("walk")
				elif crouch == 2:
					mov_low.play("crouched walking")
			elif speed == 6:
				mov_low.play("running")
				crouch = 1
			low_body_rot.play("left")
		elif Input.is_action_pressed("back") and not Input.is_action_pressed("right") and not Input.is_action_pressed("left") and mov_low.current_animation != "jump":
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("walking backwards")
				elif  crouch == 2:
					mov_low.play("crouched walking back")
			elif speed == 6:
				mov_low.play("running backwards")
				crouch = 1
			low_body_rot.play("normal")
		elif Input.is_action_pressed("back") and Input.is_action_pressed("right") and mov_low.current_animation != "jump" and not Input.is_action_pressed("forward"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("walking backwards")
				elif  crouch == 2:
					mov_low.play("crouched walking back")
			elif speed == 6:
				mov_low.play("running backwards")
				crouch = 1
			low_body_rot.play("left")
		elif Input.is_action_pressed("back") and Input.is_action_pressed("left") and mov_low.current_animation != "jump" and not Input.is_action_pressed("forward"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("walking backwards")
				elif  crouch == 2:
					mov_low.play("crouched walking back")
			elif speed == 6:
				mov_low.play("running backwards")
				crouch = 1
			low_body_rot.play("right")
		elif Input.is_action_pressed("left") and mov_low.current_animation != "jump" and not Input.is_action_pressed("right"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("left strafe walking")
				elif crouch == 2:
					mov_low.play("crouching left")
			if speed == 6:
				mov_low.play("left strafe")
				crouch = 1
			low_body_rot.play("normal")
		elif Input.is_action_pressed("right") and mov_low.current_animation != "jump" and not Input.is_action_pressed("left"):
			if speed == 1.75:
				if crouch == 1:
					mov_low.play("right strafe walking")
				elif  crouch == 2:
					mov_low.play("crouching right")
			if speed == 6:
				mov_low.play("right strafe")
				crouch = 1
			low_body_rot.play("normal")
		elif mov_low.current_animation != "jump":
			if crouch == 1:
				mov_low.play("idle")
			elif crouch == 2:
				mov_low.play("crouched idle")
			low_body_rot.play("normal")
	if Input.is_action_pressed("jump") and is_on_floor():
		mov_low.play("jump")
		low_body_rot.play("normal")
	if mov_low.current_animation != "jump" and not is_on_floor():
		mov_low.play("falling")
		low_body_rot.play("normal")

	# movement animations for upper body
	if is_on_floor():
		if Input.is_action_pressed("forward") and not Input.is_action_pressed("right") and not Input.is_action_pressed("left") and mov_up.current_animation != "jump" and not Input.is_action_pressed("back"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("walk")
				elif crouch == 2:
					mov_up.play("crouched walking")
			elif speed == 6:
				mov_up.play("running")
				crouch = 1
			upp_body_rot.play("normal")
		elif Input.is_action_pressed("forward") and Input.is_action_pressed("right") and mov_up.current_animation != "jump" and not Input.is_action_pressed("back"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("walk")
				elif crouch == 2:
					mov_up.play("crouched walking")
			elif speed == 6:
				mov_up.play("running")
				crouch = 1
			upp_body_rot.play("right")
		elif Input.is_action_pressed("forward") and Input.is_action_pressed("left") and mov_up.current_animation != "jump" and not Input.is_action_pressed("back"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("walk")
				elif crouch == 2:
					mov_up.play("crouched walking")
			elif speed == 6:
				mov_up.play("running")
				crouch = 1
			upp_body_rot.play("left")
		elif Input.is_action_pressed("back") and not Input.is_action_pressed("right") and not Input.is_action_pressed("left") and mov_up.current_animation != "jump":
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("walking backwards")
				elif  crouch == 2:
					mov_up.play("crouched walking back")
			elif speed == 6:
				mov_up.play("running backwards")
				crouch = 1
			upp_body_rot.play("normal")
		elif Input.is_action_pressed("back") and Input.is_action_pressed("right") and mov_up.current_animation != "jump" and not Input.is_action_pressed("forward"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("walking backwards")
				elif  crouch == 2:
					mov_up.play("crouched walking back")
			elif speed == 6:
				mov_up.play("running backwards")
				crouch = 1
			upp_body_rot.play("left")
		elif Input.is_action_pressed("back") and Input.is_action_pressed("left") and mov_up.current_animation != "jump" and not Input.is_action_pressed("forward"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("walking backwards")
				elif  crouch == 2:
					mov_up.play("crouched walking back")
			elif speed == 6:
				mov_up.play("running backwards")
				crouch = 1
			upp_body_rot.play("right")
		elif Input.is_action_pressed("left") and mov_up.current_animation != "jump" and not Input.is_action_pressed("right"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("left strafe walking")
				elif crouch == 2:
					mov_up.play("crouching left")
			if speed == 6:
				mov_up.play("left strafe")
				crouch = 1
			upp_body_rot.play("normal")
		elif Input.is_action_pressed("right") and mov_up.current_animation != "jump" and not Input.is_action_pressed("left"):
			if speed == 1.75:
				if crouch == 1:
					mov_up.play("right strafe walking")
				elif  crouch == 2:
					mov_up.play("crouching right")
			if speed == 6:
				mov_up.play("right strafe")
				crouch = 1
			upp_body_rot.play("normal")
		elif mov_up.current_animation != "jump":
			if crouch == 1:
				mov_up.play("idle")
			elif crouch == 2:
				mov_up.play("crouched idle")
			upp_body_rot.play("normal")
	if Input.is_action_pressed("jump") and is_on_floor():
		mov_up.play("jump")
		upp_body_rot.play("normal")
	if mov_up.current_animation != "jump" and not is_on_floor():
		mov_up.play("falling")
		low_body_rot.play("normal")

	# head rotation
	var head = $"basic movement upper body/Armature/Skeleton3D/BoneAttachment3D/head"
	head.rotation.x = camera.rotation.x

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
	pos.x = sin(t_bob * BOB_FREQ / 2) * BOB_AMP
	return pos
