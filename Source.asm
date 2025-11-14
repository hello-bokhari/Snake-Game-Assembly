INCLUDE Irvine32.inc
INCLUDELIB Irvine32.lib
INCLUDELIB kernel32.lib

ExitProcess PROTO, dwExitCode:DWORD

;--------------- Constants ----------------
GRID_WIDTH  EQU 40
GRID_HEIGHT EQU 20
MAX_SNAKE   EQU 250
GAME_DELAY  EQU 90

; Direction constants
DIR_RIGHT   EQU 0
DIR_DOWN    EQU 1
DIR_LEFT    EQU 2
DIR_UP      EQU 3

;--------------- Data --------------------
.data
gameScore   DWORD 0
snakeLength DWORD 5
snakeDir    BYTE 0
foodPosX    BYTE 0
foodPosY    BYTE 0
snakePosX   BYTE MAX_SNAKE DUP(0)
snakePosY   BYTE MAX_SNAKE DUP(0)

charHead    BYTE 'O', 0
charBody    BYTE 'o', 0
charFood    BYTE '@', 0
charWall    BYTE '#', 0
charSpace   BYTE ' ', 0

clrHead     BYTE 0Eh
clrBody     BYTE 0Ah
clrFood     BYTE 0Ch
clrWall     BYTE 08h
clrNormal   BYTE 07h

msgStart    BYTE "=== SNAKE GAME ===", 13, 10
            BYTE "Use Arrow Keys to move", 13, 10
            BYTE "Press any key to start...", 0
msgOver     BYTE 13, 10, "GAME OVER! Final Score: ", 0
msgExit     BYTE 13, 10, "Press Enter to exit...", 0
msgScoreLbl BYTE "Score: ", 0

.code

;=========================================
; MAIN PROCEDURE
;=========================================
main PROC
    call Randomize
    call ClrScr
    
    ; Show start screen
    mov dh, 8
    mov dl, 20
    call Gotoxy
    mov al, clrHead
    call SetTextColor
    mov edx, OFFSET msgStart
    call WriteString
    call ReadChar
    
    ; Initialize game
    call ClrScr
    call InitializeSnake
    call SpawnFood
    
    ; Main game loop
MainGameLoop:
    call RenderFrame
    call ProcessInput
    call UpdateSnake
    
    mov eax, GAME_DELAY
    call Delay
    jmp MainGameLoop
    
MainExit:
    call ClrScr
    invoke ExitProcess, 0
main ENDP

;=========================================
; INITIALIZE SNAKE
;=========================================
InitializeSnake PROC
    push eax
    push ecx
    push esi
    
    ; Reset game state
    mov gameScore, 0
    mov snakeLength, 5
    mov snakeDir, DIR_RIGHT
    
    ; Place snake horizontally in center
    mov ecx, 5
    mov esi, 0
    
InitSnakeLoop:
    mov eax, 20
    sub eax, esi
    mov [snakePosX + esi], al
    mov BYTE PTR [snakePosY + esi], 10
    inc esi
    loop InitSnakeLoop
    
    pop esi
    pop ecx
    pop eax
    ret
InitializeSnake ENDP

;=========================================
; SPAWN FOOD AT RANDOM LOCATION
;=========================================
SpawnFood PROC
    push eax
    push ebx
    push ecx
    
TryNewFood:
    ; Generate random position
    mov eax, GRID_WIDTH
    call RandomRange
    inc al
    mov foodPosX, al
    
    mov eax, GRID_HEIGHT
    call RandomRange
    inc al
    mov foodPosY, al
    
    ; Check if food overlaps snake
    mov ecx, snakeLength
    xor ebx, ebx
    
CheckFoodCollision:
    cmp ebx, ecx
    jae FoodIsValid
    
    mov al, [snakePosX + ebx]
    cmp al, foodPosX
    jne NextFoodCheck
    
    mov al, [snakePosY + ebx]
    cmp al, foodPosY
    jne NextFoodCheck
    
    ; Food on snake, try again
    jmp TryNewFood
    
NextFoodCheck:
    inc ebx
    jmp CheckFoodCollision
    
FoodIsValid:
    pop ecx
    pop ebx
    pop eax
    ret
SpawnFood ENDP

