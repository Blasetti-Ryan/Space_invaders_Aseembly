#####################################################################
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ryan Blasetti, 1005991198, blasett1
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 512 
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone: 4
#
# Which approved features have been implemented for milestone 4?
# 1. Increase in difficulty as game progresses 1 obstacle -> 2 obstacles -> 3 obstacles -> Boss Fight
# 2. Shoot obstacles and enemy ships (press space) -> shotting obstacles resets them and ufo can be damaged
# 3. Enemy Ship -> Boss fight ship has bouncing pattern AND shoots back
# 4. Smooth Graphics -> Only redraw neccessary parts to prevent flicker
#
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
#
# - When the ship is hit it turns red, and while red the ship gains "invinicibility frames" for
#   a short time. The ship returns to normal colour afterwards when it can receive damage again.
#
# - Only one shot can be on screen at a time to prevent the user from just spamming shots and reducing
#   difficulty of the game
#
# - Press space to shoot

#####################################################################

.eqv	BASE_ADDRESS	0x10008000	#Base address value

.data
	padding:	.space	36000   #Empty space to prevent game data from being overwritten due to large bitmap size
	all_info:	.space	208	#1-40 space ship, 40-80 fire1 80-120 ufo 120-160 meteor 164 base address 168-208 fire 2
.text

.globl main

main: 		# runs the mian program and intializes all starting values

	#Initial 2 second wait to allow user to prepare by selecting keyboard simulator 
	li $v0 32
	li $a0 2000
	syscall
	
	# store base address
	li $s0, BASE_ADDRESS
	
	# load all info
	la $s1 all_info
	
	#store base address @164
	sw $s0 164($s1)
	
	# Initialize hp to 100 for ufo and ship
	addi $s0 $zero 100
	sw $s0 20($s1)
	sw $s0 104($s1)
	
	#Store base addres
	lw $s0 164($s1)
	
	# Initialize all other values to zero
	sw $zero 28($s1)
	sw $zero 36($s1)
	sw $zero 96($s1)
	sw $zero 108($s1)
	
	# Store initial ufo direction at 32
	addi $s2 $zero -512
	sw $s2 32($s1)
	
	#store start ship spot at 0 and draw ship + UI
	addi $s0 $s0 580
	sw $s0 0($s1)
	addi $sp $sp 4
	sw $s0 0($sp)
	jal draw_ship
	jal draw_UI_start
	
	#store fire start spot at 40
	addi $s0 $s0 5520
	sw $s0 40($s1)
	
	#store fire 2 start spot at 168
	addi $s0 $s0 17888
	sw $s0 168($s1)
	
	#store meteor start spot at 120
	addi $s0 $s0 10220
	sw $s0 120($s1)
	
	#store ufo start spot at 80
	addi $s0 $s0 10236
	sw $s0 80($s1)
	
play_game: 	# Main play game loop
	j user_input
	
	
# Game Logic Section
# ===============================================

reset_wait:	# Loop for game over screen
	
	# Sit on game over screen and wait for user input
	li $s2 0xffff0000
	lw $s3 0($s2)
	beq $s3 1 key_post_game
	j reset_wait
	
key_post_game:	# Checks keypress on game over screen
	
	# Branch if users presses p
	lw $s4 4($s2)
	beq $s4 0x70 p_pressed
	j reset_wait

user_input:	# Main user input loop

	# If there is an active ship shot, move it
	lw $s5 96($s1)
	bne $s5 $zero move_shot_ship

user_input2:	# Input loop 2 that controls boss, if spawned

	#Check if the ufo has been spawned yet
	lw $s3 36($s1)
	beq $s3 $zero user_input3
	
	#Check if there is an active ufo shot, if so move it
	lw $s5 108($s1)
	bne $s5 $zero move_shot_ufo
	
	#If no active ufo shot, spawn it
	lw $s5 80($s1)
	addi $s5 $s5 1024
	sw $s5 108($s1)
	addi $sp $sp 4
	sw $s5 0($sp)
	jal shoot_ufo
	j play_game
	
user_input3:	# Input loop that controls obstacles if boss has not spawned 

	# If boss has spawned skip to boss changes
	lw $s3 36($s1)
	bne $s3 $zero load_boss2
	
	# If no boss, check if 3 obstacles have passed to spawn fire 2
	addi $s5 $zero 3
	lw $s4 28($s1)
	ble $s4 $s5 load_f1
	
	# Check if 13 obstacles have passed to spawn meteor
	addi $s5 $s5 10
	ble $s4 $s5 load_f2
	
	#Check if 38 obstacles have passed to spawn boss
	addi $s5 $s5 25
	bgt $s4 $s5 load_boss
	j load_m

load_boss:	# Initial boss load that spawns ufo and clears other obstacles

	#Store boss spawn value
	addi $t1 $zero 1
	sw $t1 36($s1)
	li $t1 0x000000 #DBrown 
	li $t2 0x000000 #Red
	li $t3 0x000000 #Orange
	li $t4 0x000000 #OrangeL
	li $t5 0x000000 #Yellowish
	li $t6 0x000000 #Black
	li $t7 0x000000 #Brown
	li $t8 0x000000 #LBrown
	li $t9 0x000000 #LLBrown

	#Clear meteor
	lw $t0 120($s1)
	jal drawing_meteor
	
	#Clear fire 2
	lw $t0 40($s1)
	jal drawing_fire2
	
	#Clear fire
	lw $t0 168($s1)
	jal drawing_fire
	
	#Draw boss health
	addi $sp $sp 4
	lw $s0 104($s1)
	sw $s0 0($sp)
	
	jal return_UI_Boss
	
load_boss2:	# Regular boss load to compute boss logic after spawn
	
	#Draw boss health
	addi $sp $sp 4
	lw $s0 104($s1)
	sw $s0 0($sp)
	
	jal colour_health_boss
	
	#Ensure ufo is still on screen (top + bottom) branch off to invalid if not
	addi $sp $sp 4
	lw $s0 80($s1)
	lw $s6 32($s1)
	add $s0 $s0 $s6
	li $s5 512
	div $s0 $s5
	mflo $s5
	li $s7 524353
	beq $s5 $s7 invalid_ufo
	li $s5 512
	div $s0 $s5
	mflo $s5
	li $s7 524447
	beq $s5 $s7 invalid_ufo
	j valid_draw

load_m:		# Move meteor

	# Get current meteor address and draw it 4 to the left
	addi $sp $sp 4
	lw $s0 120($s1)
	addi $s0 $s0 -4
	sw $s0 120($s1)
	sw $s0 0($sp)
	jal draw_meteor
	
load_f2:	# Move fire 2

	# Get current fire 2 address and draw it 4 to the left
	addi $sp $sp 4
	lw $s0 40($s1)
	addi $s0 $s0 -8
	sw $s0 40($s1)
	sw $s0 0($sp)
	jal draw_fire2
	
load_f1:	# Move fire 1

	# Get current fire address and draw it 8 to the left (double speed)
	addi $sp $sp 4
	lw $s0 168($s1)
	addi $s0 $s0 -4
	sw $s0 168($s1)
	sw $s0 0($sp)
	jal draw_fire
	j ship_stuff
	
invalid_ufo:	# Swap ufo directions if attempting to leave screen
	
	# Multiply movement by negative 1 to swap direction
	addi $s5 $zero -1
	mult $s5 $s6
	mflo $s6
	sw $s6 32($s1)
	
	# Add movement twice to prevent infinite loop to invalid
	add $s0 $s0 $s6
	add $s0 $s0 $s6
	
valid_draw:	# Set up to draw ufo if valid

	# Get ufo address on stack and draw
	sw $s0 80($s1)
	sw $s0 0($sp)
	jal draw_boss
	
ship_stuff:	# Draw ship, draw health changes and check for keypresses

	# Draw ship
	lw $s0 0($s1)
	sw $s0 0($sp)
	
	jal draw_ship
	
	# Draw ship health changes
	addi $sp $sp 4
	lw $s0 20($s1)
	sw $s0 0($sp)
	
	jal colour_health
	
	# Sleep game to prevent insta movement of all obstacles
	li $v0 32
	li $a0 25
	syscall
	
	# Detect keypress
	li $s2 0xffff0000
	lw $s3 0($s2)
	beq $s3 1 keypress_happened
	
	# Return to main loop
	j play_game
	
keypress_happened:	#Determine user keypress
	
	# Load key pressed and jump to associated method
	lw $s4 4($s2)
	beq $s4 0x61 a_pressed
	beq $s4 0x64 d_pressed
	beq $s4 0x73 s_pressed
	beq $s4 0x77 w_pressed
	beq $s4 0x70 p_pressed
	beq $s4 0x20 space_pressed
	j play_game

move_shot_ship:		# Move active ship shot

	# Move ship shot
	addi $sp $sp 4
	addi $s5 $s5 8
	
	
	# If ship shot invalid, reset it to allow new shot
	li $s3 512
	div $s5 $s3
	mfhi $s3
	li $s7 480
	beq $s3 $s7 invalid_shot
	li $s3 512
	div $s5 $s3
	mfhi $s3
	li $s7 484
	beq $s3 $s7 invalid_shot
	
	# If valid shot, draw its movement
	sw $s5 96($s1)
	sw $s5 0($sp)
	jal shoot_ship 
	j user_input2
	
