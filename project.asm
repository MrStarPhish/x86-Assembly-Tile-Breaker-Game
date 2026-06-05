; 24F-0530 // Abdullah Saleem / CS-3E / Phishy 
; COAL Semester Project 

org 0x0100
jmp start

; GENERAL PRINT AND HELPER FUNCTIONS

debugHelper:
	push ax
	push es
	push di 
	mov ax, 0xb800
	mov es, ax 
	mov di, 3202
	mov ah, 0x07
	
	mov word [es:di], 0x072A
	add di, 2
	mov al, byte [si+1]
	add al, 0x30 
	mov word [es:di], ax 
	add di, 2
	mov al, byte [si+2]
	add al, 0x30 
	mov word [es:di], ax 
	
	pop di 
	pop es 
	pop ax 
	ret 

delay: ; to generate some delay
		push CX 
		mov CX, 0xffff
	delayLoop:
		nop
		loop delayLoop
		
		pop CX
		ret 
	

clearscreen:
	
	push es
	push ax
	push cx
	push di 
	
	mov ax, 0xb800 
	mov es, ax 
	mov di, 0
	mov ax, 0x0720 ; spaces
	mov cx, 2000
	
	cld
	rep stosw
	
	pop di
	pop cx 
	pop ax 
	pop es

	ret

putChar:
	; params: x, y, char
	;  [bp+8], [bp+6], [bp+4]
	push bp
	mov bp, sp
	push es
	push ax 
	push bx
	push cx 
	push dx 
	
    mov ax, 0xB800
    mov es, ax

    ; offset = (y*80 + x)*2
    mov ax, [bp+6]          ; ax = y
    mov bl, 80  		    ; bl = 80
    mul bl 					; ax = y*80
	add ax, [bp+8]			; ax = (y*80 + x)
    shl ax, 1				; ax = (y*80 + x) * 2
	add ax, 160				; ax += 160 , to make sure no line is missing 
    
    
    ; print the character
    mov di, ax 				; loading offset
	mov ax, [bp+4]
    mov [es:di], ax      	; write character

	pop dx 
	pop cx 
	pop bx 
	pop ax 
    pop es
	pop bp
    ret 6
	

; DEDICATED PRINT FUNCTIONS

;the function to print a brick 
drawSingleBrick:
	; Param : brickAddr [bp+4]
	
	push bp 
	mov bp, sp 
	
	push ax 
	push bx 
	push cx 
	push dx 
	push si 
	
	mov si, [bp+4] ; pointing SI to that Brick 
	
	mov dl, [si+0] ; x pos 
	mov dh, [si+1] ; y pos  
	mov bl, [si+2] ; width
	
	mov al, [si+3] ; brick status 
	cmp al, 1
	je drawActiveBrick
	
	; Brick is destroyed (status = 0), draw empty spaces
	drawEmptyBrickLoop:
		xor ax, ax 
		mov al, dl
		push ax ; pushed x 
		
		xor ax, ax 
		mov al, dh 
		push ax ; pushed y 
		
		mov ax, 0x0720  ; empty space
		push ax ; pushed char+attr 
		
		call putChar
		
		inc dl 
		dec bl 
		jnz drawEmptyBrickLoop
		jmp skipThisSingleBrick
	
	drawActiveBrick: ; brick is active 
		drawThisSingleBrick:
			xor ax, ax 
			mov al, dl
			push ax ; pushed x 
			
			xor ax, ax 
			mov al, dh 
			push ax ; pushed y 
			
			mov al, byte [brick_char]
			mov ah, byte [si+4] ; attribute
			push ax ; pushed char+attr 
			
			call putChar
			
			inc dl 
			dec bl 
			jnz drawThisSingleBrick

	skipThisSingleBrick:
		pop si 
		pop dx 
		pop cx 
		pop bx 
		pop ax 
		pop bp 
		ret 2
	
	
; the function to print all the bricks one by one 
drawAllBricksIndividually:
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, bricks           ; start of brick array
    mov cx, [brickCount]       ; number of bricks

	drawBricksLoop:
        push si              ; pass pointer to this brick
        call drawSingleBrick
    
		xor ax, ax 
		mov ax, [brickStructureSize] ; next brick 
		add si, ax
        loop drawBricksLoop

	mov word [needToPrintBricks] , 0
	
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	

drawThePaddle:
	push ax
    push bx
    push cx
    push dx
    push si
	
	mov si, paddleData
	mov dl, [si+0] ; x 
	mov dh, [si+1] ; y 
	mov bl, [si+2] ; width 
	
	
	drawThePaddleLoop:
	xor ax, ax 
	mov al, dl
	push ax ; pushed x 
	
	xor ax, ax 
	mov al, dh 
	push ax ; pushed y 
	
	mov al, byte [paddle_char]
	mov ah, byte [si+3] ; attribute
	push ax ; pushed char+attr 
	
	call putChar
	
	inc dl 
	dec bl 
	jnz drawThePaddleLoop 
	
	mov word [needToPrintPaddle] , 0
	
	pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	

