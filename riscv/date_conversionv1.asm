.data
infile: .string "./arko_projekt/infile.txt"
outfile: .string "./arko_projekt/outfile1.txt"
prompt: .string  "Choose desired date format:\n1: dd.mm.yy\n2: dd.mm.yyyy\n3: mm/dd/yy\n4: mm/dd/yyyy\n5: yy-mm-dd\n6: yyyy-mm-dd\n"
filebuf: .space 512 #buffer to contain input file
inputbuf: .space 10 #buffer for collecting user input, reused when formatting dates
managebuf: .space 10 #buffer to store formatted date, output buffer
.text
	#t0 - main buffer with text from file
	#t1 - file descriptor
	#t2 - chosen operating mode
	#t3 - current char
	#t4 - buffer used to store dates converted to chosen format
	#t5 - used to store 0/1 value if date is detected
	#t6 - buffer used to store detected date in ddmmyyyy format
	#s0-s7 - used to detect date

	#display prompt
	li a7, 4
	la a0, prompt
	ecall
	
	#collect user input
	li a7, 8
	la a0, inputbuf
	mv t2, a0
	li a1, 2
	ecall
	
	#load user mode into t2
	lb t2, 0(t2)
	
	#open read file
	la a0, infile
	li a1, 0
	li a7, 1024
	ecall
	mv t1, a0
	 
	#read from file 
	la t0, filebuf
	li a7, 63
	mv a1, t0
	li a2, 512
	ecall
	
	#close file
	li   a7, 57     
	mv   a0, t1   
  	ecall	
	
	
	#open write file
	la a0, outfile
	li a1, 1
	li a7, 1024
	ecall
	mv t1, a0
	
	la t4, managebuf
	
loop:
	li t5, 0
	#check if character is empty
	lb t3, 0(t0)
	beqz t3, exit 
	
	#check for all date formats
	jal check_if_dmyyyy
	bnez t5, convert_to_output
	 
	jal check_if_dmyy
	bnez t5, convert_to_output
	
	jal check_if_mdyyyy
	bnez t5, convert_to_output
	 
	jal check_if_mdyy
	bnez t5, convert_to_output
	
	jal check_if_yyyymd
	bnez t5, convert_to_output
	 
	jal check_if_yymd
	bnez t5, convert_to_output
		
	#store character to buffer
	sb t3, 0(t4)
	
	#increment to the next character
	addi t0, t0, 1

	#change a2 to 1 -> print one character
	li a2, 1
	jal write_from_buf
	j loop
	
	
check_if_dmyyyy:
	#load first five bytes
	lb s1, 0(t0)     
	lb s2, 1(t0)     
	lb s3, 2(t0)    
	lb s4, 3(t0)    
	lb s5, 4(t0)
	
	li s0, 46 #period character
	li s6, 48 #zero character
	li s7, 57 #nine character
	
	
	blt s1, s6, wrong #check if first char is a number
	bgt s1, s7, wrong
	blt s2, s6, wrong #check if second char is a number
	bgt s2, s7, wrong
	bne s3, s0, wrong #check if third char is a period
	blt s4, s6, wrong #check if fourth char is a number
	bgt s4, s7, wrong 
	blt s5, s6, wrong #check if fifth char is a number
	bgt s5, s7, wrong
	
	#store date and month in t6
	la t6, inputbuf
	sb s1, 0(t6)
	sb s2, 1(t6)
	sb s4, 2(t6)
	sb s5, 3(t6)
	
	#load next five bytes
	lb s1, 5(t0)     
	lb s2, 6(t0)     
	lb s3, 7(t0)    
	lb s4, 8(t0)    
	lb s5, 9(t0)
	
	bne s1, s0, wrong #check if period
	blt s2, s6, wrong #check if number
	bgt s2, s7, wrong 
	blt s3, s6, wrong #check if number
	bgt s3, s7, wrong
	blt s4, s6, wrong #check if number
	bgt s4, s7, wrong
	blt s5, s6, wrong #check if number
	bgt s5, s7, wrong
	
	#store year in t6
	sb s2, 4(t6)
	sb s3, 5(t6)
	sb s4, 6(t6)
	sb s5, 7(t6)
	
	#change t5 to 1, meaning a date was detected
	li t5, 1
	#increment main buffer by 10, the length of the date
	addi t0, t0, 10
	#return
	ret
	
