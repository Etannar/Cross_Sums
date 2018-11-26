#FILE:				cross_sums_solver.asm
#AUTHOR:			(OMITTED FROM PUBLIC VIEW)
#
#DESCRIPTION:
#	This is the solver for the program
#
#ARGUMENTS:
#		None
#
#INPUT:
#		None
#
#OUTPUT:
#		None	
#


#
# CONSTANT DECLARATIONS
#
PRINT_INT		= 1		# code for syscall to print integer
PRINT_STRING	= 4		# code for syscall to print a string


#
# DATA DECLARATIONS
#

	.data
	.align 2

newlin:
	.asciiz "\n"

	.text
	.align	2
	.globl	board
	.globl	board_size
	.globl	solver_main

#
#SOLVER_MAIN
#
#ARGUMENTS:
#	None
#
#INPUTS:
#	None
#
#OUTPUT:
#	None
#
	
solver_main:
	addi	$sp, $sp, -12
	sw		$ra, 4($sp)
	sw		$s0, 0($sp)
	
	jal		reset_t_reg					# reset t registers
	
	move	$a0, $zero
	jal		find_empty					# find first 0
	
	bne		$v1, $zero, solver_main_end	# if no empty cell, its invalid
	
	jal		reset_t_reg					# reset t registers
	jal		solve_board					# solve the board
	
	move	$v0, $v1
	
solver_main_end:

	lw		$ra, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 12
	jr		$ra							# return to print board

reset_t_reg:
	addi	$sp, $sp, -8
	sw		$ra, 0($sp)

	move	$t0, $zero					# reset t registers just in case
	move	$t1, $zero
	move	$t2, $zero
	move	$t3, $zero
	move	$t4, $zero
	move	$t5, $zero
	move	$t6, $zero
	move	$t7, $zero
	
	lw		$ra, 0($sp)
	addi	$sp, $sp, 8
	jr		$ra							# return
	
#
#FIRST_EMPTY
#
#ARGUMENTS:
#	None
#
#INPUT:
#	None
#
#OUTPUT:
#	1 if error
#	n for first location of number
#	
#DESCRIPTION:
#	finds the first 0 on board, if none return invalid
#

find_empty:
	addi	$sp, $sp, -32
	sw		$ra, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	la		$s0, board_size				
	lw		$s1, 0($s0)
	move	$s0, $s1					# s0 = board size
	mul		$s2, $s0, $s0				# s2 = size of nxn board
	addi	$s2, $s2, 1
	move	$s4, $a0					# s4 = current loc in mem
	div		$s5, $s4, 4		
	addi	$s5, $s5, 1					
	move	$s3, $s5					# s3 = position on board
	
	beq		$s3, $s2, none_empty		# if s4 = s2, end of board 
	move	$s4, $a0					# reset s4

find_empty_loop:
	beq		$s3, $s2, none_empty
	
	la		$s1, board
	add		$s1, $s1, $s4				# loop through to find first 0
	lw		$s0, 0($s1)

	beq		$s0, $zero, find_loop_end	# if we have a 0, end
	
	addi	$s4, $s4, 4					# go left 1 cell
	addi	$s3, $s3, 1					# increment cell num
	
	j		find_empty_loop

none_empty:

	move	$v1, $zero					# if none are empty, dont change a0
	j		find_return
	
find_loop_end:
	move	$a0, $s4					# a0 = new position
	move	$v1, $zero					# v1 = 0, have empty cell
	
find_return:
	lw		$ra, 24($sp)
	lw		$s5, 20($sp)
	lw		$s4, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 32
	jr		$ra
	
#
#SOLVE_BOARD
#
#ARGUMENTS:
#	None
#
#INPUT:
#	None
#
#OUTPUT:
#	None
#
#DESCRIPTION:
#	solver function for board
#
	
solve_board:
	addi	$sp, $sp, -8
	sw		$ra, 0($sp)
	