move_shot_ufo:		# Move active ufo shot
	
	# Move ufo shot
	addi $sp $sp 4
	addi $s5 $s5 -8
	
	# If ufo shot invalid, reset it to shoot again
	li $s3 512
	div $s5 $s3
	mfhi $s3
	li $s7 20
	beq $s3 $s7 invalid_shot_ufo
	
	# If valid shot, draw its movement
	sw $s5 108($s1)
	sw $s5 0($sp)
	jal shoot_ufo 
	j user_input3

invalid_shot_ufo:	#Remove ufo shot from screen if invalid location
	
	# Load location of shot with black registers
	addi $s5 $s5 8
	sw $s5 108($s1)
	sw $s5 0($sp)
	li $t6 0x000000
	li $t8 0x000000
	
	# Draw over shot and reset it
	jal shoot_ufo2 
	sw $zero 108($s1)
	j user_input3
			
invalid_shot:		#Remove ship shot from screen if invalid location
	
	# Load location of shot with black registers
	addi $s5 $s5 -4
	sw $s5 96($s1)
	sw $s5 0($sp)
	li $t6 0x000000
	li $t8 0x000000
	
	# Draw over shot and reset it
	jal shoot_ship2 
	sw $zero 96($s1)
	j user_input2
#================================================

# User Input section
# ===============================================
space_pressed:		# Fire shot when space is pressed
	
	# If shot already active, don't fire new shot
	lw $s5 96($s1)
	bne $s5 $zero play_game
	
	# Set shot location in front of ship and set shot active
	lw $s5 0($s1)
	addi $s5 $s5 3652
	sw $s5 96($s1)
	addi $sp $sp 4
	sw $s5 0($sp)
	
	# Draw shot
	jal shoot_ship
	j play_game

p_pressed:		# Reset game when p is pressed
	
	# Clear screen and reset info
	jal clear_screen
	la $s2 all_info
	addi $s3 $s2 208

restart_clear:		# Loop to clear game data before reset

	# When all data is cleared, break
	beq $s2 $s3 final
	
	# Set each value in game data to 0
	sw $zero 0($s2)
	addi $s2 $s2 4
	j restart_clear
	
final:			# Reinitialize game
	
	# Load all info address and health
	la $s2 all_info
	addi $s3 $zero 100
	sw $s3 20($s2)
	
	# Restart in main
	j main
	
w_pressed:	#Move up when w is pressed (if valid)
	
	# If off screen, jump to invalid draw
	li $s5 512
	lw $s0 0($s1)
	div $s0 $s5
	mflo $s5
	li $s7 524353
	beq $s5 $s7 invalid_draw
	
	# Paint only pixels below ship to black
	li $s6, 0x000000
	sw $s6, 3584($s0)
	sw $s6, 4100($s0)
	sw $s6, 4616($s0)
	sw $s6, 5132($s0)
	sw $s6, 5648($s0)
	sw $s6, 7188($s0)
	sw $s6, 6680($s0)
	sw $s6, 6172($s0)
	sw $s6, 5664($s0)
	sw $s6, 5156($s0)
	sw $s6, 4648($s0)
	sw $s6, 4652($s0)
	sw $s6, 4656($s0)
	sw $s6, 4660($s0)
	sw $s6, 4152($s0)
	sw $s6, 4156($s0)
	sw $s6, 3648($s0)	
	
	# Draw the ship 1 unit up
	addi $s0 $s0 -512 
	addi $sp $sp 4
	sw $s0 0($s1)
	sw $s0 0($sp)
	
	jal draw_ship
	
	# Return to game loop
	j play_game
	
s_pressed:	#Move down when s is pressed (if valid)
	
	# If off screen, jump to invalid draw
	li $s5 512
	lw $s0 0($s1)
	div $s0 $s5
	mflo $s5
	li $s7 524447
	beq $s5 $s7 invalid_draw
	
	# Paint only pixels above ship to black
	li $s6, 0x000000
	sw $s6, 3584($s0)
	sw $s6, 3076($s0)
	sw $s6, 2568($s0)
	sw $s6, 2060($s0)
	sw $s6, 1552($s0)
	sw $s6, 20($s0)
	sw $s6, 536($s0)
	sw $s6, 2084($s0)
	sw $s6, 1568($s0)
	sw $s6, 1052($s0)
	sw $s6, 2600($s0)
	sw $s6, 2604($s0)
	sw $s6, 2608($s0)
	sw $s6, 2612($s0)
	sw $s6, 3128($s0)
	sw $s6, 3132($s0)
	sw $s6, 3648($s0)
	
	#Draw ship 1 unit down
	addi $s0 $s0 512 
	addi $sp $sp 4
	sw $s0 0($s1)
	sw $s0 0($sp)
	
	jal draw_ship
	
	# Return to main game loop
	j play_game
	
d_pressed:	#Move right when d is pressed (if valid)
	
	# If off screen, jump to invalid draw
	li $s5 512
	lw $s0 0($s1)
	div $s0 $s5
	mfhi $s5
	li $s7 444
	beq $s5 $s7 invalid_draw
	
	# Paint only pixels left of ship to black
	li $s6, 0x000000
	sw $s6, 3584($s0)
	sw $s6, 3076($s0)
	sw $s6, 2568($s0)
	sw $s6, 2060($s0)
	sw $s6, 1552($s0)
	sw $s6, 1044($s0)
	sw $s6, 532($s0)
	sw $s6, 20($s0)
	sw $s6, 4100($s0)
	sw $s6, 4616($s0)
	sw $s6, 5132($s0)
	sw $s6, 5648($s0)
	sw $s6, 6164($s0)
	sw $s6, 6676($s0)
	sw $s6, 7188($s0)
	
	# Draw ship 1 unit right
	addi $s0 $s0 4 
	addi $sp $sp 4
	sw $s0 0($s1)
	sw $s0 0($sp)
	
	jal draw_ship
	
	# Return to main game loop
	j play_game

a_pressed:	#Move left when a is pressed (if valid)
	
	# If off screen, jump to invalid draw
	li $s5 512
	lw $s0 0($s1)
	div $s0 $s5
	mfhi $s5
	beq $s5 $zero invalid_draw
	
	# Paint only pixels right of ship to black
	li $s6, 0x000000
	sw $s6, 3648($s0)
	sw $s6, 3132($s0)
	sw $s6, 2612($s0)
	sw $s6, 2084($s0)
	sw $s6, 1568($s0)
	sw $s6, 1052($s0)
	sw $s6, 536($s0)
	sw $s6, 20($s0)
	sw $s6, 4156($s0)
	sw $s6, 4660($s0)
	sw $s6, 5156($s0)
	sw $s6, 5664($s0)
	sw $s6, 6172($s0)
	sw $s6, 6680($s0)
	sw $s6, 7188($s0)
	
	# Draw ship 1 unit left
	addi $s0 $s0 -4 
	addi $sp $sp 4
	sw $s0 0($s1)
	sw $s0 0($sp)
	
	jal draw_ship
	
	# Return to main game loop
	j play_game

invalid_draw:	# Do nothing when movement of ship is invalid and return to game loop
	j play_game
	
# ================================================
	
# Drawing Section
# ================================================
game_over:	#Draw game over screen (drawn by rows)

	# Wait for 0.1 seconds before clearing screen	
	li $v0 32
	li $a0 100
	syscall
	jal clear_screen
	
	# Top left pixel game over (row 1)
	addi $sp $sp 4
	lw $s2 164($s1)
	addi $s2 $s2 8852 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block	
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 40 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 40
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 48
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 2 starts
	addi $sp $sp 4
	addi $s2 $s2 1296 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 64
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 24 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 3 starts
	addi $sp $sp 4
	addi $s2 $s2 1332 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 24 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 24 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 24 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 4 starts
	addi $sp $sp 4
	addi $s2 $s2 1308 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 48
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 5 starts
	addi $sp $sp 4
	addi $s2 $s2 1344 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block	
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block	
	
	addi $sp $sp 4
	addi $s2 $s2 48 
	sw $s2 0($sp)
	jal three_x_block	
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block	
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block	
	
	# Row 6 starts
	addi $sp $sp 4
	addi $s2 $s2 3356
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 40 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 48 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 7 starts
	addi $sp $sp 4
	addi $s2 $s2 1308 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 48 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 64 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 8 starts
	addi $sp $sp 4
	addi $s2 $s2 1296 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 48 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 40
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 9 starts
	addi $sp $sp 4
	addi $s2 $s2 1296 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 40 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 24 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 40 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 64 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 24 
	sw $s2 0($sp)
	jal three_x_block
	
	# Row 10 starts
	addi $sp $sp 4
	addi $s2 $s2 1320 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 64 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 52 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 12 
	sw $s2 0($sp)
	jal three_x_block
	
	addi $sp $sp 4
	addi $s2 $s2 28 
	sw $s2 0($sp)
	jal three_x_block
	
	# Bottom right pixel of game over
	addi $sp $sp 4
	addi $s2 $s2 36 
	sw $s2 0($sp)
	jal three_x_block
	
	# Jump to wait for user to reset
	j reset_wait
	
