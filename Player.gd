extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var ray_cast = $RayCast2D
@onready var collision_shape = $CollisionShape2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var hand_rigidbody: RigidBody2D
var hidden_rigidbody: RigidBody2D
var hand_joint: PinJoint2D
var grapple_hook_joint: PinJoint2D

var can_control:= true

func _physics_process(delta):
	if not can_control: 
		if Input.is_action_just_pressed("ui_down"):
			velocity= hidden_rigidbody.linear_velocity
			
			grapple_hook_joint.queue_free()
			hidden_rigidbody.queue_free()
			hand_joint.queue_free()
			hand_rigidbody.queue_free()
			
			can_control= true
			return
			
		global_position= hidden_rigidbody.global_position
		return
	
	if ray_cast.is_colliding() and velocity.y <= 0:
		create_joint_and_hidden_body(ray_cast.get_collision_point(), ray_cast.get_collider())
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func create_joint_and_hidden_body(anchor: Vector2, fix_to: CollisionObject2D):
	grapple_hook_joint= PinJoint2D.new()
	fix_to.get_parent().add_child(grapple_hook_joint)
	grapple_hook_joint.global_position= anchor

	hidden_rigidbody= RigidBody2D.new()
	hidden_rigidbody.add_child(collision_shape.duplicate())
	hidden_rigidbody.top_level= true
	hidden_rigidbody.position= position
	hidden_rigidbody.collision_mask= 2
	hidden_rigidbody.lock_rotation= true
	add_child(hidden_rigidbody)

	hidden_rigidbody.linear_velocity= velocity
	
	hand_joint= PinJoint2D.new()
	hidden_rigidbody.add_child(hand_joint)
	hand_joint.global_position= global_position

	hand_rigidbody= RigidBody2D.new()
	var hand_coll_shape= CollisionShape2D.new()
	hand_coll_shape.shape= CircleShape2D.new()
	hand_coll_shape.shape.radius= 1
	hand_rigidbody.add_child(hand_coll_shape)
	hand_rigidbody.top_level= true
	hand_rigidbody.position= position
	hand_rigidbody.collision_mask= 2
	add_child(hand_rigidbody)

	hand_joint.node_a= hidden_rigidbody.get_path()
	hand_joint.node_b= hand_rigidbody.get_path()
	
	grapple_hook_joint.node_a= fix_to.get_path()
	grapple_hook_joint.node_b= hand_rigidbody.get_path()
	
	can_control= false
