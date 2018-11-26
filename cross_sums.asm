#FILE:				cross_sums.asm
#AUTHOR:			(OMITTED FROM VIEWING)
#
#DESCRIPTION:
#	This program will be able to solve a Kakuro puzzle. If the puzzle is
#	unsolvable, it will print out a message that it is unsolvable and 
#	terminate. This program will also check that the inputs provided by
#	the user is valid according to the assignment.
#
#ARGUMENTS:
#		None
#
#INPUT:
#		n - size of the board between 2 and 12
#		board - nxn series of inputs that will construct the board itself
#
#OUTPUT:
#	If valid, the board before and after solution
#	If not valid, an message stating no solution can be found
#


#
# CONSTANT DECLARATIONS
#
PRINT_INT		= 1		# code for syscall to print integer
PRINT_STRING	= 4		# code for syscall to print a string
READ_INT		= 5		# code for syscall to get int from user
MIN_BOARD		= 1		# minimum value to check for board size
MAX_BOARD		= 13	# maximum value to check for board size
MAX_NUM			= 46	# maximum value to check for total on row/col

#
# DATA DECLARATIONS
#
	.data
	.align 2
newline:
	.asciiz "\n"
	
imposs_puzzle:
	.asciiz "\nImpossible Puzzle\n"
	
illegal_value:
	.asciiz "\nIllegal input value, Cross Sums terminating\n"
	
illegal_board_size:
	.asciiz "\nInvalid board size, Cross Sums terminating\n"

banner:
	.asciiz "\n******************\n**  CROSS SUMS  **\n******************\n"
	
init_puzzle:
	.asciiz	"\nInitial Puzzle\n\n"

final_puzzle:
	.asciiz	"\nFinal Puzzle\n\n"

cell_border_beg:
	.asciiz "+---"

cell_border_end:
	.asciiz	"+"

cell_border_wall:
	.asciiz	"|"

cell_empty:
	.asciiz "   "

cell_num_spacer:
	.asciiz " "
	
clue_divider:
	.asciiz	"\\"

clue_numblock_sing:
	.asciiz	"#"
	
clue_numblock_noclue:
	.asciiz	"##"

clue_middle:
	.asciiz "#\\#"

	.align 2
board:
	.space	576
	
same_num:
	.space	48

board_size:
	.word	0
	
#
# MAIN PROGRAM
#

	.text
	.align	2
	.globl	main
	.globl	board
	.globl	board_size
	.globl	solver_main

main:
	addi	$sp, $sp, -12				      # Allocate memory for return address
	sw		$ra, 4($sp)					      # store the ra
	sw		$s0, 0($sp)

	jal		print_banner
	
	jal		get_input					        # collect input and set puzzle
	
	bne		$v0, $zero, end_program		# if we have an error, end program
	
	jal		print_init_puzzle			    # print init_puzzle

	jal		print_board					      # print border before solving

	jal		solver_main					      # call solver
	
	bne		$v0, $zero, imposs_puzz
	
	jal		print_final_puzzle			  # print final puzzle
	
	jal		print_board					      # print final board
	
end_program:
	lw		$ra, 4($sp)					      # Clean stack and exit program
	lw		$s0, 0($sp)
	addi	$sp, $sp, 12
	jr		$ra
	
#
#GET_INPUT
#
#ARGUMENTS:
#	None
#
#INPUT:
#	Gathered from user
#
#OUTPUT:
#	Will print out error codes if needed
#

get_input:
	li		$v0, READ_INT				      # get board size from user
	syscall

	move	$a0, $v0					        # store value in a0 and t7

	la		$t0, MIN_BOARD				    # if the board is to small or big
	slt		$t1, $t0, $a0				      # print error and exit program
	beq		$t1, $zero, ill_brd_size
	
	move	$t7, $a0
	
	la		$t0, board_size				    # store size of board
	sw		$a0, 0($t0)
	
	la		$t0, MAX_BOARD
	slt		$t1, $a0, $t0
	beq		$t1, $zero, ill_brd_size

	move	$t0, $zero
	mul		$t6, $t7, $t7				      # reset t0 and get the nxn size
	move	$t7, $zero
	
input_loop:

	beq		$t0, $t6, input_loop_done	# Get all data for each cell
	
	li		$v0, READ_INT
	syscall
	
	move	$a0, $v0
	
	beq		$a0, $zero, insert_to_board	# 0 value means empty cell
	
	li		$t1, 100					        # find the number for the down
	div		$t2, $a0, $t1				      # and left clue, then check if valid
	rem		$t3, $a0, $t1
	
	j		ill_value_check
	
insert_to_board:						      # numbers are good, insert to board
	
	la		$t1, board
	add		$t1, $t1, $t7
	addi	$t7, $t7, 4
	sw		$a0, 0($t1)
	addi	$t0, $t0, 1

	j		input_loop					        # go to next input
	