three_x_block:		#Draw a 3x3 block for game over screen
	
	# Load colour white and pop from stack
	li $t1, 0xFFFFFF
	lw $t0 0($sp)
	addi $sp $sp -4
	
	#Draw top row
	sw $t1 0($t0)
	sw $t1 4($t0)
	sw $t1 8($t0)
	
	#Draw middle row
	sw $t1 512($t0)
	sw $t1 516($t0)
	sw $t1 520($t0)
	
	#Draw bottom row
	sw $t1 1024($t0)
	sw $t1 1028($t0)
	sw $t1 1032($t0)
	
	# Return to call point
	jr $ra

clear_screen:		# Clear the screen loop[ setup
	
	# Save return address
	move $s6 $ra
	
	# Load black and base address
	lw $s2 164($s1)
	addi $s3 $s2 65800
	li $t1, 0x000000
	
clear:			#Clear screen loop
	
	#while screen not completely clear keep setting pixels to black
	beq $s2 $s3 ret_clear
	sw $t1 0($s2)
	addi $s2 $s2 4
	j clear

ret_clear:		# Return from clear loop to caller	
	jr $s6

damage_colour:		# Draw ship red from taking damage
	
	# Load ship colour registers to red
	li $t1, 0xD50000
	li $t2, 0xD50000
	li $t3, 0xD50000
	li $t4, 0xD50000
	li $t5, 0xD50000
	li $t6, 0xD50000
	li $t7  0xD50000
	li $t8  0xD50000
	li $t9  0xD50000
	
	# Jump to skip colour past colour load
	addi $a1 $a1 -1
	sw $a1 16($s1)
	j drawing_ship

shoot_ship:		#Load colours for ship shot
	li $t6 0x000000  #White
	li $t8 0xFFFFFE  #Black
	
shoot_ship2:		#Draw ship shot (drawn by rows) and colours black behind it
	
	#Load address from stack
	lw $t0 0($sp)
	addi $sp $sp -4
	
	#Top row
	sw $t6, -4($t0)
	sw $t6, 0($t0)
	sw $t8, 4($t0)
	sw $t8, 8($t0)
	sw $t8, 12($t0)
	
	#Mid row
	sw $t6, 508($t0)
	sw $t6, 512($t0)
	sw $t8, 516($t0)
	sw $t8, 520($t0)
	sw $t8, 524($t0)
	
	#Bottom row
	sw $t6, 1020($t0)
	sw $t6, 1024($t0)
	sw $t8, 1028($t0)
	sw $t8, 1032($t0)
	sw $t8, 1036($t0)
	jr $ra
	
damage_ship:		#Determine if ufo shot hits ship
	
	#Set invincibility frames
	addi $a1 $zero 30
	sw $a1 16($s1)
	
	#Reduce health by 25
	lw $a1 20($s1)
	addi $a1 $a1 -25
	
	# Reset shot
	sw $a1 20($s1)
	j invalid_shot_ufo
	
shoot_ufo:		#Load colour for ufo shot
	li $t6 0x000000 #Black
	li $t8 0xE91E62 #Pink
	