removeThePaddle:
	push ax
    push bx
    push cx
    push dx
    push si
	
	mov si, paddleData
	mov dl, [si+0] ; x 
	mov dh, [si+1] ; y 
	mov bl, [si+2] ; width 
	
	
	removeThePaddleLoop:
	xor ax, ax 
	mov al, dl
	push ax ; pushed x 
	
	xor ax, ax 
	mov al, dh 
	push ax ; pushed y 
	
	mov ax, 0x0720 ; blank spaces , removing the paddle 
	push ax ; pushed char+attr 
	
	call putChar
	
	inc dl 
	dec bl 
	jnz removeThePaddleLoop 
	
	pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


drawBall:
    push ax
    push bx
    push cx
    push dx

    mov dl, [ballData + 0] ; x
    mov dh, [ballData + 1] ; y

    xor ax, ax
    mov al, dl ; loading x param 
    push ax

    xor ax, ax ; loading y param 
    mov al, dh
    push ax

    mov al, [ball_char]
    mov ah, [ballData + 4] ; ball atribute 
    push ax

    call putChar

    pop dx
    pop cx
    pop bx
    pop ax
    ret
	

removeBall:
    push ax
    push bx
    push cx
    push dx

    mov dl, [ballData + 0] ; x
    mov dh, [ballData + 1] ; y 

    xor ax, ax ; loading x param 
    mov al, dl
    push ax

    xor ax, ax ; loading y param 
    mov al, dh
    push ax

    mov ax, 0x0720      ; space
    push ax

    call putChar

    pop dx
    pop cx
    pop bx
    pop ax
    ret



showVictory:
	call clearscreen
	
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	mov di, 1830  ; (10*80 + 36)*2
	mov si, victoryText
	mov cx, 8
	mov ah, 0x0A  ; bright green
	
	printVictoryLoop:
		lodsb
		stosw
		loop printVictoryLoop
	
	; Print final score
	mov di, 2144  ; (12*80 + 33)*2
	mov si, finalScoreText
	mov cx, 13
	mov ah, 0x0F
	
	printVictoryScoreLoop:
		lodsb
		stosw
		loop printVictoryScoreLoop
	
	mov ax, [score]
	call printNumber
	call showCenterBoundary
	
	call soundVictory
	
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	; Wait for keypress
	mov ah, 0x00
	int 0x16
	
	ret
	

;--
watermarkText: db 'Phishy 24F-0530'
showWatermark:
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	mov di, 70  ; (10*80 + 36)*2
	mov si, watermarkText
	mov cx, 15
	mov ah, [hudBgColor]
	and ah, 11111000b 
	or ah, 00001010b ; operations performed such that only TEXT Bits are changed, to green 
	
	printWatermarkLoop:
		lodsb
		stosw
		loop printWatermarkLoop
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	ret	
	

	
showGameOver:
	call clearscreen
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 1826  ; (10*80 + 35)*2
	mov si, gameOverText
	mov cx, 10
	mov ah, 0x0C  ; bright red
	
	printGameOverLoop:
		lodsb
		stosw
		loop printGameOverLoop
	
	; Print final score (row 12, col 33)
	mov di, 2142  ; (12*80 + 33)*2
	mov si, finalScoreText
	mov cx, 13
	mov ah, 0x0F
	
	printFinalScoreLoop:
		lodsb
		stosw
		loop printFinalScoreLoop
	
	mov ax, [score]
	call printNumber
	
	call showCenterBoundary
	
	call soundGameOver
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	
	; Wait for keypress
	mov ah, 0x00
	int 0x16
	
	ret
	
showGamePaused:
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 1822  ; (10*80 + 35)*2
	mov si, pauseText
	mov cx, 15
	mov ah, 10000110b  ; atr 
	
	printGamePaused:
		lodsb
		stosw
		loop printGamePaused
		
	mov di, 2140  ; (10*80 + 35)*2
	mov si, pauseCaption
	mov cx, 17
	mov ah, 00000111b  ; atr 
	
	printGamePausedCaption:
		lodsb
		stosw
		loop printGamePausedCaption
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	ret
	
removeGamePaused:
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 1822  ; (10*80 + 35)*2
	mov cx, 15
	mov ax, 0x0720 ; blank space  
	
	removeGamePausedLoop:
		stosw
		loop removeGamePausedLoop 
		
	mov di, 2140  ; (10*80 + 35)*2
	mov cx, 17
	mov ax, 0x0720 ; blank space  
	
	removeGamePausedLoop2:
		stosw
		loop removeGamePausedLoop2
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	
	ret


