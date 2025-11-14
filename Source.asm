
INCLUDE Irvine32.inc
INCLUDELIB Irvine32.lib
INCLUDELIB kernel32.lib

ExitProcess PROTO, dwExitCode:DWORD

;--------------- Constants ----------------
WIDTH_BYTE  EQU 40
HEIGHT_BYTE EQU 20
MAXLEN      EQU 250
DELAY_MS    EQU 90

;--------------- Data --------------------
.data
score       DWORD 0
snakeLen    DWORD 5
dir         BYTE 0          ; 0=right, 1=down, 2=left, 3=up
foodX       BYTE 0
foodY       BYTE 0
snakeX      BYTE MAXLEN DUP(0)
snakeY      BYTE MAXLEN DUP(0)

chHead      BYTE 'O'
chBody      BYTE 'o'
chFood      BYTE '@'
chWall      BYTE '#'
chEmpty     BYTE ' '

colorHead   BYTE 0Eh      ; Yellow
colorBody   BYTE 0Ah      ; Light green
colorFood   BYTE 0Ch      ; Light red
colorWall   BYTE 08h      ; Dark gray
colorEmpty  BYTE 07h      ; Default

msgGameOver BYTE "GAME OVER! Score: ", 0
msgPressKey BYTE " - Press Enter to exit...", 0
msgScore    BYTE "Score: ", 0

tempX       BYTE 0
tempY       BYTE 0

.code

main PROC
    call Randomize
    call ClrScr

    ; Initialize snake in center
    xor esi, esi
init_loop:
    mov al, 20
    sub al, esi  ;error
    mov [snakeX+esi], al
    mov [snakeY+esi], 10
    inc esi
    cmp esi, 5
    jl init_loop

    mov dir, 0
    mov snakeLen, 5
    mov score, 0
    call PlaceFood

game_loop:
    call DrawGame
    call ReadKey
    jz no_key

    ; Quit keys
    cmp al, 27
    je quit
    cmp al, 'q'
    je quit
    cmp al, 'Q'
    je quit

    ; Arrow keys
    cmp ah, 72
    je key_up
    cmp ah, 80
    je key_down
    cmp ah, 75
    je key_left
    cmp ah, 77
    je key_right
    jmp no_key

key_up:
    cmp dir, 1
    je no_key
    mov dir, 3
    jmp no_key

key_down:
    cmp dir, 3
    je no_key
    mov dir, 1
    jmp no_key

key_left:
    cmp dir, 0
    je no_key
    mov dir, 2
    jmp no_key

key_right:
    cmp dir, 2
    je no_key
    mov dir, 0

no_key:
    call MoveSnake
    mov eax, DELAY_MS
    call Delay
    jmp game_loop

quit:
    call ClrScr
    invoke ExitProcess,0
main ENDP

;------------------------------------------
PlaceFood PROC
    pushad
pick_food:
    mov eax, WIDTH_BYTE
    call RandomRange
    inc al
    mov [foodX], al

    mov eax, HEIGHT_BYTE
    call RandomRange
    inc al
    mov [foodY], al

    ; Check for collision with snake
    mov ecx, snakeLen
    xor ebx, ebx

check_collision:
    cmp ebx, ecx
    jae food_ok

    mov al, [snakeX+ebx]
    cmp al, [foodX]
    jne next_segment
    mov al, [snakeY+ebx]
    cmp al, [foodY]
    jne next_segment

    ; Collision, retry
    jmp pick_food

next_segment:
    inc ebx
    jmp check_collision

food_ok:
    popad
    ret
PlaceFood ENDP

;------------------------------------------
DrawGame PROC
    pushad

    call ClrScr

    ; Top wall
    mov ecx, WIDTH_BYTE+2
    mov al, colorWall
    call SetTextColor
    mov edx, OFFSET chWall
draw_top:
    call WriteString
    loop draw_top
    call Crlf

    ; Draw rows
    mov bl, 1
draw_rows:
    cmp bl, HEIGHT_BYTE+1
    jg draw_bottom_wall

    ; Left wall
    mov al, colorWall
    call SetTextColor
    mov edx, OFFSET chWall
    call WriteString

    ; Draw cells
    mov bh, 1
