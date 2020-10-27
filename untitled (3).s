.global _start
	
	# 320x240, 1024 bytes/row, 2 bytes per pixel: DE1-SoC, DE2, DE2-115
.equ WIDTH, 320
.equ HEIGHT, 240
.equ LOG2_BYTES_PER_ROW, 10
.equ LOG2_BYTES_PER_PIXEL, 1
RAN_NUMS: .word 1,2,3
.equ RAN_INDEX, 0
# 160x120, 512 bytes/row, 2 bytes per pixel: DE10-Lite
#.equ WIDTH, 160
#.equ HEIGHT, 120
#.equ LOG2_BYTES_PER_ROW, 9
#.equ LOG2_BYTES_PER_PIXEL, 1
# 128 bytes/row, 1 byte per pixel: DE0
#.equ WIDTH, 80
#.equ HEIGHT, 60
#.equ LOG2_BYTES_PER_ROW, 7
#.equ LOG2_BYTES_PER_PIXEL, 0

.equ PIXBUF, 0x08000000	# Pixel buffer. Same on all boards.

.global _start
_start:
	movia sp, 0x800000	# Initial stack pointer
    movia r4, 0x0	# Some colour value
    mov r17, r0			# Some character value
	
	call FillColour		# Fill screen with a colour
	
	movi r2, 3 #inital xValue for ball
	movi r3, 7#inital yValue for ball
	movi r4, 1#inital deltaX value for ball
	movi r5, 1#inital deltaY value for ball

#main program loop
Loop:	
	call DrawBall
	movia r9,10000 /* set starting point for delay counter */

DELAY:
	subi r9,r9,1       # subtract 1 from delay
	bne r9,r0, DELAY   # continue subtracting if delay has not elapsed
    br Loop

#r2=ballX r3=ballY r4=deltaX r5=deltaY
DrawBall:
  movui r6,0xffff  /* White pixel */
  movi r10, 320#max width
  movi r11, 240#max height
CalcBallPos:
  movia r7,PIXBUF #pixel buffer address
  mov r8, r2
  muli r8, r8, 2 #calculate the x-offset from PIXBUF
  mov r9, r3
  muli r9, r9, 1024 #calculate the y-offset from PXBUF
  
  add r7, r7, r8
  add r7, r7, r9 #add the offsets to find the final address
  
  sthio r6,0(r7) /* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */
  
  add r2, r2, r4 #add the deltaX/Y's 
  add r3, r3, r5
  
  bge r2, r10, BallXOverflow#Check for overflow/underflow incase the program tries to draw out of screen.
  ble r2, r0, BallXUnderflow
  
  bge r3, r11, BallYOverflow
  ble r3, r0, BallYUnderflow

  
  ret
BallXOverflow:
  movi r4, -1
  ret
BallXUnderflow:
  movi r4, 1
  ret
BallYOverflow:
  movi r5, -1
  ret
BallYUnderflow:
  movi r5, 1
  ret
	
CheckMovement:

#r2: return of ran number
GenRanNum:
  movia r3, RAN_NUMS
  movia r4, RAN_INDEX
  movi r5, 2
GRN_If:
  blt r4, r5, GRN_ELSE
GRN_THEN:
  movi r4, 0
GRN_ELSE:
  muli r4, r4, 4
  add r3, r3, r4
  ldw r2, 0(r3)
  
  movia r4, RAN_INDEX
  addi r4, r4, 1
  #stw RAN_INDEX, r4
  ret
  
	

# r4: colour
FillColour:
	subi sp, sp, 16
    stw r16, 0(sp)		# Save some registers
    stw r17, 4(sp)
    stw r18, 8(sp)
    stw ra, 12(sp)
    
    mov r18, r4
    
    # Two loops to draw each pixel
    movi r16, WIDTH-1
    1:	movi r17, HEIGHT-1
        2:  mov r4, r16
            mov r5, r17
            mov r6, r18
            call WritePixel		# Draw one pixel
            subi r17, r17, 1
            bge r17, r0, 2b
        subi r16, r16, 1
        bge r16, r0, 1b
    
    ldw ra, 12(sp)
	ldw r18, 8(sp)
    ldw r17, 4(sp)
    ldw r16, 0(sp)    
    addi sp, sp, 16
    ret

# r4: col (x)
# r5: row (y)
# r6: colour value
WritePixel:
	movi r2, LOG2_BYTES_PER_ROW		# log2(bytes per row)
    movi r3, LOG2_BYTES_PER_PIXEL	# log2(bytes per pixel)
    
    sll r5, r5, r2
    sll r4, r4, r3
    add r5, r5, r4
    movia r4, PIXBUF
    add r5, r5, r4
    
    bne r3, r0, 1f		# 8bpp or 16bpp?
  	stbio r6, 0(r5)		# Write 8-bit pixel
    ret
    
1:	sthio r6, 0(r5)		# Write 16-bit pixel
	ret
	