check_if_dmyy:
	#load first five bytes
	lb s1, 0(t0)     
	lb s2, 1(t0)     
	lb s3, 2(t0)    
	lb s4, 3(t0)    
	lb s5, 4(t0)
	
	li s0, 46 #period character
	li s6, 48 #zero character
	li s7, 57 #nine character
	
	blt s1, s6, wrong #check if number
	bgt s1, s7, wrong
	blt s2, s6, wrong #check if number
	bgt s2, s7, wrong
	bne s3, s0, wrong #check if period
	blt s4, s6, wrong #check if number
	bgt s4, s7, wrong
	blt s5, s6, wrong #check if number
	bgt s5, s7, wrong
	
	la t6, inputbuf
	#store day and month in t6
	sb s1, 0(t6)
	sb s2, 1(t6)
	sb s4, 2(t6)
	sb s5, 3(t6)
	
	#load last 3 bytes
	lb s1, 5(t0)     
	lb s2, 6(t0)     
	lb s3, 7(t0)    

	
	bne s1, s0, wrong #check if period
	blt s2, s6, wrong #check if number
	bgt s2, s7, wrong
	blt s3, s6, wrong #check if number
	bgt s3, s7, wrong

	li s0, 50 #two character
	
	#store two and zero character, adding prefix 20 to the year
	sb s0, 4(t6)
	sb s6, 5(t6)
	
	#store the last two numbers of the year
	sb s2, 6(t6)
	sb s3, 7(t6)
	
	#change t5 to 1, marking a date has been found
	li t5, 1
	#increment the buffer by 8, the length of the date
	addi t0, t0, 8
	#return
	ret
	
check_if_mdyyyy:
	lb s1, 0(t0)     
	lb s2, 1(t0)     
	lb s3, 2(t0)    
	lb s4, 3(t0)    
	lb s5, 4(t0)
	
	li s0, 47 #slash character
	li s6, 48 #zero character
	li s7, 57 #nine character
	
	blt s1, s6, wrong
	bgt s1, s7, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	bne s3, s0, wrong
	blt s4, s6, wrong
	bgt s4, s7, wrong
	blt s5, s6, wrong
	bgt s5, s7, wrong
	
	la t6, inputbuf
	sb s1, 2(t6)
	sb s2, 3(t6)
	sb s4, 0(t6)
	sb s5, 1(t6)
	
	lb s1, 5(t0)     
	lb s2, 6(t0)     
	lb s3, 7(t0)    
	lb s4, 8(t0)    
	lb s5, 9(t0)
	
	bne s1, s0, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	blt s3, s6, wrong
	bgt s3, s7, wrong
	blt s4, s6, wrong
	bgt s4, s7, wrong
	blt s5, s6, wrong
	bgt s5, s7, wrong
	
	sb s2, 4(t6)
	sb s3, 5(t6)
	sb s4, 6(t6)
	sb s5, 7(t6)
	
	li t5, 1
	addi t0, t0, 10
	ret
	
check_if_mdyy:
	lb s1, 0(t0)     
	lb s2, 1(t0)     
	lb s3, 2(t0)    
	lb s4, 3(t0)    
	lb s5, 4(t0)
	
	li s0, 47 #slash character
	li s6, 48 #zero character
	li s7, 57 #nine character
	
	blt s1, s6, wrong
	bgt s1, s7, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	bne s3, s0, wrong
	blt s4, s6, wrong
	bgt s4, s7, wrong
	blt s5, s6, wrong
	bgt s5, s7, wrong
	
	la t6, inputbuf
	sb s1, 2(t6)
	sb s2, 3(t6)
	sb s4, 0(t6)
	sb s5, 1(t6)
	
	lb s1, 5(t0)     
	lb s2, 6(t0)     
	lb s3, 7(t0)    

	
	bne s1, s0, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	blt s3, s6, wrong
	bgt s3, s7, wrong

	li s0, 50 #two character
	
	sb s0, 4(t6)
	sb s6, 5(t6)
	sb s2, 6(t6)
	sb s3, 7(t6)
	
	li t5, 1
	addi t0, t0, 8
	ret
	