solve_loop:
	move	$v1, $zero
	jal		board_solve_check
	bne		$v1, $zero, imm_solution	# if impossible solution, end
	beq		$v0, $zero, solve_loop_done	# if board is solved, return for print
	
	jal		attempt_solve				# attempt to solve board
	bne		$v1, $zero, imm_solution	# if impossible solution, return error
	
	j		solve_loop					# go back to loop
	
solve_loop_done:
	move	$v0, $zero					# return 0 if everything is working
	j		solve_loop_return
	
imm_solution:
	li		$v1, 1						# return 1 if impossible solution
	
solve_loop_return:
	lw		$ra, 0($sp)					#return call for solve_board func
	addi	$sp, $sp, 8
	jr		$ra

#
#BOARD_SOLVE_CHECK
#
#ARGUMENTS:
#	None
#
#INPUT:
#	None
#
#OUTPUT:
#	None
#
#DESCRIPTION:
# Board is solved when there are no more empty cells and the last one is equal
#
board_solve_check:
	addi	$sp, $sp, -8
	sw		$ra, 0($sp)

	jal		reset_t_reg
	jal		last_cell
	bne		$v0, $zero, solv_att_need	# if empty exists, continue solving
	
	jal		check_equal_acr				# if equal and no 0's, board solved
	bne		$v1, $zero, inval_board		# if board is invalid, error
	bne		$v0, $zero, solv_att_need	# if not equal to clue, continue solve
	
	jal		check_equal_up
	bne		$v1, $zero, inval_board		# if board is invalid, error
	bne		$v0, $zero, solv_att_need	# if not equal to clue, continue solve
	
	j		board_check_return
	
inval_board:
	lw		$v1, 1						# v1 = 1 if invalid board
	j		board_check_return
	
solv_att_need:
	jal		reset_t_reg					# reset t registers
	li		$v0, 1						# load error and return
	move	$v1, $zero
	
board_check_return:
	lw		$ra, 0($sp)
	addi	$sp, $sp, 8
	jr		$ra
	
last_cell:
	addi	$sp, $sp, -24
	sw		$ra, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	div		$s0, $a0, 4
	addi	$s0, $s0, 1					# s0 = cell loc
	la		$s1, board_size
	lw		$s2, 0($s1)
	mul		$s3, $s2, $s2				# s2 = nxn
	
	beq		$s3, $s0, at_last_cell		# if s0 = s2, at last cell
	
	li		$v0, 1
	j		last_cell_return
	
at_last_cell:
	move	$v0, $zero
	
last_cell_return:
	lw		$ra, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 24
	jr		$ra
	
#
# Attempt to solve the board
#
attempt_solve:
	addi	$sp, $sp, -28
	sw		$ra, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)

att_solve_loop:
	beq		$a0, $zero, att_solve_impos	# if at pos 0, impossible solution
	move	$s0, $a0
	
	la		$s1, board					# load board and move to 0
	add		$s1, $s1, $s0
	lw		$s2, 0($s1)
	li		$s3, 9
	
	beq		$s2, $s3, undo_caller		# if number is a 9, undo prev move
	
	addi	$s2, $s2, 1
	sw		$s2, 0($s1)					# add 1 to current num and save

	jal		is_valid					# check if valid move
	beq		$v0, $zero, exit_att_solve	
	
	j		att_solve_loop
	
exit_att_solve:
	# check to see if adj are clues/blocks else find empty

	move	$s0, $a0
	la		$s1, board
	addi	$s0, $s0, 4					# get next cell array loc
	add		$s1, $s1, $s0				# go to position in board
	lw		$s2, 0($s1)					# s2 = right cell num
	li		$s3, 10
	slt		$t0, $s2, $s3				# if num right < 10, not a clue
	beq		$t0, $zero, check_acr_tot
	