input_loop_done:
	
	move	$v0, $zero					      # return call
	jr		$ra
	
ill_value_check:

	slt		$t5, $zero, $t2				    # if div num is less than 1
	beq		$t5, $zero, ill_val_print	# illegal value
	
	slt		$t5, $zero, $t3				    # if rem is less than 1
	beq		$t5, $zero, ill_val_print	# illegal value
	
	la		$t4, MAX_NUM				      # if div is bigger than 45
	slt		$t5, $t2, $t4				      # check to see if its 99
	beq		$t5, $zero, chk_block_acr	
	
ill_val_chk_dwn:
	
	la		$t4, MAX_NUM				      # if rem is bigger than 45
	slt		$t5, $t3, $t4				      # check to see if its 99
	beq		$t5, $zero, chk_block_dwn	
	
	j		insert_to_board				      # both good, insert to board
	
chk_block_acr:

	li		$t4, 99						        # if 99, check down, else error
	beq		$t4, $t2, ill_val_chk_dwn
	
	j		ill_val_print
	
chk_block_dwn:
	
	li		$t4, 99						        # if 99 then insert, else error
	beq		$t4, $t3, insert_to_board
	
	j		ill_val_print

#
#PRINT BOARD
#
#ARGUMENTS:
#	None
#
#INPUT:
#	None
#
#OUTPUT:
#	The board before and after solution
#
#DESCRIPTION:
#	Series of functions to print out the board before and after the solution
#	is found
#
print_board:

	addi	$sp, $sp, -40				      # store address for return
	sw		$ra, 32($sp)
	sw		$s7, 28($sp)
	sw		$s6, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)

	move	$t0, $zero
	la		$t1, board_size				    # load board size
	lw		$t2, 0($t1)						
	mul		$t3, $t2, 4	
	addi	$t3, $t3, 1					      # t3 = (size of board x 4) + 1

	move	$s4, $zero
	move	$s5, $zero
	move	$s6, $zero
	
print_loop:								
	beq		$t0, $t3, print_loop_done	# loop to print board

	rem		$t4, $t0, 4					 
	beq		$t4, $zero, print_border	# if count % 4 is 0 print border

	j		print_cell
	
cont_print_loop:
	addi	$t0, $t0, 1					
	j		print_loop					        # border printed, add 1 and continue

print_cell:
	move	$t4, $zero					      # reset t4 for cell printing

print_cell_loop:
	beq		$t4, $t2, print_cell_end	# if at last cell for the row, stop

	la		$t1, board
	la		$a0, cell_border_wall
	li		$v0, PRINT_STRING
	syscall
	
	rem		$t5, $t0, 4					# if rem = 1, print top of cell
	li		$t6, 1						
	beq		$t5, $t6, cell_top_order

	li		$t6, 2						# if rem = 2, print middle of cell
	beq		$t5, $t6, cell_mid_order

	li		$t6, 3						# if rem = 3, print bottom of cell
	beq		$t5, $t6, cell_bot_order

	j		cont_cell_loop

cell_top_order:
	add		$t1, $t1, $s4
	lw		$s0, 0($t1)					# get number in cell
	addi	$s4, $s4, 4

	li		$t5, 10						
	slt		$t6, $s0, $t5				# if num < 10, not a clue/block
	bne		$t6, $zero, cell_top_num

	la		$a0, clue_divider			# print cell divider
	li		$v0, PRINT_STRING
	syscall

	li		$s2, 99
	div		$s1, $s0, 100
	bne		$s1, $s2, print_cell_int	# if num != 99, its a clue

	la		$a0, clue_numblock_noclue	# print block
	li		$v0, PRINT_STRING
	syscall

	j		cont_cell_loop

cell_mid_order:
	add		$t1, $t1, $s5
	lw		$s0, 0($t1)					# get number in cell
	addi	$s5, $s5, 4

	li		$t5, 10
	slt		$t6, $s0, $t5				# if num < 10, not a clue/block
	bne		$t6, $zero, cell_mid_num

	la		$a0, clue_middle			# print the middle of the cell, static
	li		$v0, PRINT_STRING
	syscall

	j		cont_cell_loop
	
cell_bot_order:
	add		$t1, $t1, $s6
	lw		$s0, 0($t1)					# get number in cell
	addi	$s6, $s6, 4

	li		$t5, 10
	slt		$t6, $s0, $t5				# if num < 10, not a clue/block
	bne		$t6, $zero, cell_top_num

	li		$s2, 99
	rem		$s1, $s0, 100				# if num != 99, its a clue
	bne		$s1, $s2, print_cell_int_bot

	la		$a0, clue_numblock_noclue	# print block
	li		$v0, PRINT_STRING
	syscall

	la		$a0, clue_divider			# print divider
	li		$v0, PRINT_STRING
	syscall

	j		cont_cell_loop
	