;=========================================
; RENDER GAME FRAME
;=========================================
RenderFrame PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    
    ; Move cursor to top
    mov dh, 0
    mov dl, 0
    call Gotoxy
    
    ; Draw top wall
    mov al, clrWall
    call SetTextColor
    mov ecx, GRID_WIDTH
    add ecx, 2
DrawTopWall:
    mov edx, OFFSET charWall
    call WriteString
    loop DrawTopWall
    call Crlf
    
    ; Draw game area row by row
    mov bl, 1
    
DrawRowsLoop:
    movzx eax, bl
    cmp eax, GRID_HEIGHT
    jg DrawBottomWall
    
    ; Left wall
    mov al, clrWall
    call SetTextColor
    mov edx, OFFSET charWall
    call WriteString
    
    ; Draw columns
    mov bh, 1
    
DrawColumnsLoop:
    movzx eax, bh
    cmp eax, GRID_WIDTH
    jg EndOfRow
    
    ; Check what to draw at this position
    call CheckPosition
    
    inc bh
    jmp DrawColumnsLoop
    
EndOfRow:
    ; Right wall
    mov al, clrWall
    call SetTextColor
    mov edx, OFFSET charWall
    call WriteString
    call Crlf
    
    inc bl
    jmp DrawRowsLoop
    
DrawBottomWall:
    mov al, clrWall
    call SetTextColor
    mov ecx, GRID_WIDTH
    add ecx, 2
DrawBottomLoop:
    mov edx, OFFSET charWall
    call WriteString
    loop DrawBottomLoop
    call Crlf
    
    ; Display score
    mov al, clrNormal
    call SetTextColor
    mov edx, OFFSET msgScoreLbl
    call WriteString
    mov eax, gameScore
    call WriteDec
    call Crlf
    
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
RenderFrame ENDP

;=========================================
; CHECK WHAT TO DRAW AT POSITION (BH, BL)
;=========================================
CheckPosition PROC
    push eax
    push ecx
    push esi
    
    ; Check if it's the snake head
    mov al, [snakePosX]
    cmp al, bh
    jne CheckSnakeBody
    mov al, [snakePosY]
    cmp al, bl
    jne CheckSnakeBody
    
    ; Draw head
    mov al, clrHead
    call SetTextColor
    mov edx, OFFSET charHead
    call WriteString
    jmp CheckPositionDone
    
CheckSnakeBody:
    ; Check if it's snake body
    mov ecx, snakeLength
    mov esi, 1
    
CheckBodyLoop:
    cmp esi, ecx
    jae CheckFoodPos
    
    mov al, [snakePosX + esi]
    cmp al, bh
    jne NextBodySegment
    mov al, [snakePosY + esi]
    cmp al, bl
    jne NextBodySegment
    
    ; Draw body
    mov al, clrBody
    call SetTextColor
    mov edx, OFFSET charBody
    call WriteString
    jmp CheckPositionDone
    
NextBodySegment:
    inc esi
    jmp CheckBodyLoop
    
CheckFoodPos:
    ; Check if it's food
    mov al, foodPosX
    cmp al, bh
    jne DrawEmpty
    mov al, foodPosY
    cmp al, bl
    jne DrawEmpty
    
    ; Draw food
    mov al, clrFood
    call SetTextColor
    mov edx, OFFSET charFood
    call WriteString
    jmp CheckPositionDone
    
DrawEmpty:
    ; Draw empty space
    mov al, clrNormal
    call SetTextColor
    mov edx, OFFSET charSpace
    call WriteString
    
CheckPositionDone:
    pop esi
    pop ecx
    pop eax
    ret
CheckPosition ENDP

;=========================================
; PROCESS KEYBOARD INPUT
;=========================================
ProcessInput PROC
    push eax
    
    call ReadKey
    jz NoKeyPressed
    
    ; Check for quit keys
    cmp al, 27
    je ExitGame
    cmp al, 'q'
    je ExitGame
    cmp al, 'Q'
    je ExitGame
    
    ; Check arrow keys
    cmp ah, 72
    je PressUp
    cmp ah, 80
    je PressDown
    cmp ah, 75
    je PressLeft
    cmp ah, 77
    je PressRight
    jmp NoKeyPressed
    
