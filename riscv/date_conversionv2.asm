.data
infile: .string "./arko_projekt/infile.txt"
outfile: .string "./arko_projekt/outfile2.txt"
prompt: .string  "Choose desired date format:\n1: dd.mm.yy\n2: dd.mm.yyyy\n3: mm/dd/yy\n4: mm/dd/yyyy\n5: yy-mm-dd\n6: yyyy-mm-dd\n"
inputreadbuf: .space 512
outputwritebuf: .space 512
inputbuf: .space 11 #buffer for collecting user input, reused when formatting dates
managebuf: .space 11 #buffer to store formatted date, output buffer
current_char: .space 2
.text
	#s0 - bytes in outpur buffer
	#s1 - buffer used for date conversion
	#s2 - dash character
	#s3 - period character
	#s4 - slash character
	#s5 - 2 character
	#s6 - 0 character
	#s7 - 9 character
	#t2 - inputreadbuf register
	#s10 - read file descriptor
	#s11 - write file descriptor
	#t0 - unique date format identifier (. / - )
	#t1 - current state
	#s8 - desired mode
	#t3 - current char
	#t4 - bytes in input buffer
	#t5 - temp variable
	#t6 - buffer used for temporary data saving and pushing converted date to output
	#0(sp) - current size of managebuf
	addi sp, sp, -4
	li s0, 0
	li t4, 0
	li s2, '-'
	li s3, '.'
	li s4, '/'
	li s5, '2'
	li s6, '0' 
	li s7, '9' 
	la t2, inputreadbuf
	la s9, outputwritebuf
	
	la s1, inputbuf
	la t6, managebuf
	
	#display prompt
	li a7, 4
	la a0, prompt
	ecall
	
	#collect user input
	li a7, 8
	la a0, inputbuf
	mv s8, a0
	li a1, 2
	ecall
	
	#load user mode into s8
	lbu s8, 0(s8)
	
	#open read file
	la a0, infile
	li a1, 0
	li a7, 1024
	ecall
	mv s10, a0
	
	#open write file
	la a0, outfile
	li a1, 1
	li a7, 1024
	ecall
	mv s11, a0
	
	
	la t1, state0
loop:
	jal getc
	jr t1
	
stateNegative: # state when the last character was a special one(dash period slash or number) preventing detection of a new date
	sb t3, 0(t6)
	li a2, 1
	sw a2, 0(sp) 
	b putbuf
	#jal putc
	#j check_if_last_char_was_special

		
state0: # __________
	sb t3, 0(t6)	#if number store byte
	li a2, 1
	sw a2, 0(sp) 
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state1	#change state to 1
	j loop		#come back to loop

	
state1:	# 0_________
	sb t3, 1(t6)	#if number store byte
	li a2, 2
	sw a2, 0(sp) 

	addi sp, sp, 4
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	
	
	la t1, state2
	j loop

state2: # 00________
	sb t3, 2(t6)
	li a2, 3
	sw a2, 0(sp) 
	#check if current char is equal to / . or -
	beq t3, s2, state2_mid
	
	beq t3, s3, state2_mid
	
	beq t3, s4, state2_mid
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	
	la t1, state4
	j loop



state2_mid: # 00?_______
	la t1, state3
	mv t0, t3 #save unique to date character
	j loop

	
state3: # 00?_______
	sb t3, 3(t6)	#if number store byte
	li a2, 4
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	
	
	la t1, state5
	j loop
	
state4: # 000_______
	sb t3, 3(t6)	#if number store byte
	li a2, 4
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
		
	la t1, state6
	j loop
	
state5: # 00?0______
	sb t3, 4(t6)	
	li a2, 5
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	
	
	la t1, state7
	j loop
	
state6: # 0000______
	sb t3, 4(t6)	
	li a2, 5
	sw a2, 0(sp) 
	
	li t5, 45
	mv t0, t5
	bne t3, t5, putbuf
	la t1, state8
	j loop
	
state7: #00?00______
	sb t3, 5(t6)	
	li a2, 6
	sw a2, 0(sp) 
	
	bne t3, t0, putbuf #check if second unique character is the same as the first
	la t1, state9
	j loop
		
state8: #0000-______
	sb t3, 5(t6)	
	li a2, 6
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state10
	j loop
	
state9: #00?00?____
	sb t3, 6(t6)	
	li a2, 7
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state11
	j loop
	
state10: #0000-0____
	sb t3, 6(t6)	
	li a2, 7
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state12
	j loop
	
state11: #00?00?0___
	sb t3, 7(t6)	
	li a2, 8
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state13
	j loop
	