shoot_ufo2:		#Draw ufo shot (drawn by rows) and colours black behind it
	
	# Load address form stack
	lw $t0 0($sp)
	addi $sp $sp -4
	
	#Load ship colours
	li $a1 0x37474F
	li $a2 0x546E7A
	
	# Check if ship colour matches top row of shot to signal hit
	lw $a3 -4($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	lw $a3 0($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	lw $a3 4($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	# Check if ship colour matches mid row of shot to signal hit
	lw $a3 508($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	lw $a3 516($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	# Check if ship colour matches bottom row of shot to signal hit
	lw $a3 1020($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	lw $a3 1028($t0)
	beq $a3 $a1 damage_ship
	beq $a3 $a2 damage_ship
	
	#Draw top row of shot
	sw $t8, -4($t0)
	sw $t8, 0($t0)
	sw $t8, 4($t0)
	sw $t6, 8($t0)
	sw $t6, 12($t0)
	
	#Draw mid row of shot
	sw $t8, 508($t0)
	sw $t8, 512($t0)
	sw $t8, 516($t0)
	sw $t6, 520($t0)
	sw $t6, 524($t0)
	
	#Draw bottom row of shot
	sw $t8, 1020($t0)
	sw $t8, 1024($t0)
	sw $t8, 1028($t0)
	sw $t6, 1032($t0)
	sw $t6, 1036($t0)
	
	#Return to caller
	jr $ra

draw_ship:	#Load colours for ship drawing
	
	#Load address from stack
	lw $t0 0($sp)
	addi $sp $sp -4
	
	# If hit load red 
	lw $a1 16($s1)
	bgt $a1 $zero damage_colour
	
	#Otherwise load normal colours
	li $t1, 0xD50000
	li $t2, 0xE64919
	li $t3, 0xF4501E
	li $t4, 0x37474F
	li $t5, 0xB0BEC5
	li $t6, 0x00BBD4
	li $t7  0x2195F3
	li $t8  0x546E7A
	li $t9  0xFFFFFF
	
drawing_ship:	#Draw the ship (by rows)
	
	# Back Of Flame far back
	sw $t1, 3584($t0)
	sw $t1, 3588($t0)
	sw $t2, 3592($t0)
	sw $t2, 3596($t0)
	sw $t3, 3600($t0)
	sw $t4, 3604($t0)
	sw $t4, 3608($t0)
	sw $t4, 3612($t0)
	sw $t5, 3616($t0)
	sw $t5, 3620($t0)
	sw $t5, 3624($t0)
	sw $t5, 3628($t0)
	sw $t7, 3632($t0)
	sw $t6, 3636($t0)
	sw $t5, 3640($t0)
	sw $t5, 3644($t0)
	sw $t8, 3648($t0)
	
	# Row above flame
	sw $t1, 3076($t0) 
	sw $t1, 3080($t0)
	sw $t2, 3084($t0)
	sw $t3, 3088($t0)
	sw $t3, 3092($t0)
	sw $t3, 3096($t0)
	sw $t5, 3100($t0)
	sw $t5, 3104($t0)
	sw $t5, 3108($t0)
	sw $t5, 3112($t0)
	sw $t5, 3116($t0)
	sw $t6, 3120($t0)
	sw $t5, 3124($t0)
	sw $t8, 3128($t0)
	sw $t8, 3132($t0)
	
	#Row above flame 2
	sw $t1  2568($t0)
	sw $t1  2572($t0)
	sw $t2, 2576($t0)
	sw $t3, 2580($t0)
	sw $t9, 2584($t0)
	sw $t5, 2588($t0)
	sw $t5, 2592($t0)
	sw $t5, 2596($t0)
	sw $t8, 2600($t0)
	sw $t8, 2604($t0)
	sw $t8, 2608($t0)
	sw $t8, 2612($t0)
	
	#Row above flame 3
	sw $t1  2060($t0)
	sw $t2, 2064($t0)
	sw $t9, 2068($t0)
	sw $t8, 2072($t0)
	sw $t8, 2076($t0)
	sw $t8, 2080($t0)
	sw $t8, 2084($t0)
	
	#Row above flame 4
	sw $t1  1552($t0)
	sw $t8, 1556($t0)
	sw $t4, 1560($t0)
	sw $t4, 1564($t0)
	sw $t4, 1568($t0)
	
	#Row above flame 5
	sw $t4, 1044($t0)
	sw $t4, 1048($t0)
	sw $t4, 1052($t0)
	
	#Row above flame 6
	sw $t4, 532($t0)
	sw $t4, 536($t0)
	
	#Row above flame 7
	sw $t4, 20($t0)
	
	#Row below flame
	sw $t1, 4100($t0) 
	sw $t1, 4104($t0)
	sw $t2, 4108($t0)
	sw $t3, 4112($t0)
	sw $t3, 4116($t0)
	sw $t3, 4120($t0)
	sw $t5, 4124($t0)
	sw $t5, 4128($t0)
	sw $t5, 4132($t0)
	sw $t5, 4136($t0)
	sw $t5, 4140($t0)
	sw $t6, 4144($t0)
	sw $t5, 4148($t0)
	sw $t8, 4152($t0)
	sw $t8, 4156($t0)
	
	#Row below flame 2
	sw $t1  4616($t0)
	sw $t1  4620($t0)
	sw $t2, 4624($t0)
	sw $t3, 4628($t0)
	sw $t9, 4632($t0)
	sw $t5, 4636($t0)
	sw $t5, 4640($t0)
	sw $t5, 4644($t0)
	sw $t8, 4648($t0)
	sw $t8, 4652($t0)
	sw $t8, 4656($t0)
	sw $t8, 4660($t0)
	
	#Row below flame 3
	sw $t1  5132($t0)
	sw $t2, 5136($t0)
	sw $t9, 5140($t0)
	sw $t8, 5144($t0)
	sw $t8, 5148($t0)
	sw $t8, 5152($t0)
	sw $t8, 5156($t0)
	
	#Row below flame 4
	sw $t1  5648($t0)
	sw $t8, 5652($t0)
	sw $t4, 5656($t0)
	sw $t4, 5660($t0)
	sw $t4, 5664($t0)
	
	#Row below flame 5
	sw $t4, 6164($t0)
	sw $t4, 6168($t0)
	sw $t4, 6172($t0)
	
	#Row below flame 6
	sw $t4, 6676($t0)
	sw $t4, 6680($t0)
	
	#Row below flame 7
	sw $t4, 7188($t0)
	
	#Return to caller
	jr $ra
	
draw_UI_start:		# Set up for loop to draw bottom UI
	
	# Set UI colours
	lw $t0  0($s1)
	li $t8  0x546E7A
        li $t9  0xFFFFFF
        
        #Set ui addresses to colour
	addi $t1 $t0 55740
	addi $t2 $t0 65000
	
draw_UI_Loop:		# Loop to draw ui in grey at bottom
	
	# If end is reached break otherwise continue to colour ui
	beq $t1 $t2 return_UI
	sw $t8 0($t1)
	addi $t1 $t1 4
	j draw_UI_Loop
	
return_UI:		# Draw hp letters (by column)
	
	# First columbn H
	sw $t9 58824($t0)
	sw $t9 59336($t0)
	sw $t9 59848($t0)
	sw $t9 60360($t0)
	sw $t9 60872($t0)
	sw $t9 61384($t0)
	sw $t9 61896($t0)
	
	#Second column H
	sw $t9 60364($t0)
	sw $t9 60368($t0)
	
	# Thiird column H
	sw $t9 58836($t0)
	sw $t9 59348($t0)
	sw $t9 59860($t0)
	sw $t9 60372($t0)
	sw $t9 60884($t0)
	sw $t9 61396($t0)
	sw $t9 61908($t0)
	
	#First column P
	sw $t9 58848($t0)
	sw $t9 59360($t0)
	sw $t9 59872($t0)
	sw $t9 60384($t0)
	sw $t9 60896($t0)
	sw $t9 61408($t0)
	sw $t9 61920($t0)
	
	#Second column P
	sw $t9 58852($t0)
	sw $t9 58856($t0)
	sw $t9 58860($t0)
	
	#Third column P
	sw $t9 59372($t0)
	sw $t9 59884($t0)
	sw $t9 60396($t0)
	
	#Fourth column P
	sw $t9 60392($t0)
	sw $t9 60388($t0)
	
	#Colon column
	sw $t9 59384($t0)
	sw $t9 61432($t0)
	
	# Setup to draw health at 100
	addi $sp $sp 4
	addi $t7 $zero 100
	sw $t7 0($sp)

colour_health:	# Setup for loop top draw health bar
	
	# Load green 
	li $t9 0x7AFA5A
	
	#Load address for end of health from stack
	lw $t2 0($sp)
	addi $sp $sp -4
	div $t2 $t2 4
	addi $t4 $zero 0
	
	#Load end address
	li $t3 25
	lw $t5 164($s1)
	addi $t5 $t5 60500
	
colour_green:	# Loop to draw health in green (3 width)
	
	#While health is not at end, draw 3 pixels down
	bge $t4 $t2 checker
	sw $t9 0($t5)
	sw $t9 512($t5)
	sw $t9 1024($t5)
	addi $t5 $t5 4
	addi $t4 $t4 1
	j colour_green
	
checker:	# If health is negative, set it to 0
	bgez $t2 colour_red
	add $t2 $zero $zero
	
colour_red:	# Colour missing health (3 width)
	
	# Load colour red
	li $t9 0xD50000
	
	#While colour does not fil health bar, draw red
	bge $t2 $t3 return_health
	sw $t9 0($t5)
	sw $t9 512($t5)
	sw $t9 1024($t5)
	addi $t5 $t5 4
	addi $t2 $t2 1
	j colour_red
	
return_health:	# When health is less than 0, set game over
	lw $t2 20($s1)
	blez $t2 game_over
	jr $ra
	
damage_meteor:	#Calculate metor hit
	
	# Set invincibility frames
	addi $a1 $zero 25
	sw $a1 16($s1)
	lw $a1 20($s1)
	
	#Reduce health by 20
	addi $a1 $a1 -20
	sw $a1 20($s1)
	
	#Reset meteor
	j randomize_meteor

damage_fire:	# Calculate fire hit
	
	# Set invincibility frames
	addi $a1 $zero 25
	sw $a1 16($s1)
	lw $a1 20($s1)
	
	#Reduce health by 15
	addi $a1 $a1 -15
	sw $a1 20($s1)
	
	#Randomize fire
	j randomize_fire1	
	
damage_fire2:	#Calculate fire 2 hit

	# Set invincibility frames
	addi $a1 $zero 25
	sw $a1 16($s1)
	lw $a1 20($s1)
	
	#Reduce health by 10
	addi $a1 $a1 -10
	sw $a1 20($s1)
	
	#Randomize fire 2
	j randomize_fire2
	
damage_boss:	# Calculate damage from ufo collision
	
	# Set invincibility frames
	addi $a1 $zero 25
	sw $a1 16($s1)
	lw $a1 20($s1)
	
	# Reduce health by 5
	addi $a1 $a1 -5
	sw $a1 20($s1)
	
	# Draw boss
	j drawing_boss

draw_meteor:	# Determine meteor collision before draw 
	lw $t0 0($sp)
	addi $sp $sp -4
	
	#Load ship and shot colours
	li $a1 0x37474F
	li $a2 0x546E7A
	li $v1 0xFFFFFE
	
	#If top row hit ship, do damage. if shot hits, reset
	lw $a3 8($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 20($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 32($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 44($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 52($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	#If third row hit ship, do damage. if shot hits, reset
	lw $a3 1024($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 1604($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	#If fifth row hit ship, do damage. if shot hits, reset
	lw $a3 2048($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 3140($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	#If bottom row hit ship, do damage. if shot hits, reset
	lw $a3 4104($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 4116($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 4128($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 4140($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	lw $a3 4152($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	#If sides hit ship, do damage. if shot hits, reset
	lw $a3 3592($t0)
	beq $a3 $a1 damage_meteor
	beq $a3 $a2 damage_meteor
	beq $a3 $v1 randomize_meteor_hit
	
	# If going off screen, reset meteor
	li $t7 512
	div $t0 $t7
	mfhi $t7
	beq $t7 $zero before_rand_m

colour_met_set:		#Set meteor colours for drawing
	li $t1 0x3E2723 #DBrown 
	li $t2 0xDD2C00 #Red
	li $t3 0xF4501E #Orange
	li $t4 0xFF9900 #OrangeL
	li $t5 0xFFAC40 #Yellowish
	li $t6 0x000000 #Black
	li $t7 0x5D4037 #Brown
	li $t8 0x795548 #LBrown
	li $t9 0x8D6E63 #LLBrown

drawing_meteor:		#Draw meteor (drawn by rows) with black behind it
	
	#Draw top row
	sw $t1 8($t0)
	sw $t1 12($t0)
	sw $t1 16($t0)
	sw $t1 20($t0)
	sw $t1 24($t0)
	sw $t1 28($t0)
	sw $t3 32($t0)
	sw $t3 36($t0)
	sw $t3 40($t0)
	sw $t3 44($t0)
	sw $t2 48($t0)
	sw $t2 52($t0)
	sw $t2 56($t0)
	sw $t6 60($t0)
	
	#Draw row 2
	sw $t1 516($t0)
	sw $t7 520($t0)
	sw $t7 524($t0)
	sw $t9 528($t0)
	sw $t8 532($t0)
	sw $t7 536($t0)
	sw $t7 540($t0)
	sw $t1 544($t0)
	sw $t4 548($t0)
	sw $t4 552($t0)
	sw $t4 556($t0)
	sw $t4 560($t0)
	sw $t2 564($t0)
	sw $t2 568($t0)
	sw $t2 572($t0)
	sw $t6 576($t0)
	
	#Draw row 3
	sw $t1 1024($t0)
	sw $t7 1028($t0)
	sw $t7 1032($t0)
	sw $t7 1036($t0)
	sw $t8 1040($t0)
	sw $t8 1044($t0)
	sw $t7 1048($t0)
	sw $t7 1052($t0)
	sw $t7 1056($t0)
	sw $t1 1060($t0)
	sw $t2 1064($t0)
	sw $t2 1068($t0)
	sw $t2 1072($t0)
	sw $t2 1076($t0)
	sw $t2 1080($t0)
	sw $t3 1084($t0)
	sw $t2 1088($t0)
	sw $t6 1092($t0)
	
	#Draw row 4
	sw $t1 1536($t0)
	sw $t7 1540($t0)
	sw $t8 1544($t0)
	sw $t7 1548($t0)
	sw $t7 1552($t0)
	sw $t7 1556($t0)
	sw $t7 1560($t0)
	sw $t7 1564($t0)
	sw $t7 1568($t0)
	sw $t1 1572($t0)
	sw $t4 1576($t0)
	sw $t5 1580($t0)
	sw $t5 1584($t0)
	sw $t5 1588($t0)
	sw $t2 1592($t0)
	sw $t2 1596($t0)
	sw $t3 1600($t0)
	sw $t2 1604($t0)
	sw $t6 1608($t0)
	
	#Draw row 5
	sw $t1 2048($t0)
	sw $t7 2052($t0)
	sw $t8 2056($t0)
	sw $t9 2060($t0)
	sw $t7 2064($t0)
	sw $t7 2068($t0)
	sw $t7 2072($t0)
	sw $t8 2076($t0)
	sw $t8 2080($t0)
	sw $t1 2084($t0)
	sw $t2 2088($t0)
	sw $t2 2092($t0)
	sw $t2 2096($t0)
	sw $t2 2100($t0)
	sw $t2 2104($t0)
	sw $t5 2108($t0)
	sw $t5 2112($t0)
	sw $t2 2116($t0)
	sw $t2 2120($t0)
	sw $t6 2124($t0)
	
	#Draw row 6
	sw $t1 2560($t0)
	sw $t7 2564($t0)
	sw $t9 2568($t0)
	sw $t8 2572($t0)
	sw $t7 2576($t0)
	sw $t7 2580($t0)
	sw $t7 2584($t0)
	sw $t8 2588($t0)
	sw $t9 2592($t0)
	sw $t1 2596($t0)
	sw $t3 2600($t0)
	sw $t3 2604($t0)
	sw $t3 2608($t0)
	sw $t5 2612($t0)
	sw $t5 2616($t0)
	sw $t2 2620($t0)
	sw $t2 2624($t0)
	sw $t2 2628($t0)
	sw $t6 2632($t0)
	
	#Draw row 7
	sw $t1 3072($t0)
	sw $t7 3076($t0)
	sw $t7 3080($t0)
	sw $t8 3084($t0)
	sw $t7 3088($t0)
	sw $t7 3092($t0)
	sw $t9 3096($t0)
	sw $t7 3100($t0)
	sw $t9 3104($t0)
	sw $t1 3108($t0)
	sw $t2 3112($t0)
	sw $t5 3116($t0)
	sw $t2 3120($t0)
	sw $t2 3124($t0)
	sw $t2 3128($t0)
	sw $t2 3132($t0)
	sw $t2 3136($t0)
	sw $t6 3140($t0)
	
	#Draw row 8
	sw $t1 3588($t0)
	sw $t7 3592($t0)
	sw $t7 3596($t0)
	sw $t7 3600($t0)
	sw $t9 3604($t0)
	sw $t8 3608($t0)
	sw $t7 3612($t0)
	sw $t1 3616($t0)
	sw $t4 3620($t0)
	sw $t3 3624($t0)
	sw $t3 3628($t0)
	sw $t3 3632($t0)
	sw $t4 3636($t0)
	sw $t2 3640($t0)
	sw $t2 3644($t0)
	sw $t6 3648($t0)
	
	#Draw row 9
	sw $t1 4104($t0)
	sw $t1 4108($t0)
	sw $t1 4112($t0)
	sw $t1 4116($t0)
	sw $t1 4120($t0)
	sw $t1 4124($t0)
	sw $t5 4128($t0)
	sw $t2 4132($t0)
	sw $t2 4136($t0)
	sw $t3 4140($t0)
	sw $t3 4144($t0)
	sw $t2 4148($t0)
	sw $t2 4152($t0)
	sw $t6 4156($t0)
	
	#Return to caller
	jr $ra

randomize_meteor_hit:		#Randomize meteor when hit by ship shot
	
	# Add count of obstacles that passed
	lw $t6 28($s1)
	addi $t6 $t6 1
	sw $t6 28($s1)
	addi $sp $sp 4
	lw $t7 96($s1)
	sw $t7 0($sp)
	
	# Clear shot form screen
	li $t6 0x000000
	li $t8 0x000000
	jal shoot_ship2 
	
	#Reset shot and randomize meteor
	sw $zero 96($s1)
	lw $t0 120($s1)
	jal randomize_meteor
	j play_game

before_rand_m:			# Count obstacle as passed before resetting		
	lw $t6 28($s1)
	addi $t6 $t6 1
	sw $t6 28($s1)	

randomize_meteor:		# Randomize meteor start spot in reset
	
	# PIck a number 1-100
	li $v0 42
	li $a0 1
	li $a1 100
	syscall
	
	li $t6 0x000000 #Black
	
	#Clear top row meteor
	sw $t6 8($t0)
	sw $t6 12($t0)
	sw $t6 16($t0)
	sw $t6 20($t0)
	sw $t6 24($t0)
	sw $t6 28($t0)
	sw $t6 32($t0)
	sw $t6 36($t0)
	sw $t6 40($t0)
	sw $t6 44($t0)
	sw $t6 48($t0)
	sw $t6 52($t0)
	sw $t6 56($t0)
	sw $t6 60($t0)
	
	#Clear row 2 meteor
	sw $t6 516($t0)
	sw $t6 520($t0)
	sw $t6 524($t0)
	sw $t6 528($t0)
	sw $t6 532($t0)
	sw $t6 536($t0)
	sw $t6 540($t0)
	sw $t6 544($t0)
	sw $t6 548($t0)
	sw $t6 552($t0)
	sw $t6 556($t0)
	sw $t6 560($t0)
	sw $t6 564($t0)
	sw $t6 568($t0)
	sw $t6 572($t0)
	sw $t6 576($t0)
	
	#Clear row 3 meteor
	sw $t6 1024($t0)
	sw $t6 1028($t0)
	sw $t6 1032($t0)
	sw $t6 1036($t0)
	sw $t6 1040($t0)
	sw $t6 1044($t0)
	sw $t6 1048($t0)
	sw $t6 1052($t0)
	sw $t6 1056($t0)
	sw $t6 1060($t0)
	sw $t6 1064($t0)
	sw $t6 1068($t0)
	sw $t6 1072($t0)
	sw $t6 1076($t0)
	sw $t6 1080($t0)
	sw $t6 1084($t0)
	sw $t6 1088($t0)
	sw $t6 1092($t0)
	
	#Clear row 4 meteor
	sw $t6 1536($t0)
	sw $t6 1540($t0)
	sw $t6 1544($t0)
	sw $t6 1548($t0)
	sw $t6 1552($t0)
	sw $t6 1556($t0)
	sw $t6 1560($t0)
	sw $t6 1564($t0)
	sw $t6 1568($t0)
	sw $t6 1572($t0)
	sw $t6 1576($t0)
	sw $t6 1580($t0)
	sw $t6 1584($t0)
	sw $t6 1588($t0)
	sw $t6 1592($t0)
	sw $t6 1596($t0)
	sw $t6 1600($t0)
	sw $t6 1604($t0)
	sw $t6 1608($t0)
	
	#Clear row 5 meteor
	sw $t6 2048($t0)
	sw $t6 2052($t0)
	sw $t6 2056($t0)
	sw $t6 2060($t0)
	sw $t6 2064($t0)
	sw $t6 2068($t0)
	sw $t6 2072($t0)
	sw $t6 2076($t0)
	sw $t6 2080($t0)
	sw $t6 2084($t0)
	sw $t6 2088($t0)
	sw $t6 2092($t0)
	sw $t6 2096($t0)
	sw $t6 2100($t0)
	sw $t6 2104($t0)
	sw $t6 2108($t0)
	sw $t6 2112($t0)
	sw $t6 2116($t0)
	sw $t6 2120($t0)
	sw $t6 2124($t0)
	
	
	#Clear row 6 meteor
	sw $t6 2560($t0)
	sw $t6 2564($t0)
	sw $t6 2568($t0)
	sw $t6 2572($t0)
	sw $t6 2576($t0)
	sw $t6 2580($t0)
	sw $t6 2584($t0)
	sw $t6 2588($t0)
	sw $t6 2592($t0)
	sw $t6 2596($t0)
	sw $t6 2600($t0)
	sw $t6 2604($t0)
	sw $t6 2608($t0)
	sw $t6 2612($t0)
	sw $t6 2616($t0)
	sw $t6 2620($t0)
	sw $t6 2624($t0)
	sw $t6 2628($t0)
	sw $t6 2632($t0)
	
	#Clear row 7 meteor
	sw $t6 3072($t0)
	sw $t6 3076($t0)
	sw $t6 3080($t0)
	sw $t6 3084($t0)
	sw $t6 3088($t0)
	sw $t6 3092($t0)
	sw $t6 3096($t0)
	sw $t6 3100($t0)
	sw $t6 3104($t0)
	sw $t6 3108($t0)
	sw $t6 3112($t0)
	sw $t6 3116($t0)
	sw $t6 3120($t0)
	sw $t6 3124($t0)
	sw $t6 3128($t0)
	sw $t6 3132($t0)
	sw $t6 3136($t0)
	sw $t6 3140($t0)
	
	#Clear row 8 meteor
	sw $t6 3588($t0)
	sw $t6 3592($t0)
	sw $t6 3596($t0)
	sw $t6 3600($t0)
	sw $t6 3604($t0)
	sw $t6 3608($t0)
	sw $t6 3612($t0)
	sw $t6 3616($t0)
	sw $t6 3620($t0)
	sw $t6 3624($t0)
	sw $t6 3628($t0)
	sw $t6 3632($t0)
	sw $t6 3636($t0)
	sw $t6 3640($t0)
	sw $t6 3644($t0)
	sw $t6 3648($t0)
	
	#Clear row 9 meteor
	sw $t6 4104($t0)
	sw $t6 4108($t0)
	sw $t6 4112($t0)
	sw $t6 4116($t0)
	sw $t6 4120($t0)
	sw $t6 4124($t0)
	sw $t6 4128($t0)
	sw $t6 4132($t0)
	sw $t6 4136($t0)
	sw $t6 4140($t0)
	sw $t6 4144($t0)
	sw $t6 4148($t0)
	sw $t6 4152($t0)
	sw $t6 4156($t0)
	
	#Use random number to select new spawn start
	li $t7 128
	mult $a0 $t7
	li $t7 4
	mflo $a0
	mult $a0 $t7
	mflo $t0
	addi $t0 $t0 432
	lw $t7 164($s1)
	add $t0 $t0 $t7
	sw $t0 120($s1)
	
	# Load colours for meteor and draw it
	li $t1 0x3E2723 #DBrown 
	li $t2 0xDD2C00 #Red
	li $t3 0xF4501E #Orange
	li $t4 0xFF9900 #OrangeL
	li $t5 0xFFAC40 #Yellowish
	li $t6 0x000000 #Black
	li $t7 0x5D4037 #Brown
	li $t8 0x795548 #LBrown
	li $t9 0x8D6E63 #LLBrown
	j drawing_meteor
	
	
draw_fire:		# Determine fire collision before draw 
	
	#Load fire colours
	li $t2 0x03A8F4 #Blue
	li $t3 0x00BBD4 #Orange
	li $t4 0x90CAF9 #OrangeL
	li $t5 0x80DEEA #Yellow
	li $t6 0x000000
	lw $t0 0($sp)
	addi $sp $sp -4
	
	
	#Load ship colours and shot colour
	li $a1 0x37474F
	li $a2 0x546E7A
	li $v1 0xFFFFFE
	
	# If top of fire hits ship do damage, if shot hits reset
	lw $a3 3072($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	lw $a3 4096($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	# If higher side of fire hits ship do damage, if shot hits reset
	lw $a3 1036($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	lw $a3 1048($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	lw $a3 2064($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	lw $a3 2056($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	# If bottom of fire hits shhip do damage, if shot hits reset
	lw $a3 3604($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	lw $a3 2580($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	lw $a3 4616($t0)
	beq $a3 $a1 damage_fire
	beq $a3 $a2 damage_fire
	beq $a3 $v1 randomize_f1_hit
	
	# If fire is about to go off screen randomize and reset
	li $t7 512
	div $t0 $t7
	mfhi $t7
	beq $t7 $zero before_rand_f1

drawing_fire:		#Draw fire (drawn by row) and black behind
	
	# Draw fire row 7
	sw $t2 3072($t0)
	sw $t3 3076($t0)
	sw $t3 3080($t0)
	sw $t4 3084($t0)
	sw $t3 3088($t0)
	sw $t2 3092($t0)
	sw $t6 3096($t0)
	
	#Draw fire row 8
	sw $t2 3584($t0)
	sw $t3 3588($t0)
	sw $t5 3592($t0)
	sw $t5 3596($t0)
	sw $t3 3600($t0)
	sw $t2 3604($t0)
	sw $t6 3608($t0)
	
	#Draw fire row 9
	sw $t2 4096($t0)
	sw $t4 4100($t0)
	sw $t5 4104($t0)
	sw $t3 4108($t0)
	sw $t2 4112($t0)
	sw $t6 4116($t0)
	
	#Draw fire row 10
	sw $t2 4612($t0)
	sw $t3 4616($t0)
	sw $t2 4620($t0)
	sw $t6 4624($t0)
	
	#Draw fire top row
	sw $t2 8($t0)
	sw $t6 12($t0)

	#Draw fire row 2
	sw $t2 516($t0)
	sw $t6 520($t0)

	#Draw fire row 3
	sw $t2 1036($t0)
	sw $t6 1040($t0)
	sw $t2 1048($t0)
	sw $t6 1052($t0)

	#Draw fire row 4
	sw $t2 1548($t0)
	sw $t2 1552($t0)
	sw $t6 1556($t0)

	#Draw fire row 5
	sw $t2 2056($t0)
	sw $t3 2060($t0)
	sw $t2 2064($t0)
	sw $t6 2068($t0)
	
	#Draw fire row 6
	sw $t2 2564($t0)
	sw $t3 2568($t0)
	sw $t4 2572($t0)
	sw $t3 2576($t0)
	sw $t2 2580($t0)
	sw $t6 2584($t0)

	# Return to caller
	jr $ra
	
randomize_f1_hit:	#Randomize fire setup when hit by ship shot
	
	# Count obstacle passed for difficulty increase
	lw $t6 28($s1)
	addi $t6 $t6 1
	sw $t6 28($s1)
	
	# Clear shot from screen
	addi $sp $sp 4
	lw $t7 96($s1)
	sw $t7 0($sp)
	li $t6 0x000000
	li $t8 0x000000
	jal shoot_ship2 
	
	# Randomize and draw fire
	sw $zero 96($s1)
	lw $t0 168($s1)
	jal randomize_fire1
	j play_game
	
before_rand_f1:		# Count obstacle passed for difficulty increase	
	lw $t6 28($s1)
	addi $t6 $t6 1
	sw $t6 28($s1)	
	
randomize_fire1:	#Randomize fire when resetting
	
	# Choose random number form 1-100
	li $v0 42
	li $a0 1
	li $a1 100
	syscall
	
	li $t6 0x000000 #Black
	
	#Clear fire row 7
	sw $t6 3072($t0)
	sw $t6 3076($t0)
	sw $t6 3080($t0)
	sw $t6 3084($t0)
	sw $t6 3088($t0)
	sw $t6 3092($t0)
	sw $t6 3096($t0)
	
	#Clear fire row 8
	sw $t6 3584($t0)
	sw $t6 3588($t0)
	sw $t6 3592($t0)
	sw $t6 3596($t0)
	sw $t6 3600($t0)
	sw $t6 3604($t0)
	sw $t6 3608($t0)
	
	#Clear fire row 9
	sw $t6 4096($t0)
	sw $t6 4100($t0)
	sw $t6 4104($t0)
	sw $t6 4108($t0)
	sw $t6 4112($t0)
	sw $t6 4116($t0)
	
	#Clear fire row 10
	sw $t6 4612($t0)
	sw $t6 4616($t0)
	sw $t6 4620($t0)
	sw $t6 4624($t0)
	
	#Clear fire row 1
	sw $t6 8($t0)
	sw $t6 12($t0)

	#Clear fire row 2
	sw $t6 516($t0)
	sw $t6 520($t0)

	#Clear fire row 3
	sw $t6 1036($t0)
	sw $t6 1040($t0)
	sw $t6 1048($t0)
	sw $t6 1052($t0)

	#Clear fire row 4
	sw $t6 1548($t0)
	sw $t6 1552($t0)
	sw $t6 1556($t0)

	#Clear fire row 5
	sw $t6 2056($t0)
	sw $t6 2060($t0)
	sw $t6 2064($t0)
	sw $t6 2068($t0)
	
	#Clear fire row 6
	sw $t6 2564($t0)
	sw $t6 2568($t0)
	sw $t6 2572($t0)
	sw $t6 2576($t0)
	sw $t6 2580($t0)
	sw $t6 2584($t0)
	
	#Use randomly selected number to set new start on reset
	li $t7 128
	mult $a0 $t7
	li $t7 4
	mflo $a0
	mult $a0 $t7
	mflo $t0
	addi $t0 $t0 432
	
	#Draw fire with new spawn location
	lw $t7 164($s1)
	add $t0 $t0 $t7
	sw $t0 168($s1)
	j drawing_fire
	
randomize_f2_hit:	#Randomize fire2 setup when hit by ship shot
	
	# Count obstacle passed for difficulty increase
	lw $t6 28($s1)
	addi $t6 $t6 1
	sw $t6 28($s1)
	addi $sp $sp 4
	
	#Clear shot from screen
	lw $t7 96($s1)
	sw $t7 0($sp)
	li $t6 0x000000
	li $t8 0x000000
	jal shoot_ship2 
	
	#Randomize fire 2 and redraw
	sw $zero 96($s1)
	lw $t0 40($s1)
	jal randomize_fire2
	j play_game

before_rand_f2:		# Count obstacle passed for difficulty increase
	lw $t6 28($s1)
	addi $t6 $t6 1
	sw $t6 28($s1)			

randomize_fire2:	#Randomize fire when resetting
	
	#Choose random number from 1-100
	li $v0 42
	li $a0 1
	li $a1 100
	syscall
	
	li $t6 0x000000 #Black
	
	#Clear fire 2 row 7
	sw $t6 3072($t0)
	sw $t6 3076($t0)
	sw $t6 3080($t0)
	sw $t6 3084($t0)
	sw $t6 3088($t0)
	sw $t6 3092($t0)
	sw $t6 3096($t0)
	sw $t6 3100($t0)
	
	#Clear fire 2 row 8
	sw $t6 3584($t0)
	sw $t6 3588($t0)
	sw $t6 3592($t0)
	sw $t6 3596($t0)
	sw $t6 3600($t0)
	sw $t6 3604($t0)
	sw $t6 3608($t0)
	sw $t6 3612($t0)
	
	#Clear fire 2 row 9
	sw $t6 4096($t0)
	sw $t6 4100($t0)
	sw $t6 4104($t0)
	sw $t6 4108($t0)
	sw $t6 4112($t0)
	sw $t6 4116($t0)
	sw $t6 4120($t0)
	
	#Clear fire 2 row 10
	sw $t6 4612($t0)
	sw $t6 4616($t0)
	sw $t6 4620($t0)
	sw $t6 4624($t0)
	sw $t6 4628($t0)
	
	#Clear fire 2 row 1
	sw $t6 8($t0)
	sw $t6 12($t0)
	sw $t6 16($t0)

	#Clear fire 2 row 2
	sw $t6 516($t0)
	sw $t6 520($t0)
	sw $t6 524($t0)

	#Clear fire 2 row 3
	sw $t6 1036($t0)
	sw $t6 1044($t0)
	sw $t6 1048($t0)
	sw $t6 1052($t0)
	sw $t6 1056($t0)

	#Clear fire 2 row 4
	sw $t6 1548($t0)
	sw $t6 1552($t0)
	sw $t6 1556($t0)
	sw $t6 1560($t0)

	#Clear fire 2 row 5
	sw $t6 2056($t0)
	sw $t6 2060($t0)
	sw $t6 2064($t0)
	sw $t6 2068($t0)
	sw $t6 2072($t0)
	
	#Clear fire 2 row 6
	sw $t6 2564($t0)
	sw $t6 2568($t0)
	sw $t6 2572($t0)
	sw $t6 2576($t0)
	sw $t6 2580($t0)
	sw $t6 2584($t0)
	sw $t6 2588($t0)
	
	#Use randomly selected number to randomize new spawn
	li $t7 128
	mult $a0 $t7
	li $t7 4
	mflo $a0
	mult $a0 $t7
	mflo $t0
	addi $t0 $t0 480
	
	#Use new spanw loaction to draw reset fire 2
	lw $t7 164($s1)
	add $t0 $t0 $t7
	sw $t0 40($s1)
	j drawing_fire2

draw_fire2:	# Determine fire 2 collision before draw 
	
	#Load fire 2 colours
	li $t2 0xD50000 #Red
	li $t3 0xF4501E #Orange
	li $t4 0xFF9900 #OrangeL
	li $t5 0xFFEB3B #Yellow
	li $t6 0x000000 #Yellow
	lw $t0 0($sp)
	addi $sp $sp -4
	
	#Load ship and ship shot colours
	li $a1 0x37474F
	li $a2 0x546E7A
	li $v1 0xFFFFFE
	
	# If top of fire 2 hits ship do damage, if shot hits reset
	lw $a3 3072($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 4096($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	# If side of fire 2 hits ship do damage, if shot hits reset
	lw $a3 4100($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 1036($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 1048($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 2064($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 2056($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	# If bottom of fire 2 hits ship do damage, if shot hits reset
	lw $a3 3604($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 3608($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 2580($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 2584($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 4616($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	lw $a3 4620($t0)
	beq $a3 $a1 damage_fire2
	beq $a3 $a2 damage_fire2
	beq $a3 $v1 randomize_f2_hit
	
	
	# If fire 2 tries to go off screen randomize and reset
	li $t7 512
	div $t0 $t7
	mfhi $t7
	beq $t7 $zero before_rand_f2
	
	li $t7 512
	addi $t8 $t0 4
	div $t8 $t7
	mfhi $t7
	beq $t7 $zero before_rand_f2

drawing_fire2:		#Draw fire 2 (drawn by rows)
	
	# Draw fire 2 row 7
	sw $t2 3072($t0)
	sw $t3 3076($t0)
	sw $t3 3080($t0)
	sw $t4 3084($t0)
	sw $t3 3088($t0)
	sw $t2 3092($t0)
	sw $t6 3096($t0)
	sw $t6 3100($t0)
	
	# Draw fire 2 row 8
	sw $t2 3584($t0)
	sw $t3 3588($t0)
	sw $t5 3592($t0)
	sw $t5 3596($t0)
	sw $t3 3600($t0)
	sw $t2 3604($t0)
	sw $t6 3608($t0)
	sw $t6 3612($t0)
	
	# Draw fire 2 row 9
	sw $t2 4096($t0)
	sw $t4 4100($t0)
	sw $t5 4104($t0)
	sw $t3 4108($t0)
	sw $t2 4112($t0)
	sw $t6 4116($t0)
	sw $t6 4120($t0)
	
	# Draw fire 2 row 10
	sw $t2 4612($t0)
	sw $t3 4616($t0)
	sw $t2 4620($t0)
	sw $t6 4624($t0)
	sw $t6 4628($t0)
	
	# Draw fire 2 row 1
	sw $t2 8($t0)
	sw $t6 12($t0)
	sw $t6 16($t0)

	# Draw fire 2 row 2
	sw $t2 516($t0)
	sw $t6 520($t0)
	sw $t6 524($t0)

	# Draw fire 2 row 3
	sw $t2 1036($t0)
	sw $t6 1044($t0)
	sw $t2 1048($t0)
	sw $t6 1052($t0)
	sw $t6 1056($t0)
	
	# Draw fire 2 row 4
	sw $t2 1548($t0)
	sw $t2 1552($t0)
	sw $t6 1556($t0)
	sw $t6 1560($t0)

	# Draw fire 2 row 5
	sw $t2 2056($t0)
	sw $t3 2060($t0)
	sw $t2 2064($t0)
	sw $t6 2068($t0)
	sw $t6 2072($t0)
	
	# Draw fire 2 row 6
	sw $t2 2564($t0)
	sw $t3 2568($t0)
	sw $t4 2572($t0)
	sw $t3 2576($t0)
	sw $t2 2580($t0)
	sw $t6 2584($t0)
	sw $t6 2588($t0)

	# Return to caller
	jr $ra

boss_hit:	# Calculate damage when boss gets shot
	
	# Deal 10 damage to boss
	lw $t7 104($s1)
	addi $t7 $t7 -10
	sw $t7 104($s1)
	
	# Clear and reset shot
	addi $sp $sp 4
	lw $t7 96($s1)
	sw $t7 0($sp)
	li $t6 0x000000
	li $t8 0x000000
	jal shoot_ship2 
	sw $zero 96($s1)
	addi $sp $sp 4
	
	#Redraw boss
	lw $t0 80($s1)
	li $t2 0x000000 #DGray
	li $t3 0x000000 #LGray
	li $t4 0x000000 #L Blue
	li $t5 0x000000 #D Blue
	li $t6 0x000000 #Black
	jal drawing_boss
	
	# Return to main game loop
	j play_game

draw_boss:		# Determine ufo collision before draw
	li $t2 0x607D8B #DGray
	li $t3 0x78909C #LGray
	li $t4 0x00BBD4 #L Blue
	li $t5 0x03A8F4 #D Blue
	li $t6 0x000000 #Black
	lw $t0 0($sp)
	addi $sp $sp -4
	
	#Load colour of ship shot and ship
	li $a1 0x37474F
	li $a2 0x546E7A
	li $v1 0xFFFFFE
	
	
	# If front of ufo hits ship do damage, if shot hits ufo takes damage
	lw $a3 536($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 1044($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 2124($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit

	lw $a3 2052($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 3584($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 4616($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5136($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5176($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5152($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	# If top of ufo hits ship do damage, if shot hits ufo takes damage
	lw $a3 552($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 564($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 28($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 36($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 44($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 52($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	# If bottom of ufo hits ship do damage, if shot hits ufo takes damage
	lw $a3 5652($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5660($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5672($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5684($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	lw $a3 5692($t0)
	beq $a3 $a1 damage_boss
	beq $a3 $a2 damage_boss
	beq $a3 $v1 boss_hit
	
	
drawing_boss:		# Draw ufo (drawn by row)

	# Draw ufo row 1
	sw $t6 28($t0)
	sw $t6 32($t0)
	sw $t6 36($t0)
	sw $t6 40($t0)
	sw $t6 44($t0)
	sw $t6 48($t0)
	sw $t6 52($t0)
	
	# Draw ufo row 2
	sw $t6 536($t0)
	sw $t4 540($t0)
	sw $t4 544($t0)
	sw $t4 548($t0)
	sw $t4 552($t0)
	sw $t4 556($t0)
	sw $t4 560($t0)
	sw $t4 564($t0)
	sw $t6 568($t0)
	
	# Draw ufo row 3
	sw $t6 1044($t0)
	sw $t4 1048($t0)
	sw $t4 1052($t0)
	sw $t5 1056($t0)
	sw $t5 1060($t0)
	sw $t5 1064($t0)
	sw $t5 1068($t0)
	sw $t5 1072($t0)
	sw $t5 1076($t0)
	sw $t5 1080($t0)
	sw $t6 1084($t0)
	
	# Draw ufo row 4
	sw $t6 1548($t0)
	sw $t6 1552($t0)
	sw $t6 1556($t0)
	sw $t4 1560($t0)
	sw $t5 1564($t0)
	sw $t5 1568($t0)
	sw $t5 1572($t0)
	sw $t5 1576($t0)
	sw $t5 1580($t0)
	sw $t5 1584($t0)
	sw $t5 1588($t0)
	sw $t5 1592($t0)
	sw $t6 1596($t0)
	sw $t6 1600($t0)
	sw $t6 1604($t0)
	
	# Draw ufo row 5
	sw $t6 2052($t0)
	sw $t6 2056($t0)
	sw $t3 2060($t0)
	sw $t3 2064($t0)
	sw $t6 2068($t0)
	sw $t4 2072($t0)
	sw $t5 2076($t0)
	sw $t5 2080($t0)
	sw $t5 2084($t0)
	sw $t5 2088($t0)
	sw $t5 2092($t0)
	sw $t5 2096($t0)
	sw $t5 2100($t0)
	sw $t5 2104($t0)
	sw $t6 2108($t0)
	sw $t3 2112($t0)
	sw $t3 2116($t0)
	sw $t6 2120($t0)
	sw $t6 2124($t0)
	
	# Draw ufo row 6
	sw $t6 2560($t0)
	sw $t2 2564($t0)
	sw $t2 2568($t0)
	sw $t2 2572($t0)
	sw $t3 2576($t0)
	sw $t2 2580($t0)
	sw $t6 2584($t0)
	sw $t6 2588($t0)
	sw $t6 2592($t0)
	sw $t6 2596($t0)
	sw $t6 2600($t0)
	sw $t6 2604($t0)
	sw $t6 2608($t0)
	sw $t6 2612($t0)
	sw $t6 2616($t0)
	sw $t3 2620($t0)
	sw $t3 2624($t0)
	sw $t3 2628($t0)
	sw $t3 2632($t0)
	sw $t3 2636($t0)
	sw $t6 2640($t0)
	
	# Draw ufo row 7
	sw $t6 3072($t0)
	sw $t2 3076($t0)
	sw $t2 3080($t0)
	sw $t2 3084($t0)
	sw $t2 3088($t0)
	sw $t2 3092($t0)
	sw $t2 3096($t0)
	sw $t2 3100($t0)
	sw $t3 3104($t0)
	sw $t3 3108($t0)
	sw $t3 3112($t0)
	sw $t3 3116($t0)
	sw $t3 3120($t0)
	sw $t3 3124($t0)
	sw $t3 3128($t0)
	sw $t3 3132($t0)
	sw $t3 3136($t0)
	sw $t3 3140($t0)
	sw $t3 3144($t0)
	sw $t3 3148($t0)
	sw $t3 3152($t0)
	sw $t6 3156($t0)
	
	# Draw ufo row 8
	sw $t6 3584($t0)
	sw $t2 3588($t0)
	sw $t2 3592($t0)
	sw $t2 3596($t0)
	sw $t2 3600($t0)
	sw $t2 3604($t0)
	sw $t2 3608($t0)
	sw $t2 3612($t0)
	sw $t2 3616($t0)
	sw $t2 3620($t0)
	sw $t2 3624($t0)
	sw $t2 3628($t0)
	sw $t3 3632($t0)
	sw $t3 3636($t0)
	sw $t3 3640($t0)
	sw $t3 3644($t0)
	sw $t3 3648($t0)
	sw $t3 3652($t0)
	sw $t3 3656($t0)
	sw $t3 3660($t0)
	sw $t3 3664($t0)
	sw $t6 3668($t0)
	
	# Draw ufo row 9
	sw $t6 4100($t0)
	sw $t2 4104($t0)
	sw $t2 4108($t0)
	sw $t2 4112($t0)
	sw $t2 4116($t0)
	sw $t2 4120($t0)
	sw $t2 4124($t0)
	sw $t2 4128($t0)
	sw $t2 4132($t0)
	sw $t2 4136($t0)
	sw $t2 4140($t0)
	sw $t2 4144($t0)
	sw $t2 4148($t0)
	sw $t3 4152($t0)
	sw $t3 4156($t0)
	sw $t3 4160($t0)
	sw $t3 4164($t0)
	sw $t3 4168($t0)
	sw $t3 4172($t0)
	sw $t6 4176($t0)
	
	# Draw ufo row 10
	sw $t6 4616($t0)
	sw $t6 4620($t0)
	sw $t6 4624($t0)
	sw $t6 4628($t0)
	sw $t6 4632($t0)
	sw $t6 4636($t0)
	sw $t6 4640($t0)
	sw $t6 4644($t0)
	sw $t6 4648($t0)
	sw $t6 4652($t0)
	sw $t6 4656($t0)
	sw $t6 4660($t0)
	sw $t6 4664($t0)
	sw $t6 4668($t0)
	sw $t6 4672($t0)
	sw $t6 4676($t0)
	sw $t6 4680($t0)
	sw $t6 4684($t0)

	# Draw ufo row 11
	sw $t6 5136($t0)
	sw $t2 5140($t0)
	sw $t2 5144($t0)
	sw $t2 5148($t0)
	sw $t2 5152($t0)
	sw $t2 5156($t0)
	sw $t2 5160($t0)
	sw $t2 5164($t0)
	sw $t2 5168($t0)
	sw $t2 5172($t0)
	sw $t3 5176($t0)
	sw $t3 5180($t0)
	sw $t6 5184($t0)
	
	# Draw ufo row 12
	sw $t6 5652($t0)
	sw $t6 5656($t0)
	sw $t6 5660($t0)
	sw $t6 5664($t0)
	sw $t6 5668($t0)
	sw $t6 5672($t0)
	sw $t6 5676($t0)
	sw $t6 5680($t0)
	sw $t6 5684($t0)
	sw $t6 5688($t0)
	sw $t6 5692($t0)

	# Return to caller
	jr $ra
	
return_UI_Boss:		#Draw "Boss" on ui (drawn by row)
	
	#Load colours for drawing
	li $t9 0xD50100
	lw $t5 164($s1)
	addi $t5 $t5 59640
	
	#Draw "Boss" row 1
	sw $t9 0($t5)
	sw $t9 4($t5)
	sw $t9 8($t5)
	sw $t9 24($t5)
	sw $t9 28($t5)
	sw $t9 32($t5)
	sw $t9 36($t5)
	sw $t9 48($t5)
	sw $t9 52($t5)
	sw $t9 56($t5)
	sw $t9 60($t5)
	sw $t9 72($t5)
	sw $t9 76($t5)
	sw $t9 80($t5)
	sw $t9 84($t5)
	
	#Draw "Boss" row 2
	sw $t9 512($t5)
	sw $t9 524($t5)
	sw $t9 536($t5)
	sw $t9 548($t5)
	sw $t9 560($t5)
	sw $t9 584($t5)
	sw $t9 608($t5)
	
	#Draw "Boss" row 3
	sw $t9 1024($t5)
	sw $t9 1036($t5)
	sw $t9 1048($t5)
	sw $t9 1060($t5)
	sw $t9 1072($t5)
	sw $t9 1096($t5)
	
	#Draw "Boss" row 4
	sw $t9 1536($t5)
	sw $t9 1540($t5)
	sw $t9 1544($t5)
	sw $t9 1560($t5)
	sw $t9 1572($t5)
	sw $t9 1584($t5)
	sw $t9 1588($t5)
	sw $t9 1592($t5)
	sw $t9 1596($t5)
	sw $t9 1608($t5)
	sw $t9 1612($t5)
	sw $t9 1616($t5)
	sw $t9 1620($t5)
	
	#Draw "Boss" row 5
	sw $t9 2048($t5)
	sw $t9 2060($t5)
	sw $t9 2072($t5)
	sw $t9 2084($t5)
	sw $t9 2108($t5)
	sw $t9 2132($t5)
	
	#Draw "Boss" row 6
	sw $t9 2560($t5)
	sw $t9 2572($t5)
	sw $t9 2584($t5)
	sw $t9 2596($t5)
	sw $t9 2620($t5)
	sw $t9 2644($t5)
	sw $t9 2656($t5)
	
	#Draw "Boss" row 7
	sw $t9 3072($t5)
	sw $t9 3076($t5)
	sw $t9 3080($t5)
	sw $t9 3096($t5)
	sw $t9 3100($t5)
	sw $t9 3104($t5)
	sw $t9 3108($t5)
	sw $t9 3120($t5)
	sw $t9 3124($t5)
	sw $t9 3128($t5)
	sw $t9 3132($t5)
	sw $t9 3144($t5)
	sw $t9 3148($t5)
	sw $t9 3152($t5)
	sw $t9 3156($t5)
	
colour_health_boss:	#Setup for boss health draw
	
	#Load colour and addres for hp
	li $t9 0x7AFA5A
	lw $t2 0($sp)
	addi $sp $sp -4
	div $t2 $t2 4
	
	#Load health and end address
	addi $t4 $zero 0
	li $t3 25
	lw $t5 164($s1)
	addi $t5 $t5 60780
	
colour_green_boss:	#Loop to draw boss health
	
	# While less than end continue to draw health (3 width)
	bge $t4 $t2 checker_boss
	sw $t9 0($t5)
	sw $t9 512($t5)
	sw $t9 1024($t5)
	addi $t5 $t5 4
	addi $t4 $t4 1
	j colour_green_boss
	
checker_boss:		# If health goes to negative, set it to 0
	bgez $t2 colour_red_boss
	add $t2 $zero $zero
	
colour_red_boss:	# Loop to draw missing boss health
	
	# Load missing boss health colour
	li $t9 0xD50000
	
	# While health bar not filled draw
	bge $t2 $t3 return_health_boss
	sw $t9 0($t5)
	sw $t9 512($t5)
	sw $t9 1024($t5)
	addi $t5 $t5 4
	addi $t2 $t2 1
	j colour_red_boss
	
return_health_boss:	# Return from drawing health
	
	# If boss has less than 0 health load game over
	lw $t2 104($s1)
	blez $t2 game_over
	jr $ra
# ===========================================
