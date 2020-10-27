# 320x240, 1024 bytes/row, 2 bytes per pixel: DE1-SoC, DE2, DE2-115
.equ WIDTH, 320
.equ HEIGHT, 240
.equ LOG2_BYTES_PER_ROW, 10
.equ LOG2_BYTES_PER_PIXEL, 1
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
.equ ADDR_RNG, 0xff11a0

.global _start
_start:
	movia sp, 0x800000	# Initial stack pointer
    movia r4, 0x0	# Some colour value
    mov r17, r0			# Some character value
	

 	movia r2,ADDR_RNG
  	ldwio r3,(r2)
	call FillColour		# Fill screen with a colour

	
Loop:	
	movi r2, 10
	movi r3, 3
	movi r4, 1
	movi r5, 1
	
	call DrawBall
    br Loop

#r2=ballX r3=ballY r4=deltaX r5=deltaY
DrawBall:
  movui r6,0xffff  /* White pixel */
  movi r10, 320
  movi r11, 240
CalcBallPos:
  movia r7,PIXBUF
  mov r8, r2
  muli r8, r8, 2
  mov r9, r3
  muli r9, r9, 1024
  
  add r7, r7, r8
  add r7, r7, r9
  
  sthio r6,0(r7) /* pixel (4,1) is x*2 + y*1024 so (8 + 1024 = 1032) */
  
  add r2, r2, r4
  add r3, r3, r5
  
  bge r2, r10, BallXOverflow
  ble r2, r0, BallXUnderflow
  
  bge r3, r11, BallYOverflow
  ble r3, r0, BallYUnderflow

  
  br CalcBallPos
BallXOverflow:
  movi r4, -1
  br CalcBallPos
BallXUnderflow:
  movi r4, 1
  br CalcBallPos
BallYOverflow:
  movi r5, -1
  br CalcBallPos
BallYUnderflow:
  movi r5, 1
  br CalcBallPos
	
CheckMovement:
	

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