showCenterBoundary:
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 1488  ; (10*80 + 35)*2
	mov cx, 29
	mov ah, 0000111b  ; atr 
	mov al, '='
	
	showCenterBoundaryLoop1:
		stosw
		loop showCenterBoundaryLoop1
		
	mov di, 2448  ; (10*80 + 35)*2
	mov cx, 29
	mov ah, 00000111b  ; atr 
	mov al, '='
	
	showCenterBoundaryLoop2:
		stosw
		loop showCenterBoundaryLoop2
	
	mov al, '|'
	mov cx, 5
	mov di, 1648
	showCenterBoundaryLoop3:
		mov [es:di], ax 
		mov [es:di + 56], ax 
		add di, 160 
		dec cx 
		jnz showCenterBoundaryLoop3
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	ret
	
removeCenterBoundary:
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 1488  ; (10*80 + 35)*2
	mov cx, 29
	mov ah, 0000111b  ; atr 
	mov al, ' '
	
	removeCenterBoundaryLoop1:
		stosw
		loop removeCenterBoundaryLoop1
		
	mov di, 2448  ; (10*80 + 35)*2
	mov cx, 29
	mov ah, 00000111b  ; atr 
	mov al, ' '
	
	removeCenterBoundaryLoop2:
		stosw
		loop removeCenterBoundaryLoop2
		
	mov al, ' '
	mov cx, 5
	mov di, 1648
	removeCenterBoundaryLoop3:
		mov [es:di], ax 
		mov [es:di + 56], ax 
		add di, 160 
		dec cx 
		jnz removeCenterBoundaryLoop3
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	ret
	

printNumber:
	; ax has the number 
	push ax
	push bx
	push cx
	push dx
	
	mov bx, 10
	xor cx, cx  ; digit counter
	
	
	extractDigits: ; Extract digits (reverse order)
		xor dx, dx
		div bx      ; ax = ax/10, dx = ax%10
		push dx     ; save digit
		inc cx
		test ax, ax
		jnz extractDigits
	
	; Print digits one by one 
	
	;mov ah, 0x0F
	mov ah, [numColor]
	printDigits:
		pop dx
		add dl, '0'
		mov al, dl
		stosw
		loop printDigits
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
setHUDbackgroundColor:
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 0  ; (10*80 + 35)*2
	mov cx, 80
	mov al, 0x20 ; blank spaces 
	mov ah, [hudBgColor] ; HUD BG Color   
	
	setHUDbackgroundColorLoop:
		stosw
		loop setHUDbackgroundColorLoop
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	ret

printScoreAndLives:
	push ax
	push bx
	push cx
	push dx
	push di
	push es
	
	mov ax, 0xb800
	mov es, ax
	
	xor ax, ax 
	mov ah, [hudTextColor] ; set NumColor to Black on White
	mov [numColor], ah
	
	; Print "SCORE: " at top-left (row 0, col 2)
	mov di, 4  ; (0*80 + 2)*2
	mov si, scoreText
	mov cx, 7
	mov ah, [hudTextColor]  ; white on black
	
	printScoreLabel:
		lodsb
		stosw
		loop printScoreLabel
	
	; Print score value (convert number to string)
	mov ax, [score]
	call printNumber  ; prints at current DI position
	
	; Print "LIVES: " at top-right area (row 0, col 65)
	mov di, 130  ; (0*80 + 65)*2
	mov si, livesText
	mov cx, 7
	mov ah, [hudTextColor]
	
	printLivesLabel:
		lodsb
		stosw
		loop printLivesLabel
	
	; Print lives value
	mov ax, [lives]
	call printNumber
	
	mov di, 40  ; (0*80 + 65)*2
	mov si, levelText
	mov cx, 7
	mov ah, [hudTextColor]
	
	printLevelLabel:
		lodsb
		stosw
		loop printLevelLabel
	
	; Print lives value
	mov ax, 10
	sub ax, [ballMoveInterval]
	call printNumber
	
	;reset NumColor to White on Black 
	mov byte [numColor], 00000111b
	
	pop es
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	


showSplashScreen:
	
	push ax
	push di
	push es
	push si
	push cx
	
	mov ax, 0xb800
	mov es, ax
	
	
	mov di, 670  ; (10*80 + 35)*2
	mov si, splashLine
	mov dx, [splashLinesCount] ; N lines in DX 
	mov ah, 0x07  ; white text
	
	nextSplashLine:
	mov cx, [splashLineWidth]  ; no. of chars in each line 
	printCurrentSplashLine:
		lodsb
		stosw
		loop printCurrentSplashLine
		
		add di, 160
		sub di, [splashLineWidth]
		sub di, [splashLineWidth]
		dec dx 
		jnz nextSplashLine
	
	pop cx
	pop si
	pop es
	pop di
	pop ax
	
	
	; Wait for keypress
	mov ah, 0x00
	int 0x16
	
	ret
	

