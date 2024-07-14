 .globl main

.data
mazeFilename:    .asciiz "./input_1.txt"
buffer:          .space 4096
victoryMessage:  .asciiz "\nYou have won the game!"

amountOfRows:    .word 16  # The mount of rows of pixels
amountOfColumns: .word 32  # The mount of columns of pixels

wallColor:      .word 0x004286F4    # Color used for walls (blue)
passageColor:   .word 0x00000000    # Color used for passages (black)
playerColor:    .word 0x00FFFF00    # Color used for player (yellow)
exitColor:      .word 0x0000FF00    # Color used for exit (green)

.text

main: 
	jal read_maze 
	move $a0, $v0 # buffer
	jal color_screen
	move $t0, $v0 # load player's starting row into $t0
	move $t1, $v1 # load player's starting column into $t1
game_loop:
	# Read a character
	li $v0, 12
	syscall 
	la $t2, ($v0) # load input character into $t2
	
	move $a0, $t2 # input character
	jal inputs # get row/column operation (e.g. -1 rows when 'z' is pressed) for new position
	move $t2, $v0 
	add $t2, $t2, $t0 # rows of new position
	move $t3, $v1
	add $t3, $t3, $t1 # columns of new position
 	
	move $a0, $t0 # rows of current position
	move $a1, $t1 # columns of current position
	move $a2, $t2 # rows of new position
	move $a3, $t3 # columns of new position
	jal update_player_position
	move $t0, $v0 # current row = new row 
	move $t1, $v1 # current column = new column
	
	# Sleep for 60ms
	li $v0, 32
	li $a0, 60
	syscall
	j game_loop
	
inputs:
	# Build the stack
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 16
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	
	move $s0, $a0 # input character

	beq $s0, 'z', input_up
	beq $s0, 's', input_down
	beq $s0, 'q', input_left
	beq $s0, 'd', input_right
	beq $s0, 'x', input_x
	# if any other input, then:
	j game_loop
return_1:
	# Pop the stack
	lw $s0, -8($fp)
	lw $ra, -4($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra
input_up:
	li $v0, -1 # go up 1 row
	li $v1, 0
	j return_1
input_down:
	li $v0, 1 # go down 1 row
	li $v1, 0
	j return_1
input_left:
	li $v0, 0
	li $v1, -1 # go left 1 column
	j return_1
input_right:
	li $v0, 0 # go right 1 column
	li $v1, 1
	j return_1
input_x:
	j exit
	
update_player_position:
	# Build the stack
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 40
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	sw $s2, -16($fp)
	sw $s3, -20($fp)
	sw $s4, -24($fp)
	sw $s5, -28($fp)
	sw $s6, -32($fp)
	
	move $s0, $a0 # rows of current position
	move $s1, $a1 # columns of current position
	
	# Pre-emptive returning of current position for bug fixing purposes
	move $v0, $s0
	move $v1, $s1
	
	mul $s4, $s0, 128 # number of bits to add for row = rownumber * 128
	mul $s5, $s1, 4 # number of bits to add for column = columnnumber * 4
	
	li $gp, 0x10008000 # reset the global pointer to (0,0)
	add $gp, $gp, $s4 # update the global pointer with the number of bits for the row
	add $gp, $gp, $s5 # update the global pointer with the number of bits for the column
	move $s4, $gp # address of current position
	
	move $s2, $a2 # rows of new position
	move $s3, $a3 # columns of new position
	
	mul $s5, $s2, 128 # number of bits to add for row = rownumber * 128
	mul $s6, $s3, 4 # number of bits to add for column = columnnumber * 4
	
	li $gp, 0x10008000 # reset the global pointer to (0,0)
	add $gp, $gp, $s5 # update the global pointer with the number of bits for the row
	add $gp, $gp, $s6 # update the global pointer with the number of bits for the column
	move $s5, $gp # address of new position
	
	# Verify whether new position is legal (/new position isn't a wall)
	lw $s0, wallColor
	lw $s1, ($gp) # global pointer is currently at new position
	beq $s1, $s0, return 
	
	# Return the player's current position
	move $v0, $s2
	move $v1, $s3
	
	# Decolor current pixel
	move $gp, $s4 # address of current position
	lw $s3, passageColor
	sw $s3, ($gp)
	# Check if exit was reached
	move $gp, $s5 # address of new position
	lw $s0, exitColor
	lw $s1, ($gp)
	beq $s1, $s0, exit_found
	# Color new pixel
	move $gp, $s5
	lw $s3, playerColor
	sw $s3, ($gp)
	
return:
	# Pop the stack
	lw $s6, -32($fp)
	lw $s5, -28($fp)
	lw $s4, -24($fp)
	lw $s3, -20($fp)
	lw $s2, -16($fp)
	lw $s1, -12($fp)
	lw $s0, -8($fp)
	lw $ra, -4($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra
	
color_screen:
	# Build the stack
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 28
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	sw $s1, -12($fp)
	sw $s2, -16($fp)
	sw $s3, -20($fp)
	
	move $s0, $a0 # buffer
	la $a0, ($s0) # address of first character from buffer
	li $s3, 0 # $s3 is used for player's starting position
loop:
	lb $s1, ($a0) # load character from buffer
	# Compare current character to valid characters
	beq $s1, 'w', wall
	beq $s1, 'p', passage
	beq $s1, 's', player
	beq $s1, 'u', maze_exit
	# if 'newline', then:
	subi $gp, $gp, 4 # prevent $gp from being updated
	subi $s3, $s3, 1 # prevent player's starting position from being updated
color_pixel:	
	sw $s2, ($gp) # color current pixel
	addi $a0, $a0, 1 # update address to next byte from buffer
	addi $gp, $gp, 4 # update global pointer to next pixel
	addi $s3, $s3, 1 # add 1 (pixel) to player's starting position
	bne $s1, 0, loop # loop ends when terminating 0 is reached
	
	# Pop the stack
	lw $s3, -20($fp)
	lw $s2, -16($fp)
	lw $s1, -12($fp)
	lw $s0, -8($fp)
	lw $ra, -4($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra
wall:
	lw $s2, wallColor
	j color_pixel
passage:
	lw $s2, passageColor
	j color_pixel
player:
	lw $s2, playerColor
	
	# Calculate and return the player's starting position
	div $s3, $s3, 32
	mflo $s3 # row = quotient
	move $v0, $s3 # place the player's starting row in return value location
	mfhi $s3 # column = remainder
	move $v1, $s3 # place the player's starting column in 2nd return value location
	
	j color_pixel
maze_exit:
	lw $s2, exitColor
	j color_pixel
	
read_maze: 
	# Build the stack
	sw $fp, 0($sp)
	move $fp, $sp
	subu $sp, $sp, 12
	sw $ra, -4($fp)
	sw $s0, -8($fp)
	
	# Open the maze file
	li $v0, 13 
	la $a0, mazeFilename 
	li $a1, 0 
	li $a2, 0
	syscall
	
	move $s0, $v0 # save the file descriptor

	# Read from file to buffer
	li $v0, 14
	move $a0, $s0
	la $a1, buffer
	li $a2, 2048
	syscall
	
	move $v0, $a1 # place buffer in return value location
	
	# Pop the stack
	lw $s0, -8($fp)
	lw $ra, -4($fp)
	move $sp, $fp
	lw $fp, ($sp)
	jr $ra

exit_found:
	la $a0, victoryMessage
	li $v0, 4
	syscall
	
exit:
	# closes the maze file
	li $v0, 16
	move $a0, $s0
	syscall
 
	# syscall to end the program
    	li $v0, 10    
    	syscall