state12: #0000-00___
	sb t3, 7(t6)	
	li a2, 8
	sw a2, 0(sp) 
	
	bne t3, t0, putbuf
	la t1, state14
	j loop
	
state13: #00?00?00__
	sb t3, 8(t6)	
	li a2, 9
	sw a2, 0(sp) 
	

	beq t3, s2, putbuf
	
	beq t3, s3, putbuf
	
	beq t3, s4, putbuf
	
	blt t3, s6, twodigityear_convert_to_ddmmyyyy #check if number
	bgt t3, s7, twodigityear_convert_to_ddmmyyyy
	la t1, state15
	j loop
	
state14: #0000-00-__
	sb t3, 8(t6)	
	li a2, 9
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state16
	j loop
	
state15: #00?00?000_
	sb t3, 9(t6)	
	li a2, 10
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state17
	j loop
state16: #0000-00-00
	sb t3, 9(t6)	
	li a2, 10
	sw a2, 0(sp) 
	
	blt t3, s6, putbuf #check if number
	bgt t3, s7, putbuf
	la t1, state17
	j loop
	
state17: #final state, we have the full date and were checking if the next character is special
	sb t3, 10(t6)	
	li a2, 11
	sw a2, 0(sp) 
	
	beq t3, s2, putbuf
	
	beq t3, s3, putbuf

	beq t3, s4, putbuf
	
	blt t3, s6, fourdigityear_convert_to_ddmmyyyy #check if number
	bgt t3, s7, fourdigityear_convert_to_ddmmyyyy
	j putbuf

	
	
twodigityear_convert_to_ddmmyyyy:
	#check two digit year date type and normalize to ddmmyyyy accordingly, t0 is the saved special character (- / .)

	beq t0, s3, normalize_from_ddmmyy
	
	beq t0, s4, normalize_from_mmddyy
	
	beq t0, s2, normalize_from_yymmdd

fourdigityear_convert_to_ddmmyyyy:
	#check four digit year date type and normalize to ddmmyyyy accordingly, t0 is the saved special character (- / .)46
	beq t0, s3, normalize_from_ddmmyyyy
	
	beq t0, s4, normalize_from_mmddyyyy
	
	beq t0, s2, normalize_from_yyyymmdd
	
normalize_from_yymmdd:
	lbu t5, 0(t6)
	sb t5, 6(s1)
	
	lbu t5, 1(t6)
	sb t5, 7(s1)
	
	lbu t5, 3(t6)
	sb t5, 2(s1)
	
	lbu t5, 4(t6)
	sb t5, 3(s1)
	
	lbu t5, 6(t6)
	sb t5, 0(s1)
	
	lbu t5, 7(t6)
	sb t5, 1(s1)
	
	sb s5, 4(s1)
	sb s6, 5(s1)
	
	sb t3, 8(t6)
	j convert_to_output
	
	
normalize_from_yyyymmdd:
	lbu t5, 0(t6)
	sb t5, 4(s1)
	
	lbu t5, 1(t6)
	sb t5, 5(s1)
	
	lbu t5, 2(t6)
	sb t5, 6(s1)
	
	lbu t5, 3(t6)
	sb t5, 7(s1)
	
	lbu t5, 5(t6)
	sb t5, 2(s1)
	
	lbu t5, 6(t6)
	sb t5, 3(s1)
	
	lbu t5, 8(t6)
	sb t5, 0(s1)
	
	lbu t5, 9(t6)
	sb t5, 1(s1)
	
	sb t3, 10(t6)
	j convert_to_output
	
normalize_from_ddmmyy:
	lbu t5, 0(t6)
	sb t5, 0(s1)
	
	lbu t5, 1(t6)
	sb t5, 1(s1)
	
	lbu t5, 3(t6)
	sb t5, 2(s1)
	
	lbu t5, 4(t6)
	sb t5, 3(s1)
	
	lbu t5, 6(t6)
	sb t5, 6(s1)
	
	lbu t5, 7(t6)
	sb t5, 7(s1)
	
	sb s5, 4(s1)
	sb s6, 5(s1)
	
	sb t3, 8(t6)
	j convert_to_output
	
normalize_from_ddmmyyyy:
	lbu t5, 0(t6)
	sb t5, 0(s1)
	
	lbu t5, 1(t6)
	sb t5, 1(s1)
	
	lbu t5, 3(t6)
	sb t5, 2(s1)
	
	lbu t5, 4(t6)
	sb t5, 3(s1)
	
	lbu t5, 6(t6)
	sb t5, 4(s1)
	
	lbu t5, 7(t6)
	sb t5, 5(s1)
	
	lbu t5, 8(t6)
	sb t5, 6(s1)
	
	lbu t5, 9(t6)
	sb t5, 7(s1)
	
	sb t3, 10(t6)
	j convert_to_output
	