draw_cols:
    cmp bh, WIDTH_BYTE+1
    jg draw_right_wall

    mov tempX, bh
    mov tempY, bl

    ; Check snake head
    mov al, [snakeX]
    cmp al, tempX
    jne check_body
    mov al, [snakeY]
    cmp al, tempY
    jne check_body
    mov al, colorHead
    call SetTextColor
    mov edx, OFFSET chHead
    call WriteString
    jmp next_cell

check_body:
    mov ecx, snakeLen
    xor esi, esi
    inc esi
check_body_loop:
    cmp esi, ecx
    jae check_food
    mov al, [snakeX+esi]
    cmp al, tempX
    jne next_body_segment
    mov al, [snakeY+esi]
    cmp al, tempY
    jne next_body_segment
    mov al, colorBody
    call SetTextColor
    mov edx, OFFSET chBody
    call WriteString
    jmp next_cell
next_body_segment:
    inc esi
    jmp check_body_loop

check_food:
    mov al, [foodX]
    cmp al, tempX
    jne draw_empty
    mov al, [foodY]
    cmp al, tempY
    jne draw_empty
    mov al, colorFood
    call SetTextColor
    mov edx, OFFSET chFood
    call WriteString
    jmp next_cell

draw_empty:
    mov al, colorEmpty
    call SetTextColor
    mov edx, OFFSET chEmpty
    call WriteString

next_cell:
    inc bh
    jmp draw_cols

draw_right_wall:
    mov al, colorWall
    call SetTextColor
    mov edx, OFFSET chWall
    call WriteString
    call Crlf
    inc bl
    jmp draw_rows

draw_bottom_wall:
    mov ecx, WIDTH_BYTE+2
    mov al, colorWall
    call SetTextColor
    mov edx, OFFSET chWall
draw_bottom:
    call WriteString
    loop draw_bottom
    call Crlf

    ; Display score
    mov al, 07h
    call SetTextColor
    mov edx, OFFSET msgScore
    call WriteString
    mov eax, score
    call WriteDec
    call Crlf

    popad
    ret
DrawGame ENDP

;------------------------------------------
MoveSnake PROC
    pushad

    mov al, [snakeX]
    mov bl, [snakeY]

    cmp dir, 0
    je move_right
    cmp dir, 1
    je move_down
    cmp dir, 2
    je move_left
    cmp dir, 3
    je move_up

move_right: inc al
    jmp position_ready
move_down:  inc bl
    jmp position_ready
move_left:  dec al
    jmp position_ready
move_up:    dec bl

position_ready:
    ; Wall collision
    cmp al, 1
    jl game_over
    cmp al, WIDTH_BYTE
    jg game_over
    cmp bl, 1
    jl game_over
    cmp bl, HEIGHT_BYTE
    jg game_over

    mov tempX, al
    mov tempY, bl

    ; Self collision
    mov ecx, snakeLen
    xor esi, esi
self_collision:
    cmp esi, ecx
    jae check_food
    mov dl, [snakeX+esi]
    cmp dl, tempX
    jne next_self
    mov dh, [snakeY+esi]
    cmp dh, tempY
    jne next_self
    jmp game_over
next_self:
    inc esi
    jmp self_collision

check_food:
    mov dl, [foodX]
    cmp dl, tempX
    jne normal_move
    mov dl, [foodY]
    cmp dl, tempY
    jne normal_move

    ; Eating food
    mov eax, snakeLen
    inc eax
    cmp eax, MAXLEN
    jg cap_length
    mov snakeLen, eax
    inc score
    call PlaceFood
    jmp insert_head
cap_length:
    mov snakeLen, MAXLEN
    inc score
    call PlaceFood

normal_move:
    ; Shift body
    mov eax, snakeLen
    dec eax
    mov esi, eax
shift_loop:
    cmp esi, 0
    jle insert_head
    mov dl, [snakeX+esi-1]
    mov [snakeX+esi], dl
    mov dl, [snakeY+esi-1]
    mov [snakeY+esi], dl
    dec esi
    jmp shift_loop

insert_head:
    mov [snakeX], tempX ; error
    mov [snakeY], tempY ;error
    popad
    ret

game_over:
    call ClrScr
    mov dh, 10
    mov dl, 20
    call Gotoxy
    mov al, 0Ch
    call SetTextColor
    mov edx, OFFSET msgGameOver
    call WriteString
    mov eax, score
    call WriteDec
    mov edx, OFFSET msgPressKey
    call WriteString

wait_loop:
    call ReadChar
    cmp al, 13
    jne wait_loop
    invoke ExitProcess, 0
MoveSnake ENDP

END main