;-------------------------------------------
; INPUT HANDLING 
;-------------------------------------------

processKeyboardInput:
	; key ASCII as parameter at [bp+4]
	push bp 
	mov bp, sp
	push ax
	push bx 
	push cx 
	push dx 
	
	mov ax, [bp+4] 
	
	cmp al, 'd'
	je movePaddleRight
	cmp al, 'D'
	je movePaddleRight 
	cmp al, 'a'
	je movePaddleLeft
	cmp al, 'A'
	je movePaddleLeft 
	
	cmp al, 'p'
	je pauseGameSequence
	cmp al, 'P'
	je pauseGameSequence
	
	cmp al, '0'
	je terminateTheProgramSequence
	
	cmp al, '1'
	je winningSequence
	
	cmp al, '2'
	je gameoverSequence
	
	cmp al, '3'
	je decreaseSpeedSequence
	
	cmp al, '4'
	je increaseSpeedSequence
	
	cmp al, '5'
	je decreasePaddleWidthSequence
	
	cmp al, '6'
	je increasePaddleWidthSequence
	
	cmp al, ' '
	je launchTheBall
	
	; no match 
	jmp endProcessKeyboardInput 
	
	movePaddleRight:
		mov bl, [paddleData]
		inc bl 
		mov dl, bl 
		add dl, [paddleData+2] ; X + width 
		cmp dl, 80
		jg endProcessKeyboardInput  ; if out of bound, then no update 
		
		call removeThePaddle
		mov byte [paddleData], bl 
		mov word [needToPrintPaddle], 1
		jmp endProcessKeyboardInput
	
	movePaddleLeft:	
		mov bl, [paddleData]
		dec bl 
		mov dl, bl 
		cmp dl, 0
		jl endProcessKeyboardInput ; if out of bound, then no movemnet 
		
		call removeThePaddle
		mov byte [paddleData], bl 
		mov word [needToPrintPaddle], 1
		jmp endProcessKeyboardInput
		
	terminateTheProgramSequence:
		mov byte [isGameLoop], 0
		jmp endProcessKeyboardInput
		
	pauseGameSequence:
		call pauseTheGame
		jmp endProcessKeyboardInput
	
	launchTheBall:
		mov byte [ballLaunchStatus], 1 ; ball Launched 
		jmp endProcessKeyboardInput
		
	winningSequence:
		call gameWon
		jmp endProcessKeyboardInput
		
	gameoverSequence:
		call gameLost
		jmp endProcessKeyboardInput
		
	increaseSpeedSequence:
		call increaseSpeed
		jmp endProcessKeyboardInput
	
	decreaseSpeedSequence:
		call decreaseSpeed
		jmp endProcessKeyboardInput
		
	increasePaddleWidthSequence:
		call increasePaddleWidth
		jmp endProcessKeyboardInput
		
	decreasePaddleWidthSequence:
		call decreasePaddleWidth
		jmp endProcessKeyboardInput
	
	endProcessKeyboardInput:
	
	pop dx 
	pop cx 
	pop bx 
	pop ax 
	pop bp 
	ret 2 


;----------
; MECHANICS HANDLING 
;-----------

progressBall:
    
    push ax
	push bx 
	push cx 
	push dx 
	
	call removeBall ; remove old ball
 
    mov al, [ballData + 0] ; load x 
    add al, [ballData + 2] ; increase x according to movement 
	mov [ballData + 0], al

    mov al, [ballData + 1] ; load y 
    add al, [ballData + 3] ; updating y 
    mov [ballData + 1], al

    ; draw ball at new position
	endProgressBall:
	
    call drawBall
	pop dx 
	pop cx 
	pop bx 
	pop ax 
    ret
	
	
	
	
detectCollision:
	
    mov al, [ballData + 0] ; x 

    cmp al, 0
    je hitLeftWall

    cmp al, 79
    je hitRightWall

    mov al, [ballData + 1] ; y
    cmp al, 2
    je hitTopWall

    ; (paddle collision next)
    call checkPaddleCollision
	cmp al, 4
	je endDetectCollision

	call checkTileCollision
	cmp al, 0
	jg hitTopWall  ; hitTopWall procedure if hit a tile 

	mov al, 0 ; no coliision 
	jmp endDetectCollision

	hitLeftWall:
		mov al, 1
		jmp endDetectCollision

	hitRightWall:
		mov al, 2
		jmp endDetectCollision

	hitTopWall:
		mov al, 3
	
	endDetectCollision:
	ret
	