normalize_from_mmddyy:
	lbu t5, 0(t6)
	sb t5, 2(s1)
	
	lbu t5, 1(t6)
	sb t5, 3(s1)
	
	lbu t5, 3(t6)
	sb t5, 0(s1)
	
	lbu t5, 4(t6)
	sb t5, 1(s1)
	
	lbu t5, 6(t6)
	sb t5, 6(s1)
	
	lbu t5, 7(t6)
	sb t5, 7(s1)
	

	sb s5, 4(s1)
	sb s6, 5(s1)
	
	sb t3, 8(t6)
	j convert_to_output
	
normalize_from_mmddyyyy:
	lbu t5, 0(t6)
	sb t5, 2(s1)
	
	lbu t5, 1(t6)
	sb t5, 3(s1)
	
	lbu t5, 3(t6)
	sb t5, 0(s1)
	
	lbu t5, 4(t6)
	sb t5, 1(s1)
	
	lbu t5, 6(t6)
	sb t5, 4(s1)
	
	lbu t5, 7(t6)
	sb t5, 5(s1)
	
	lbu t5, 8(t6)
	sb t5, 6(s1)
	
	lbu t5, 9(t6)
	sb t5, 7(s1)
	
	sb t3, 10(t6)
	j convert_to_output

convert_to_output:
	#s8 is the desired mode
	#load chars '1' - '6' to s1-s6
	li t5, '1'
	beq s8, t5, convert_to_dmyy
	
	li t5, '2'
	beq s8, t5, convert_to_dmyyyy
	
	li t5, '3'
	beq s8, t5, convert_to_mdyy
	
	li t5, '4'
	beq s8, t5, convert_to_mdyyyy
	
	li t5, '5'
	beq s8, t5, convert_to_yymd
	
	li t5, '6'
	beq s8, t5, convert_to_yyyymd
	
	#if mode is invalid exit the program

	b exit
	
convert_to_dmyyyy:
	#load first byte of the buffer(day) of t6 and store it into the first position of the output buffer t6
	lbu t5, 0(s1)
	sb t5, 0(t6)
	
	#load second byte of t6 (day) and store it to second position of t6
	lbu t5, 1(s1)
	sb t5, 1(t6)
	
	# load third byte of t6 (month) and store ir to fourth position of t6
	lbu t5, 2(s1)
	sb t5, 3(t6)
	
	#load fourth byte of t6 (month) and store it to fifth position of t6
	lbu t5, 3(s1)
	sb t5, 4(t6)
	
	#load fifth byte of t6 (year) and store it to seventh position of t6
	lbu t5, 4(s1)
	sb t5, 6(t6)

	#load sixth byte of t6 (year) and store it to eighth position of t6
	lbu t5, 5(s1)
	sb t5, 7(t6)
	
	#load seventh byte of t6 (year) and store it to ninth position of t6
	lbu t5, 6(s1)
	sb t5, 8(t6)
	
	#load eighth byte of t6 (year) and store it to tenth position of t6
	lbu t5, 7(s1)
	sb t5, 9(t6)
	
	#load the period character and storeit to third and sixth position of t6
	sb s3, 2(t6)
	sb s3, 5(t6)
	
	sb t3, 10(t6)
	#load 10 (length of the date) into a2 and jump to function which writes from buffer t6 to outfile
	li a2, 11
	j putbuf

	
convert_to_dmyy:
	lbu t5, 0(s1)
	sb t5, 0(t6)
	
	lbu t5, 1(s1)
	sb t5, 1(t6)
	
	lbu t5, 2(s1)
	sb t5, 3(t6)
	
	lbu t5, 3(s1)
	sb t5, 4(t6)
	

	lbu t5, 6(s1)
	sb t5, 6(t6)
	
	lbu t5, 7(s1)
	sb t5, 7(t6)
	

	sb s3, 2(t6)
	sb s3, 5(t6)
	
	sb t3, 8(t6)
	li a2, 9
	
	j putbuf

convert_to_mdyy:
	lbu t5, 0(s1)
	sb t5, 3(t6)
	
	lbu t5, 1(s1)
	sb t5, 4(t6)
	
	lbu t5, 2(s1)
	sb t5, 0(t6)
	
	lbu t5, 3(s1)
	sb t5, 1(t6)
	

	lbu t5, 6(s1)
	sb t5, 6(t6)
	
	lbu t5, 7(s1)
	sb t5, 7(t6)
	

	sb s4, 2(t6)
	sb s4, 5(t6)
	

	sb t3, 8(t6)
	li a2, 9
	
	j putbuf
	