att_sol_chk_bot:

	move	$s0, $a0
	la		$s1, board
	la		$s2, board_size
	li		$s3, 10
	lw		$s4, 0($s2)					# s4 = board size
	
	move	$t0, $s0
	addi	$t1, $s4, -1
	mul		$t1, $t1, $s4				# t1 = n(n-1)
	div		$t0, $t0, 4
	addi	$t0, $t0, 1					# get position on board
	
	slt		$t2, $t1, $t0				# if t1 < curr loc, in last row 
	bne		$t2, $zero, check_up_tot	# always check total for last row
	
	div		$s0, $s0, 4					# get position on board
	add		$s0, $s0, $s4				# go up down level
	mul		$s0, $s0, 4					# get mem loc for array
	add		$s1, $s1, $s0				# go to position
	lw		$s2, 0($s1)					# s2 = bottom num
	slt		$t0, $s2, $s3				# if num bot < 10, not a clue
	beq		$t0, $zero, check_up_tot

att_sol_cont:
	jal		find_empty					# if no empties exist, cannot solve
	
attempt_solve_return:
	lw		$ra, 20($sp)
	lw		$s4, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 28
	jr		$ra
	
check_acr_tot:
	jal		check_equal_acr
	beq		$v0, $zero, att_sol_chk_bot	# check if bottom is block/clue
	j		att_solve_loop
	
check_up_tot:
	jal		check_equal_up
	beq		$v0, $zero, att_sol_cont	# if it is equal, find next empty
	j		att_solve_loop
	
att_solve_impos:
	li		$v0, 1
	li		$v1, 1
	j		attempt_solve_return
	
#
# Calls the undo function to turn current value to 0 and go to previous cell
#
undo_caller:
	move	$t0, $zero
	sw		$t0, 0($s1)					# make current num 0
	
	jal		find_prev_empty
	bne		$v0, $zero, att_solve_impos	# if we are at - 
	j		att_solve_loop

#
# finds the previous empty cell, if at 0 in the array then impossible solution
#	
find_prev_empty:
	addi	$sp, $sp, -24
	sw		$ra, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	move	$s0, $a0
	addi	$s0, $s0, -4
	
	beq		$s0, $zero, imposs_sol
	
	la		$s1, board					# s1 = board array
	add		$s1, $s1, $s0
	lw		$s2, 0($s1)					# s2 = prev cell
	li		$s3, 10
	
prev_empty_loop:
	slt		$t0, $s2, $s3				# if prev cell < 10, cell found
	bne		$t0, $zero, prev_found
	
	addi	$s0, $s0, -4				# go back previous cell
	
	beq		$s0, $zero, imposs_sol		# if at pos 0, no cell found
	
	la		$s1, board					# s1 = board array
	add		$s1, $s1, $s0
	lw		$s2, 0($s1)					# s2 = prev cell
	j		prev_empty_loop
	
imposs_sol:
	li		$v0, 1
	j		prev_empty_ret
	
prev_found:
	move	$a0, $s0
	move	$v0, $zero

prev_empty_ret:
	lw		$ra, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 24
	jr		$ra
	
#
# Check if the placement of number is valid
#	
is_valid:
	addi	$sp, $sp, -32
	sw		$ra, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	move	$s0, $a0
	la		$s1, board					# s1 = board addr
	la		$s2, board_size				# s2 = board size addr
	add		$s1, $s1, $s0
	lw		$s3, 0($s1)					# s3 = current number
	lw		$s4, 0($s2)					# s4 = board size
	addi	$s1, $s1, -4
	lw		$s5, 0($s1)					# s5 = prev number
	li		$t6, 10
	
valid_chk_acr:							
	slt		$t0, $s5, $t6				# if num < 10, not a clue
	beq		$t0, $zero, valid_chk_num	
	
	addi	$s1, $s1, -4
	lw		$s5, 0($s1)
	
	j		valid_chk_acr
	
valid_chk_num:
	div		$s5, $s5, 100
	slt		$t0, $s3, $s5				# if num < clue then continue
	beq		$t0, $zero, valid_false
	
	move	$s5, $zero
	la		$s1, board					# s1 = board array
	la		$s2, board_size				# s2 = board size
	div		$s0, $s0, 4
	sub		$s0, $s0, $s4				
	mul		$s0, $s0, 4					# get upper number
	add		$s1, $s1, $s0
	lw		$s5, 0($s1)
	