checkPaddleCollision:
	
    ; check y
    mov al, [ballData + 1] ; ball y 
    mov bl, [paddleData + 1]      ; paddle y
    dec bl
    cmp al, bl
    jne noPaddleHit

    ; check x range
    mov al, [ballData + 0]
    mov bl, [paddleData]          ; paddle x
    cmp al, bl
    jb noPaddleHit
    add bl, [paddleData+2]        ; x + width
    cmp al, bl
    ja noPaddleHit

    mov al, 4         ; paddle collision
	call soundPaddleHit
    jmp endDetectPaddleCollision

	noPaddleHit:
		mov al, 0         ; no wall or paddle collision
	
	endDetectPaddleCollision:
	ret 




checkTileCollision:
	push bx 
	push cx 
	push dx 
	push si
	
	
	xor ax, ax  ; Get current ball position
	mov al, [ballData+1] ; y 
	mov ah, [ballData+0] ; x  
	
	
	mov dl, al  ; Calculate next position to predict collision
	add dl, [ballData+3] ; nextY
	mov dh, ah 
	add dh, [ballData+2] ; nextX
	
	; Check if next Y position is in tile rows (2-5)
	cmp dl, 2
	jl notInTileRow
	cmp dl, 5
	jg notInTileRow
	
	; DX = (nextX, next Y)
	call getTheTileOffset ; find the exact tile 
	cmp si, 0  ; if SI = 0, no tile found
	je notInTileRow
	
	; Tile found! SI points to the tile
	cmp byte [si+3], 0 ; if tile is active...then destroy it 
	je notInTileRow  ; tile already destroyed
	
	call destroyTheTile 
	mov al, 2  ; return collision code
	jmp endCheckTileCollision
	
notInTileRow:
	xor ax, ax 
	mov al, 0  ; no collision
	
endCheckTileCollision:
	pop si
	pop dx 
	pop cx 
	pop bx 
	ret 


getTheTileOffset:
	; DX = (x,y)
	; Returns: SI = pointer to tile, or SI = 0 if not found
	
	push ax 
	push cx 
	push bx
	
	; Calculate which row (0-3 for rows at Y=2,3,4,5)
	xor ax, ax 
	mov al, dl      ; AL = y 
	sub al, 2       ; AL = row number (0-3)
	
	; Bounds check
	cmp al, 0
	jl tileNotFound2
	cmp al, 3
	jg tileNotFound2
	
	
	mov bl, 10
	mul bl          ; AX = row * 10
	mov bl, 5       ; brickStructureSize
	mul bl          ; AX = row * 10 * 5
	
	; SI now points to start of the correct row
	mov si, bricks 
	add si, ax  
	
	; Search through 10 tiles in this row
	mov cx, 10
	
getTileLoop: 
	; Check if tile is active
	cmp byte [si+3], 0
	je nextTile  ; skip if destroyed
	
	
	mov al, [si+0]  ; ball is outside the left bound of tile 
	cmp dh, al
	jl nextTile     ; ball is left of tile
	
	mov bl, al
	add bl, [si+2]  ; tile_x + width
	cmp dh, bl    ; ball is right of tile
	jg nextTile    ; ball is right of tile
	
	; tile found. SI has the pointer 
	jmp endGetTheTileOffset
	
nextTile:
	add si, 5       ; move to next tile
	loop getTileLoop
	
tileNotFound2:
	mov si, 0       ; return 0 if not found
	
endGetTheTileOffset:
	pop bx
	pop cx 
	pop ax 
	ret 
	
	
destroyTheTile:
	; SI points to the tile to destroy
	push ax
	push bx 
	push dx 
	
	; Set tile status to 0 (destroyed)
	mov byte [si+3], 0
	mov ax, [aliveBricks]
	dec ax 
	mov [aliveBricks], ax ; update active bricks count 
	
	call soundBrickBreak
	
	;Static SCore increasing here...ditching it 
	;mov ax, [score] ; increase score 
	;add ax, 10
	;mov [score], ax 
	
	;Dynamic Score Increasing here 
	mov bx, bricks 
	sub si, bx 
	mov ax, si
	xor dx, dx 
	mov bx, 50
	div bx  ; now AX has row number 
	push ax 
	call incrementScore
	
	mov word [needToPrintBricks], 1
	;call debugHelper
	
	pop dx 
	pop bx 
	pop ax
	ret
	
	
	