PressUp:
    cmp snakeDir, DIR_DOWN
    je NoKeyPressed
    mov snakeDir, DIR_UP
    jmp NoKeyPressed
    
PressDown:
    cmp snakeDir, DIR_UP
    je NoKeyPressed
    mov snakeDir, DIR_DOWN
    jmp NoKeyPressed
    
PressLeft:
    cmp snakeDir, DIR_RIGHT
    je NoKeyPressed
    mov snakeDir, DIR_LEFT
    jmp NoKeyPressed
    
PressRight:
    cmp snakeDir, DIR_LEFT
    je NoKeyPressed
    mov snakeDir, DIR_RIGHT
    jmp NoKeyPressed
    
ExitGame:
    call ClrScr
    invoke ExitProcess, 0
    
NoKeyPressed:
    pop eax
    ret
ProcessInput ENDP

;=========================================
; UPDATE SNAKE POSITION
;=========================================
UpdateSnake PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Calculate new head position
    movzx eax, BYTE PTR [snakePosX]
    movzx ebx, BYTE PTR [snakePosY]
    
    cmp snakeDir, DIR_RIGHT
    je MoveRight
    cmp snakeDir, DIR_DOWN
    je MoveDown
    cmp snakeDir, DIR_LEFT
    je MoveLeft
    cmp snakeDir, DIR_UP
    je MoveUp
    
MoveRight:
    inc al
    jmp CheckCollisions
MoveDown:
    inc bl
    jmp CheckCollisions
MoveLeft:
    dec al
    jmp CheckCollisions
MoveUp:
    dec bl
    
CheckCollisions:
    ; Check wall collision
    cmp al, 1
    jl GameOver
    cmp al, GRID_WIDTH
    jg GameOver
    cmp bl, 1
    jl GameOver
    cmp bl, GRID_HEIGHT
    jg GameOver
    
    ; Check self collision
    mov ecx, snakeLength
    cmp ecx, 1
    jle CheckFoodCollision
    
    mov esi, 1
CheckSelfLoop:
    cmp esi, ecx
    jae CheckFoodCollision
    
    movzx edx, BYTE PTR [snakePosX + esi]
    cmp dl, al
    jne NextSelfCheck
    
    movzx edx, BYTE PTR [snakePosY + esi]
    cmp dl, bl
    jne NextSelfCheck
    
    jmp GameOver
    
NextSelfCheck:
    inc esi
    jmp CheckSelfLoop
    
CheckFoodCollision:
    ; Check if food eaten
    movzx edx, BYTE PTR foodPosX
    cmp dl, al
    jne MoveNormally
    
    movzx edx, BYTE PTR foodPosY
    cmp dl, bl
    jne MoveNormally
    
    ; Food eaten - grow snake
    mov ecx, snakeLength
    inc ecx
    cmp ecx, MAX_SNAKE
    jg CapLength
    mov snakeLength, ecx
    inc gameScore
    call SpawnFood
    jmp InsertHead
    
CapLength:
    mov snakeLength, MAX_SNAKE
    inc gameScore
    call SpawnFood
    jmp InsertHead
    
MoveNormally:
    ; Shift body segments
    mov ecx, snakeLength
    cmp ecx, 1
    jle InsertHead
    
    mov esi, ecx
    dec esi
    
ShiftLoop:
    cmp esi, 0
    jle InsertHead
    
    mov edi, esi
    dec edi
    
    movzx edx, BYTE PTR [snakePosX + edi]
    mov [snakePosX + esi], dl
    
    movzx edx, BYTE PTR [snakePosY + edi]
    mov [snakePosY + esi], dl
    
    dec esi
    jmp ShiftLoop
    
InsertHead:
    mov [snakePosX], al
    mov [snakePosY], bl
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
    
GameOver:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    
    call Crlf
    call Crlf
    mov al, clrFood
    call SetTextColor
    mov edx, OFFSET msgOver
    call WriteString
    mov eax, gameScore
    call WriteDec
    
    mov al, clrNormal
    call SetTextColor
    mov edx, OFFSET msgExit
    call WriteString
    
WaitForExit:
    call ReadChar
    cmp al, 13
    jne WaitForExit
    
    call ClrScr
    invoke ExitProcess, 0
UpdateSnake ENDP

END main