valid_chk_up:
	slt		$t0, $s5, $t6				#if num < 10, not a clue
	beq		$t0, $zero, valid_cont
	
	la		$s1, board
	div		$s0, $s0, 4
	sub		$s0, $s0, $s4
	mul		$s0, $s0, 4
	add		$s1, $s1, $s0
	lw		$s5, 0($s1)
	
	j		valid_chk_up
	
valid_cont:
	rem		$s5, $s5, 100
	slt		$t0, $s3, $s5				# if num < clue then continue
	beq		$t0, $zero, valid_false
	
	jal		dup_check
	bne		$v0, $zero, valid_false
	
valid_return:
	
	lw		$ra, 24($sp)
	lw		$s5, 20($sp)
	lw		$s4, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 32
	jr		$ra
	
valid_false:
	li		$v0, 1
	j		valid_return

#
# Check if row is equal to clue
#
check_equal_acr:
	addi	$sp, $sp, -32
	sw		$ra, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	move	$s0, $a0
	la		$s1, board					# s1 = board array
	la		$s2, board_size				# s2 = board size
	add		$s1, $s1, $s0
	lw		$s3, 0($s1)					# s3 = current number
	lw		$s4, 0($s2)					# s4 = board size
	add		$s5, $s5, $s3				# s5 = current total
	li		$t6, 10
	
	div		$s0, $s0, 4
	rem		$t0, $s0, $s4				# left wall check
	mul		$s0, $s0, 4
	
	beq		$t0, $zero, check_equal_done	# if at left wall, check total
	
chk_eq_acr_loop:

	addi	$s0, $s0, -4
	addi	$s1, $s1, -4
	lw		$s3, 0($s1)
	
	slt		$t0, $s3, $t6				# if num not < 10, its a clue
	beq		$t0, $zero, chk_eq_acr

	add		$s5, $s5, $s3				# add current num to total
	
	div		$s0, $s0, 4
	rem		$t0, $s0, $s4				# left wall check
	mul		$s0, $s0, 4
	
	beq		$t0, $zero, inval_wall		# if at left wall, check total
	j		chk_eq_acr_loop				# continue loop
	
chk_eq_acr:
	
	div		$s3, $s3, 100
	bne		$s5, $s3, not_equal_return	# if total != clue then end
	j		check_equal_done			# otherwise, end true
	
#
# Check if num is equal up
#
check_equal_up:
	addi	$sp, $sp, -32
	sw		$ra, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)

	move	$s0, $a0
	la		$s1, board					# s1 = board array
	la		$s2, board_size				# s2 = board size
	add		$s1, $s1, $s0
	lw		$s3, 0($s1)					# s3 = current number
	lw		$s4, 0($s2)					# s4 = board size
	add		$s5, $s5, $s3				# s5 = current total
	
	div		$s0, $s0, 4
	slt		$t0, $s0, $s4				# if curr loc < board size, cant go up
	bne		$t0, $zero, check_equal_done
	
chk_eq_up_loop:
	sub		$s0, $s0, $s4				# go up on the board
	mul		$s0, $s0, 4					# mult by 4 to get mem loc
	la		$s1, board					# reset board loc
	add		$s1, $s1, $s0				# go to new loc
	lw		$s3, 0($s1)					# get current number
	
	slt		$t0, $s3, $t6				# if current num < 10, not a clue
	beq		$t0, $zero, check_up_equal
	
	add		$s5, $s5, $s3				# s5 = current total
	
	div		$s0, $s0, 4
	slt		$t0, $s0, $s4				# if curr loc < board size, inval board
	bne		$t0, $zero, inval_wall
	
	j		chk_eq_up_loop				# continue adding up
	
check_up_equal:
	rem		$s3, $s3, 100
	bne		$s5, $s3, not_equal_return	# if total != clue, return false
	
check_equal_done:
	move	$v0, $zero					# run is equal to clues, return
	move	$v1, $zero
	j		check_equal_return
	