check_if_yyyymd:
	lb s1, 0(t0)     
	lb s2, 1(t0)     
	lb s3, 2(t0)    
	lb s4, 3(t0)    
	lb s5, 4(t0)
	
	li s0, 45 #dash character
	li s6, 48 #zero character
	li s7, 57 #nine character
	
	blt s1, s6, wrong
	bgt s1, s7, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	blt s3, s6, wrong
	bgt s3, s7, wrong
	blt s4, s6, wrong
	bgt s4, s7, wrong
	bne s5, s0, wrong
	
	la t6, inputbuf
	
	sb s1, 4(t6)
	sb s2, 5(t6)
	sb s3, 6(t6)
	sb s4, 7(t6)
	
	lb s1, 5(t0)     
	lb s2, 6(t0)     
	lb s3, 7(t0)    
	lb s4, 8(t0)    
	lb s5, 9(t0)
	
	blt s1, s6, wrong
	bgt s1, s7, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	bne s3, s0, wrong
	blt s4, s6, wrong
	bgt s4, s7, wrong
	blt s5, s6, wrong
	bgt s5, s7, wrong
	
	sb s1, 2(t6)
	sb s2, 3(t6)
	sb s4, 0(t6)
	sb s5, 1(t6)
	
	li t5, 1
	addi t0, t0, 10
	ret
	
check_if_yymd:
	lb s1, 0(t0)     
	lb s2, 1(t0)     
	lb s3, 2(t0)    
	lb s4, 3(t0)    
	lb s5, 4(t0)
	
	li s0, 45 #dash character
	li s6, 48 #zero character
	li s7, 57 #nine character
	
	blt s1, s6, wrong
	bgt s1, s7, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	bne s3, s0, wrong
	blt s4, s6, wrong
	bgt s4, s7, wrong
	blt s5, s6, wrong
	bgt s5, s7, wrong
	
	la t6, inputbuf
	sb s1, 6(t6)
	sb s2, 7(t6)
	sb s4, 2(t6)
	sb s5, 3(t6)
	
	lb s1, 5(t0)     
	lb s2, 6(t0)     
	lb s3, 7(t0)    

	
	bne s1, s0, wrong
	blt s2, s6, wrong
	bgt s2, s7, wrong
	blt s3, s6, wrong
	bgt s3, s7, wrong

	li s0, 50 #two character
	
	sb s0, 4(t6)
	sb s6, 5(t6)
	sb s2, 0(t6)
	sb s3, 1(t6)
	
	li t5, 1
	addi t0, t0, 8
	ret
wrong:
	ret
	
	
convert_to_output:
	#t2 is the desired mode
	#load chars '1' - '6' to s1-s6
	li s1, 49
	li s2, 50
	li s3, 51
	li s4, 52
	li s5, 53
	li s6, 54
	#check user mode and convert accordingly
	beq t2, s1, convert_to_dmyy
	beq t2, s2, convert_to_dmyyyy
	beq t2, s3, convert_to_mdyy
	beq t2, s4, convert_to_mdyyyy
	beq t2, s5, convert_to_yymd
	beq t2, s6, convert_to_yyyymd
	#if mode is invalid exit the program
	b exit

convert_to_mdyyyy:
	lb s1, 0(t6)
	sb s1, 3(t4)
	
	lb s1, 1(t6)
	sb s1, 4(t4)
	
	lb s1, 2(t6)
	sb s1, 0(t4)
	
	lb s1, 3(t6)
	sb s1, 1(t4)
	
	lb s1, 4(t6)
	sb s1, 6(t4)
	
	lb s1, 5(t6)
	sb s1, 7(t4)
	
	lb s1, 6(t6)
	sb s1, 8(t4)
	
	lb s1, 7(t6)
	sb s1, 9(t4)
	
	li s1, 47 #slash character
	sb s1, 2(t4)
	sb s1, 5(t4)
	
	li a2, 10
	jal write_from_buf
	j loop
	
convert_to_mdyy:
	lb s1, 0(t6)
	sb s1, 3(t4)
	
	lb s1, 1(t6)
	sb s1, 4(t4)
	
	lb s1, 2(t6)
	sb s1, 0(t4)
	
	lb s1, 3(t6)
	sb s1, 1(t4)
	
	lb s1, 6(t6)
	sb s1, 6(t4)
	
	lb s1, 7(t6)
	sb s1, 7(t4)
	
	li s1, 47 #slash character
	sb s1, 2(t4)
	sb s1, 5(t4)
	
	li a2, 8
	jal write_from_buf
	j loop
	