convert_to_mdyyyy:
	lbu t5, 0(s1)
	sb t5, 3(t6)
	
	lbu t5, 1(s1)
	sb t5, 4(t6)
	
	lbu t5, 2(s1)
	sb t5, 0(t6)
	
	lbu t5, 3(s1)
	sb t5, 1(t6)
	
	lbu t5, 4(s1)
	sb t5, 6(t6)
	
	lbu t5, 5(s1)
	sb t5, 7(t6)

	lbu t5, 6(s1)
	sb t5, 8(t6)
	
	lbu t5, 7(s1)
	sb t5, 9(t6)
	
	sb s4, 2(t6)
	sb s4, 5(t6)
	

	sb t3, 10(t6)
	li a2, 11
	
	j putbuf
	
convert_to_yymd:
	lbu t5, 0(s1)
	sb t5, 6(t6)
	
	lbu t5, 1(s1)
	sb t5, 7(t6)
	
	lbu t5, 2(s1)
	sb t5, 3(t6)
	
	lbu t5, 3(s1)
	sb t5, 4(t6)
	

	lbu t5, 6(s1)
	sb t5, 0(t6)
	
	lbu t5, 7(s1)
	sb t5, 1(t6)
	
	sb s2, 2(t6)
	sb s2, 5(t6)
	

	sb t3, 8(t6)
	li a2, 9
	
	j putbuf
	
convert_to_yyyymd:
	lbu t5, 0(s1)
	sb t5, 8(t6)
	
	lbu t5, 1(s1)
	sb t5, 9(t6)
	
	lbu t5, 2(s1)
	sb t5, 5(t6)
	
	lbu t5, 3(s1)
	sb t5, 6(t6)
	

	lbu t5, 4(s1)
	sb t5, 0(t6)
	
	lbu t5, 5(s1)
	sb t5, 1(t6)

	lbu t5, 6(s1)
	sb t5, 2(t6)
	
	lbu t5, 7(s1)
	sb t5, 3(t6)
	
	sb s2, 4(t6)
	sb s2, 7(t6)
	

	sb t3, 10(t6)
	li a2, 11
	
	j putbuf
	
getc: #get next character from input file
	beqz t4, reset_input_buf
	addi t2, t2, 1

	j ret_from_getc
	
reset_input_buf:
	la t2, inputreadbuf
	li a7, 63
	mv a0, s10
	mv a1, t2
	li a2, 512
	ecall
	mv t4, a0


	mv a5, ra
	jal check_if_finish
	mv ra, a5
	
	

ret_from_getc:
	addi t4, t4, -1
	lbu t3, 0(t2)
	ret 
	
check_if_finish:
	beqz a0, change_state_to_finish
	ret
	
change_state_to_finish:
	la t1, state_finish
	ret

putc: #put last character into output file\
	li a5, 0
	sb t3, 0(s9)
	addi s9, s9, 1
	addi s0, s0, 1
	
	li t5, 512
	beq s0, t5, reset_output_buf
	
	ret

reset_output_buf:
	mv t5, a2
	li a7, 64
	mv a0, s11
	la a1, outputwritebuf
	mv a2, s0
	ecall
	li s0, 0
	la s9, outputwritebuf
	mv a2, t5
	ret
		
putbuf: 
	beq zero, a2, exit
	lbu t3, 0(t6)
	jal putc
	addi t6, t6, 1
	addi a2, a2, -1
	
	bnez a2, putbuf
	la t6, managebuf
	sw zero, 0(sp)
	
	la t5, state_finish
	beq t1, t5, exit
	
check_if_last_char_was_special: # if character was special (/ . -) or a number go to stateNegative, else go to state0
	li t5, 46
	beq t3, t5, go_state_negative
	
	li t5, 47
	beq t3, t5, go_state_negative
	
	li t5, 45
	beq t3, t5, go_state_negative
	
	blt t3, s6, go_state0 #check if number
	bgt t3, s7, go_state0

	
go_state_negative:
	la t1, stateNegative
	j loop

go_state0:
	la t1, state0
	j loop



	
state_finish:
	lw a2, 0(sp)
	#write last line to output buffer
	j putbuf

exit:
	#output buffer to output file
	jal reset_output_buf
	#close read file
	li   a7, 57     
	mv   a0, s10   
  	ecall	
  	
  	#close write file
	li   a7, 57     
	mv   a0, s11
  	ecall	
  	
  	#exit program
	li a0, 1
	li a7, 93
	ecall