inval_wall:
	li		$v0, 1
	li		$v1, 1						# impossible solution, return
	j		check_equal_return
	
not_equal_return:
	li		$v0, 1						# not equal to clues, return
	move	$v1, $zero
	
check_equal_return:
	lw		$ra, 24($sp)
	lw		$s5, 20($sp)
	lw		$s4, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 32
	jr		$ra		
	
#
# Checks for duplicates on a run, if one exists either up or down increment num
#
dup_check:
	addi	$sp, $sp, -40
	sw		$ra, 32($sp)
	sw		$s7, 28($sp)
	sw		$s6, 24($sp)
	sw		$s5, 20($sp)
	sw		$s4, 16($sp)
	sw		$s3, 12($sp)
	sw		$s2, 8($sp)
	sw		$s1, 4($sp)
	sw		$s0, 0($sp)
	
	move	$s0, $a0
	move	$s5, $zero
	la		$s1, board					# s1 = board array
	la		$s2, board_size				# s2 = board size
	add		$s1, $s1, $s0
	
	lw		$s3, 0($s1)					# s3 = current number
	lw		$s4, 0($s2)					# s4 = board size
	add		$s5, $s5, $s3				# s5 = duplicate num to find
	li		$s6, 10
	
	div		$s0, $s0, 4
	rem		$t0, $s0, $s4				# left wall check
	mul		$s0, $s0, 4
	
	beq		$t0, $zero, dup_chk_up		# if at left wall, check total
	
dup_chk_acr_loop:

	addi	$s1, $s1, -4				# go left 1 cell
	addi	$s0, $s0, -4				
	lw		$s3, 0($s1)					# get current number
	
	beq		$s5, $s3, dup_chk_fail
	
	slt		$t0, $s3, $s6				# if current num < 10, not a clue
	beq		$t0, $zero, dup_chk_up
	
	div		$s0, $s0, 4
	rem		$t2, $s0, $s4
	beq		$t2, $zero, dup_chk_up
	mul		$s0, $s0, 4
	
	j		dup_chk_acr_loop			# continue checking
	
dup_chk_up:
	move	$s5, $zero					# reset s5
	move	$s0, $a0
	la		$s1, board					# s1 = board array
	la		$s2, board_size				# s2 = board size
	add		$s1, $s1, $s0
	lw		$s3, 0($s1)					# s3 = current number
	lw		$s4, 0($s2)					# s4 = board size
	add		$s5, $s5, $s3				# s5 = current total
	
	div		$s0, $s0, 4
	slt		$t0, $s0, $s4				# if curr loc < board size, cant go up
	bne		$t0, $zero, dup_chk_done

dup_chk_up_loop:
	sub		$s0, $s0, $s4				# go up on the board
	mul		$s0, $s0, 4					# mult by 4 to get mem loc
	la		$s1, board					# reset board loc
	add		$s1, $s1, $s0				# go to new loc
	lw		$s3, 0($s1)					# get current number
	
	slt		$t0, $s3, $s6				# if current num < 10, not a clue
	beq		$t0, $zero, dup_chk_done
	
	beq		$s5, $s3, dup_chk_fail
	
	div		$s0, $s0, 4
	slt		$t0, $s0, $s4				# if curr loc < board size, inval board
	bne		$t0, $zero, dup_chk_done
	
	j		dup_chk_up_loop				# continue checking

dup_chk_done:
	move	$v0, $zero					# no duplicates found
	j		dup_chk_return
	
dup_chk_fail:
	li		$v0, 1
	
dup_chk_return:
	lw		$ra, 32($sp)
	lw		$s7, 28($sp)
	lw		$s6, 24($sp)
	lw		$s5, 20($sp)
	lw		$s4, 16($sp)
	lw		$s3, 12($sp)
	lw		$s2, 8($sp)
	lw		$s1, 4($sp)
	lw		$s0, 0($sp)
	addi	$sp, $sp, 40
	jr		$ra		