cell_mid_num:
	beq		$s0, $zero, print_empt_cell

	la		$a0, cell_num_spacer		# if cell not clue, print space
	li		$v0, PRINT_STRING
	syscall

	move	$a0, $s0					# print number in cell, unless 0
	li		$v0, PRINT_INT
	syscall

	la		$a0, cell_num_spacer		# print space to end middle cell
	li		$v0, PRINT_STRING
	syscall
	
	j		cont_cell_loop

cell_top_num:
	la		$a0, cell_empty
	li		$v0, PRINT_STRING			# if num, top and bot are empty
	syscall

	j		cont_cell_loop

cont_cell_loop:
	addi	$t4, $t4, 1					# increment counter
	j		print_cell_loop

print_cell_end:
	la		$a0, cell_border_wall		# print cell wall when at end of row
	li		$v0, PRINT_STRING
	syscall

	la		$a0, newline
	li		$v0, PRINT_STRING
	syscall
	j		cont_print_loop

print_cell_int:
	li		$s3, 9
	slt		$t5, $s3, $s1				# if two digits, go to two digit print
	bne		$t5, $zero, print_cell_twodig

	la		$a0, clue_numblock_sing		# print num sign
	li		$v0, PRINT_STRING
	syscall

	move	$a0, $s1					# print digit
	li		$v0, PRINT_INT
	syscall

	j		cont_cell_loop


print_cell_twodig:
	move	$a0, $s1
	li		$v0, PRINT_INT				# if two digits, just print digits
	syscall

	j		cont_cell_loop

print_cell_int_bot:
	li		$s3, 9
	slt		$t5, $s3, $s1				# if two digits, go to two digit print
	bne		$t5, $zero, print_cell_twodig_bot

	la		$a0, clue_numblock_sing		# print num sign
	li		$v0, PRINT_STRING
	syscall

	move	$a0, $s1					# print digit
	li		$v0, PRINT_INT
	syscall

	la		$a0, clue_divider			# print the divider
	li		$v0, PRINT_STRING
	syscall

	j		cont_cell_loop


print_cell_twodig_bot:
	move	$a0, $s1					# if two digits, just print digits
	li		$v0, PRINT_INT
	syscall

	la		$a0, clue_divider			# print the divider
	li		$v0, PRINT_STRING
	syscall

	j		cont_cell_loop

print_empt_cell:
	la		$a0, cell_empty				# if 0, just print an empty cell
	li		$v0, PRINT_STRING
	syscall

	j		cont_cell_loop

print_border:
	move	$t4, $zero					

print_border_loop:
	beq		$t4, $t2, print_border_end	

	la		$a0, cell_border_beg		# print begin border till EOL
	li		$v0, PRINT_STRING
	syscall

	addi	$t4, $t4, 1
	j		print_border_loop

print_border_end:		
	la		$a0, cell_border_end		# print end of border and new line
	li		$v0, PRINT_STRING
	syscall

	la		$a0, newline
	syscall

	j		cont_print_loop				# go to next line for printing

print_loop_done:

	lw		$ra, 32($sp)				# restore the stack
	lw		$s7, 28($sp)
	lw		$s6, 24($sp)
	lw		$s5, 20($sp)
	lw		$s4, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 40
	jr		$ra							# return

#
#PRINT STATEMENTS
#
ill_brd_size:
	li		$v0, PRINT_STRING			# print out error for board size
	la		$a0, illegal_board_size
	syscall
	
	li		$v0, 1						# set error marker and return
	jr		$ra
	
ill_val_print:
	li		$v0, PRINT_STRING			# print out error for illegal value
	la		$a0, illegal_value
	syscall
	
	li		$v0, 1						# set error marker and return
	jr		$ra

print_init_puzzle:
	addi	$sp, $sp, -8
	sw		$ra, 0($sp)
	
	la		$a0, init_puzzle			# print init_puzzle
	li		$v0, PRINT_STRING
	syscall
	
	lw		$ra, 0($sp)
	addi	$sp, $sp, 8
	jr		$ra
	
print_banner:
	addi	$sp, $sp, -8
	sw		$ra, 0($sp)
	
	la		$a0, banner					# print banner
	li		$v0, PRINT_STRING
	syscall
	
	lw		$ra, 0($sp)
	addi	$sp, $sp, 8
	jr		$ra
	
print_final_puzzle:
	la		$a0, final_puzzle			# print final puzzle
	li		$v0, PRINT_STRING
	syscall
	
	jr		$ra
	
imposs_puzz:
	li		$v0, PRINT_STRING			# print impossible puzzle
	la		$a0, imposs_puzzle
	syscall
	
	j		end_program
	