convert_to_dmyyyy:
	#load first byte of the buffer(day) of t6 and store it into the first position of the output buffer t4
	lb s1, 0(t6)
	sb s1, 0(t4)
	
	#load second byte of t6 (day) and store it to second position of t4
	lb s1, 1(t6)
	sb s1, 1(t4)
	
	# load third byte of t6 (month) and store ir to fourth position of t4
	lb s1, 2(t6)
	sb s1, 3(t4)
	
	#load fourth byte of t6 (month) and store it to fifth position of t4
	lb s1, 3(t6)
	sb s1, 4(t4)
	
	#load fifth byte of t6 (year) and store it to seventh position of t4
	lb s1, 4(t6)
	sb s1, 6(t4)
	
	#load sixth byte of t6 (year) and store it to eighth position of t4
	lb s1, 5(t6)
	sb s1, 7(t4)
	
	#load seventh byte of t6 (year) and store it to ninth position of t4
	lb s1, 6(t6)
	sb s1, 8(t4)
	
	#load eighth byte of t6 (year) and store it to tenth position of t4
	lb s1, 7(t6)
	sb s1, 9(t4)
	
	#load the period character and storeit to third and sixth position of t4
	li s1, 46 #period character
	sb s1, 2(t4)
	sb s1, 5(t4)
	
	#load 10 (length of the date) into a2 and jump to function which writes from buffer t4 to outfile
	li a2, 10
	jal write_from_buf
	#return to main loop
	j loop
	
convert_to_dmyy:
	#load first byte of the buffer(day) of t6 and store it into the first position of the output buffer t4
	lb s1, 0(t6)
	sb s1, 0(t4)
	
	#load second byte of t6 (day) and store it to second position of t4
	lb s1, 1(t6)
	sb s1, 1(t4)
	
	# load third byte of t6 (month) and store ir to fourth position of t4
	lb s1, 2(t6)
	sb s1, 3(t4)
	
	#load fourth byte of t6 (month) and store it to fifth position of t4
	lb s1, 3(t6)
	sb s1, 4(t4)
	
	#load seventh byte of t6 (third number of the year) and store it to seventh position of t4
	lb s1, 6(t6)
	sb s1, 6(t4)
	
	#load eighth byte of t6 (last number of the year) and store it to eighth position of t4
	lb s1, 7(t6)
	sb s1, 7(t4)
	
	#load period char and load it to third and sixth position of t4
	li s1, 46 #period character
	sb s1, 2(t4)
	sb s1, 5(t4)
	
	#load eight (the length of the date) into a2 and jump to function which writes from buffer t4 to outfile
	li a2, 8
	jal write_from_buf
	#return to main loop
	j loop
	
convert_to_yyyymd:
	lb s1, 0(t6)
	sb s1, 8(t4)
	
	lb s1, 1(t6)
	sb s1, 9(t4)
	
	lb s1, 2(t6)
	sb s1, 5(t4)
	
	lb s1, 3(t6)
	sb s1, 6(t4)
	
	lb s1, 4(t6)
	sb s1, 0(t4)
	
	lb s1, 5(t6)
	sb s1, 1(t4)
	
	lb s1, 6(t6)
	sb s1, 2(t4)
	
	lb s1, 7(t6)
	sb s1, 3(t4)
	
	li s1, 45 #dash character
	sb s1, 4(t4)
	sb s1, 7(t4)
	
	li a2, 10
	jal write_from_buf
	j loop
	
convert_to_yymd:
	lb s1, 0(t6)
	sb s1, 6(t4)
	
	lb s1, 1(t6)
	sb s1, 7(t4)
	
	lb s1, 2(t6)
	sb s1, 3(t4)
	
	lb s1, 3(t6)
	sb s1, 4(t4)
	
	lb s1, 6(t6)
	sb s1, 0(t4)
	
	lb s1, 7(t6)
	sb s1, 1(t4)
	
	li s1, 45 #dash character
	sb s1, 2(t4)
	sb s1, 5(t4)
	
	li a2, 8
	jal write_from_buf
	j loop
	
	
write_from_buf:
	li a7, 64
	mv a0, t1
	mv a1, t4
	ecall
	ret
	
exit:
	#close file
	li   a7, 57     
	mv   a0, t1    
  	ecall

	#exit program
	li a0, 1
	li a7, 93
	ecall