bounceBall:
	push ax 
	push bx 

    cmp al, 1
    je reverseDX

    cmp al, 2
    je reverseDX

    cmp al, 3
    je reverseDY

    cmp al, 4
    je reverseDY

    jmp endBounceBallFunction

	reverseDX:
		mov al, [ballData + 2]
		neg al
		mov [ballData + 2], al
		call soundWallBounce
		jmp endBounceBallFunction

	reverseDY:
		mov al, [ballData +3]
		neg al
		mov [ballData + 3], al
		call soundWallBounce
		jmp endBounceBallFunction

	endBounceBallFunction:
		pop bx 
		pop ax 
	ret 


checkBallFell:
	
	
	mov al, [ballData + 1]  ; storing ball Y pos 
	cmp al, 24              ; if y>24, ball fell off screen
	jge ballFellOff
	
	mov al, 0  ; no fall
	jmp endCheckBallFell
	
	ballFellOff:
		mov al, 1  ; ball fell
	
	endCheckBallFell:
	
		ret  ; returns AL = 1 if fell, 0 otherwise


resetBallAndPaddle:
	
	
	; Reset paddle to center
	mov byte [paddleData + 0], 35  ; X position
	mov word [needToPrintPaddle], 1
	
	; Reset ball position (on paddle)
	mov byte [ballData + 0], 40    ; X position
	mov byte [ballData + 1], 21    ; Y position
	mov byte [ballData + 2], 1     ; X movement (right)
	mov byte [ballData + 3], -1    ; Y movement (up)
	

	mov byte [ballLaunchStatus], 0 	; Ball not launched yet
	call soundBallFell
	
	ret


increaseSpeed:
	push ax 
	
	mov ax, [ballMoveInterval]
	dec ax 
	cmp ax, 0
	je endIncreaseSpeed
	mov word [ballMoveInterval], ax 
	call soundButtonPressed
	
	endIncreaseSpeed:
	pop ax 
	ret 

decreaseSpeed:
	push ax 
	
	mov ax, [ballMoveInterval]
	inc ax 
	cmp ax, 10
	je endDecreaseSpeed
	mov word [ballMoveInterval], ax 
	call soundButtonPressed
	
	endDecreaseSpeed:
	pop ax 
	ret

incrementScore:
	; param at [bp+4]
	; param stores the TileRowNum
	push bp 
	mov bp, sp 
	push ax 
	push bx 
	push cx 
	push dx 
	
	mov ax, 4 ; i.e, AX = 4
	sub ax, [bp+4] ; i.e, AX = 4-0 = 4 (top row gives higher rewards)
	mov bl, 10 
	mul bl  ; AX = 4 * 10 = 40
	
	mov cx, [score]
	add cx, ax 
	mov [score], cx 
	
	pop dx 
	pop cx 
	pop bx 
	pop ax 
	pop bx 
	ret 2 
	
	
increasePaddleWidth:
	push ax 
	
	mov ax, [paddleData + 2] ; paddle width 
	inc ax 
	cmp ax, 25
	je endIncreasePaddleWidth
	mov [paddleData+2], ax 
	mov byte [needToPrintPaddle], 1
	call soundButtonPressed
	
	endIncreasePaddleWidth:
	pop ax
	ret 
	

decreasePaddleWidth:
	push ax 
	
	mov ax, [paddleData + 2] ; paddle width 
	dec ax 
	cmp ax, 5
	je endDecreasePaddleWidth
	call removeThePaddle
	mov [paddleData+2], ax 
	mov byte [needToPrintPaddle], 1
	call soundButtonPressed
	
	endDecreasePaddleWidth:
	pop ax
	ret 
	

pauseTheGame:
	push ax 
	
	call soundButtonPressed
	call showCenterBoundary
	call showGamePaused
waitForUnpause:	
	mov ah, 00
	int 0x16 
	cmp al, '0'
	je terminateTheProgramSequence
	cmp al, 'p'
	je unpauseTheGame
	cmp al, 'P'
	jne waitForUnpause
	
unpauseTheGame:
	call soundButtonPressed
	call removeCenterBoundary
	call removeGamePaused
	pop ax 
	ret 


; ------
; SOUND RELATED 
; ------

; ================================
; playSound:
; AX = frequency divisor
; CX = duration
;
; Example values:
;   AX = 1000 → medium beep
;   AX = 800  → higher pitch
;   AX = 2000 → lower pitch
;
; ================================
playSound:
	; AX = Freq, CX = duration 
    push ax
    push bx
    push dx

    ; Configure PIT channel 2
    mov al, 0B6h          ; 1011 0110: load channel 2, lobyte/hibyte, square wave
    out 43h, al

    ; Send frequency divisor (AX)
    mov al, al            ; low byte
    out 42h, al
    mov al, ah            ; high byte
    out 42h, al

    ; Turn speaker ON
    in   al, 61h
    mov  bl, al           ; save original speaker state
    or   al, 03h
    out  61h, al

    ; --- Delay loop ---
soundDelay:
    nop
    loop soundDelay

    ; Turn speaker OFF
    mov al, bl
    out 61h, al

    pop dx
    pop bx
    pop ax
ret


soundBrickBreak:
	push ax 
	push cx 
	
    mov ax, 850
    mov cx, 9000
    call playSound
	pop cx 
	pop ax 
    ret

soundPaddleHit:
	push ax 
	push cx 
	
    mov ax, 700
    mov cx, 6000
    call playSound
	pop cx 
	pop ax 
    ret

soundWallBounce:
	push ax 
	push cx 
	
    mov ax, 1200
    mov cx, 7000
    call playSound
	pop cx 
	pop ax 
    ret

soundBallFell:
	push ax 
	push cx 
	
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	
	pop cx
	pop ax 
	ret

soundGameOver:
	push ax 
	push cx 
	 ; trying ot make a little melody 
    mov ax, 2000
    mov cx, 0xffff
    call playSound
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	
	call delay 
	
	mov ax, 4000
    mov cx, 0xffff
    call playSound
	mov ax, 4000
    mov cx, 0xffff
    call playSound
	mov ax, 4000
    mov cx, 0xffff
    call playSound
	mov ax, 4000
    mov cx, 0xffff
    call playSound
	
	call delay 
	
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	mov ax, 8000
    mov cx, 0xffff
    call playSound
	
	pop cx 
	pop ax 
    ret
	
soundVictory:
	push ax 
	push cx 
	
    mov ax, 3000
    mov cx, 0xffff
    call playSound
	mov ax, 3000
    mov cx, 0xffff
    call playSound
	mov ax, 3000
    mov cx, 0xffff
    call playSound
	mov ax, 3000
    mov cx, 0xffff
    call playSound
	
	call delay 
	
	mov ax, 5000
    mov cx, 0xffff
    call playSound
	mov ax, 5000
    mov cx, 0xffff
    call playSound
	mov ax, 5000
    mov cx, 0xffff
    call playSound
	mov ax, 5000
    mov cx, 0xffff
    call playSound
	
	call delay 
	
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	mov ax, 2000
    mov cx, 0xffff
    call playSound
	
	pop cx 
	pop ax 
    ret

soundButtonPressed:
	push ax 
	push cx 
	
    mov ax, 1000
    mov cx, 0xffff
    call playSound
	mov ax, 1000
    mov cx, 0xffff
    call playSound
	mov ax, 1000
    mov cx, 0xffff
    call playSound
	mov ax, 1000
    mov cx, 0xffff
    call playSound
	
	pop cx
	pop ax 
	ret 

;-------------------------------------------
; DATA 
;-------------------------------------------

; debugging vars here

isGameLoop: db 1

; splash/intro screen data here 

splashLinesCount: dw 19
splashLineWidth: dw 46

splashLine:
db '=============================================='
db '              BREAKOUT ARCADE GAME            '
db '=============================================='
db '                                              '
db '                = INSTRUCTIONS =              '
db '                                              '
db '    You have 3 lives.                         '
db '    Break all the tiles to Win.               '
db '                                              '
db '                = CONTROLS =                  '
db '    A / D       : Move Paddle (Optional)      '
db '    Spacebar    : Launch Ball                 '
db '    P           : Pause Game                  '
db '    3 / 4       : Dec / Inc Level             '
db '    5 / 6       : Dec / Inc Paddle Width      '
db '                                              '
db '=============================================='
db '            Press ANY KEY to START...         '
db '=============================================='



; game vars here 

score: dw 0
lives: dw 9

brick_char: db '|'
paddle_char: db '='
ball_char: db 'O'

; HUD and Print Data 
hudBgColor: db 01110000b
hudTextColor: db 01110000b
numColor: db 00000111b
victoryText: db 'YOU WIN!'
gameOverText: db 'GAME OVER!'
finalScoreText: db 'FINAL SCORE: '
pauseText: db '= GAME PAUSED ='
pauseCaption: db 'Press P to Resume'
pressAnyKeyCaption: db 'Press Any Key To Continue'
scoreText: db 'SCORE: '
livesText: db 'LIVES: '
levelText: db 'LEVEL: '

aliveBricks: db 40
needToPrintBricks: dw 1
brickStructureSize: dw 5 ; size in terms of data 
brickCount: dw 40  ; no.of bricks to print 
bricks:
		;  x, y, width, status, attribute 
		db 1, 2,  6, 1, 01000100b
		db 8, 2,  5, 1, 01000100b
		db 14, 2,  7, 1, 01000100b
		db 22, 2,  4, 1, 01000100b
		db 27, 2,  8, 1, 01000100b
		db 36, 2,  5, 1, 01000100b
		db 42, 2,  10, 1, 01000100b
		db 53, 2,  7, 1, 01000100b
		db 61, 2,  10, 1, 01000100b
		db 72, 2,  7, 1, 01000100b

		db  0, 3, 7, 1, 00100010b
		db  8, 3, 7, 1, 00100010b
		db 16, 3, 5, 1, 00100010b
		db 22, 3, 6, 1, 00100010b
		db 29, 3, 8, 1, 00100010b
		db 38, 3, 5, 1, 00100010b
		db 44, 3, 7, 1, 00100010b
		db 52, 3, 6, 1, 00100010b
		db 59, 3, 8, 1, 00100010b
		db 68, 3, 9, 1, 00100010b

		db  1, 4, 7, 1, 00110011b
		db  9, 4, 6, 1, 00110011b
		db 16, 4, 9, 1, 00110011b
		db 26, 4, 4, 1, 00110011b
		db 31, 4, 7, 1, 00110011b
		db 39, 4, 6, 1, 00110011b
		db 46, 4, 7, 1, 00110011b
		db 54, 4, 8, 1, 00110011b
		db 63, 4, 5, 1, 00110011b
		db 69, 4, 11, 1, 00110011b

		db  0, 5, 6, 1, 01100110b
		db  7, 5, 8, 1, 01100110b
		db 16, 5, 6, 1, 01100110b
		db 23, 5, 7, 1, 01100110b
		db 31, 5, 8, 1, 01100110b
		db 40, 5, 5, 1, 01100110b
		db 46, 5, 9, 1, 01100110b
		db 56, 5, 6, 1, 01100110b
		db 63, 5, 7, 1, 01100110b
		db 71, 5, 8, 1, 01100110b


paddleData:
		; x, y, width, attribute 
		db 35, 23, 10, 01010101b
needToPrintPaddle:
		dw 1


ballMoveInterval: dw 5 ; ball moves every Nth frame 
ballLaunchStatus: db 0 ; when to launch ball 
ballData:
		; x, y
		; x_movment, y_movement
		; attribute 
		db 40, 21, 1, -1, 00001010b

frameCounter: dw 0 


start:
	call clearscreen
	call showSplashScreen
	
	gamestart: 
		call clearscreen
		call setHUDbackgroundColor
		call showWatermark
		call printScoreAndLives
		call drawBall

	gameloop:
		
		cmp byte [isGameLoop], 0  ; is game Active 
		jne gameNotEnd
		call terminateProgram
		gameNotEnd:
	
		cmp word [aliveBricks], 0
		jne gameNotWon
		call gameWon
		gameNotWon:
	
		cmp word [lives], 0
		jne gameNotLost
		call gameLost
		gameNotLost: 
	
		xor ax, ax 
		mov ah, 0x01 
		int 16h
		cmp al, 0
		je noKeyPressed
		
		mov ah, 0x00
		int 16h               ; clearing buffer 
		xor ah, ah 
		
		push ax ; parameter for below func
		call processKeyboardInput
		
	
	noKeyPressed:
	cmp byte [ballLaunchStatus], 0  ; if ball not launched yet, skip Ball Mechanics 
	je skipBallSequence
	
	inc word [frameCounter]  ; calculating frame 
	mov ax, [frameCounter]
	xor dx, dx 
	mov bx, [ballMoveInterval]
	div bx 
	
	cmp dx, 0 ; ball only moves when frame%n == 0
	jne skipBallSequence 
	
		call checkBallFell
		cmp al, 1
		je ballLost 
	
		call detectCollision
		
		cmp al, 0 
		je skipBounceBall
		call bounceBall
		xor ax, ax 
		
		
		
		
	skipBounceBall: 
		call progressBall 
		cmp word [frameCounter], 1000 ; reset frame after some time to prevent overflow
		jl skipBallSequence
		mov word [frameCounter], 0
		jmp skipBallSequence
		
	ballLost:
		dec word [lives]
		call resetBallAndPaddle
		call clearscreen
		call setHUDbackgroundColor
		call printScoreAndLives
		call drawBall
	
		mov word [needToPrintBricks], 1
		mov word [needToPrintPaddle], 1
		
	skipBallSequence:
		cmp word [needToPrintBricks], 0
		je skipBricksPrinting 
		call drawAllBricksIndividually
		
	skipBricksPrinting:
		cmp word [needToPrintPaddle], 0
		je skipPaddlePrinting
		call drawThePaddle
	skipPaddlePrinting:
		call printScoreAndLives
		call showWatermark
		call delay 
		jmp gameloop 
		
	
		

terminateProgram:

mov ax, 0x4c00
int 0x21


gameWon:
	call showVictory
	jmp terminateProgram
	
gameLost:
	call showGameOver
	jmp terminateProgram
	