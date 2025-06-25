jmp main

; Variáveis do jogo
dino_pos: var #1
dino_y: var #1
dino_jumping: var #1
dino_jump_count: var #1

obstacles: var #5
obstacle_x: var #5
obstacle_active: var #5

score: var #1
game_over: var #1
game_speed: var #1

static dino_pos + #0, #1118    ; Posição inicial linha 27, coluna 38
static dino_y + #0, #27        ; Y inicial do dinossauro
static dino_jumping + #0, #0   ; Não está pulando
static dino_jump_count + #0, #0 ; Contador de pulo
static score + #0, #0          ; Pontuação inicial
static game_over + #0, #0      ; Jogo não terminou
static game_speed + #0, #3     ; Velocidade inicial

; Strings do jogo
dino_char: string "D"
obstacle_char: string "|"
ground_char: string "="
space_char: string " "

game_over_msg: string "GAME OVER - PRESSIONE R PARA REINICIAR"
score_msg: string "SCORE: "

main:
    call init_game

game_loop:
    call clear_screen
    call handle_input
    call update_game
    call render_game
    call delay

    load r0, game_over
    loadn r1, #1
    cmp r0, r1
    jeq game_over_screen

    jmp game_loop

game_over_screen:
    call clear_screen
    call draw_game_over
    call input_wait

    loadn r1, #'r'
    cmp r0, r1
    jeq restart_game

    loadn r1, #'q'
    cmp r0, r1
    jeq end_game

    jmp game_over_screen

restart_game:
    call init_game
    jmp game_loop

end_game:
    halt

init_game:
    push r0
    push r1
    push r2

    ; Reinicializa variáveis
    loadn r0, #1118
    store dino_pos, r0
    loadn r0, #27
    store dino_y, r0
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    store score, r0
    store game_over, r0

    ; Inicializa obstáculos
    loadn r0, #obstacles
    loadn r1, #5
    loadn r2, #0

init_obstacles_loop:
    storei r0, r2
    inc r0
    dec r1
    cmp r1, r2
    jne init_obstacles_loop

    ; Desenha chão
    call draw_ground

    pop r2
    pop r1
    pop r0
    rts

handle_input:
    push r0
    push r1

    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq handle_input_end

    loadn r1, #' '  ; Tecla espaço
    cmp r0, r1
    jeq start_jump

    jmp handle_input_end

start_jump:
    load r0, dino_jumping
    loadn r1, #0
    cmp r0, r1
    jne handle_input_end

    loadn r0, #1
    store dino_jumping, r0
    loadn r0, #0
    store dino_jump_count, r0

handle_input_end:
    pop r1
    pop r0
    rts

update_game:
    push r0
    push r1
    push r2
    push r3

    ; Atualiza pulo do dinossauro
    call update_dino_jump

    ; Atualiza obstáculos
    call update_obstacles

    ; Verifica colisões
    call check_collisions

    ; Incrementa pontuação
    load r0, score
    inc r0
    store score, r0

    ; Aumenta velocidade gradualmente
    loadn r1, #100
    mod r2, r0, r1
    loadn r3, #0
    cmp r2, r3
    jne update_game_end

    load r1, game_speed
    loadn r2, #1
    cmp r1, r2
    jeq update_game_end
    dec r1
    store game_speed, r1

update_game_end:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

update_dino_jump:
    push r0
    push r1
    push r2
    push r3

    load r0, dino_jumping
    loadn r1, #0
    cmp r0, r1
    jeq update_dino_jump_end

    load r0, dino_jump_count
    inc r0
    store dino_jump_count, r0

    ; Fase de subida (frames 1-6)
    loadn r1, #6
    cmp r0, r1
    jle dino_going_up

    ; Fase de descida (frames 7-12)
    loadn r1, #12
    cmp r0, r1
    jle dino_going_down

    ; Termina o pulo
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    loadn r0, #27
    store dino_y, r0

    ; Recalcula posição
    load r1, dino_y
    loadn r2, #40
    mul r1, r1, r2
    loadn r2, #38
    add r1, r1, r2
    store dino_pos, r1

    jmp update_dino_jump_end

dino_going_up:
    loadn r1, #24  ; Altura máxima y=24
    store dino_y, r1
    jmp recalc_dino_pos

dino_going_down:
    loadn r1, #25  ; Altura intermediária y=25
    store dino_y, r1
    jmp recalc_dino_pos

recalc_dino_pos:
    load r1, dino_y
    loadn r2, #40
    mul r1, r1, r2
    loadn r2, #38
    add r1, r1, r2
    store dino_pos, r1

update_dino_jump_end:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

update_obstacles:
    push r0
    push r1
    push r2
    push r3
    push r4

    ; Atualiza obstáculos existentes
    loadn r0, #0

update_obstacles_loop:
    loadn r1, #5
    cmp r0, r1
    jeg update_obstacles_spawn

    loadn r1, #obstacle_active
    add r1, r1, r0
    loadi r2, r1

    loadn r3, #0
    cmp r2, r3
    jeq update_obstacles_next

    ; Move obstáculo para esquerda
    loadn r1, #obstacle_x
    add r1, r1, r0
    loadi r2, r1

    load r3, game_speed
    sub r2, r2, r3

    ; Verifica se saiu da tela
    loadn r3, #0
    cmp r2, r3
    jle deactivate_obstacle

    storei r1, r2
    jmp update_obstacles_next

deactivate_obstacle:
    loadn r1, #obstacle_active
    add r1, r1, r0
    loadn r2, #0
    storei r1, r2

update_obstacles_next:
    inc r0
    jmp update_obstacles_loop

update_obstacles_spawn:
    ; Tenta criar novo obstáculo
    load r0, score
    loadn r1, #30
    mod r2, r0, r1
    loadn r3, #0
    cmp r2, r3
    jne update_obstacles_end

    call spawn_obstacle

update_obstacles_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

spawn_obstacle:
    push r0
    push r1
    push r2

    ; Procura slot livre
    loadn r0, #0

spawn_obstacle_loop:
    loadn r1, #5
    cmp r0, r1
    jeg spawn_obstacle_end

    loadn r1, #obstacle_active
    add r1, r1, r0
    loadi r2, r1

    loadn r2, #0
    cmp r2, r2
    jeq found_free_slot

    inc r0
    jmp spawn_obstacle_loop

found_free_slot:
    ; Ativa obstáculo
    loadn r2, #1
    storei r1, r2

    ; Define posição X
    loadn r1, #obstacle_x
    add r1, r1, r0
    loadn r2, #39
    storei r1, r2

spawn_obstacle_end:
    pop r2
    pop r1
    pop r0
    rts

check_collisions:
    push r0
    push r1
    push r2
    push r3
    push r4

    load r0, dino_y
    loadn r1, #27
    cmp r0, r1
    jne check_collisions_end  ; Dinossauro no ar, sem colisão

    ; Verifica colisão com obstáculos
    loadn r0, #0

check_collision_loop:
    loadn r1, #5
    cmp r0, r1
    jeg check_collisions_end

    loadn r1, #obstacle_active
    add r1, r1, r0
    loadi r2, r1

    loadn r3, #0
    cmp r2, r3
    jeq check_collision_next

    ; Verifica posição X do obstáculo
    loadn r1, #obstacle_x
    add r1, r1, r0
    loadi r2, r1

    ; Colisão se obstáculo está na posição 37-39
    loadn r3, #37
    cmp r2, r3
    jle check_collision_next

    loadn r3, #39
    cmp r2, r3
    jgr check_collision_next

    ; Colisão detectada!
    loadn r0, #1
    store game_over, r0
    jmp check_collisions_end

check_collision_next:
    inc r0
    jmp check_collision_loop

check_collisions_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

render_game:
    push r0
    push r1
    push r2

    ; Desenha chão
    call draw_ground

    ; Desenha dinossauro
    call draw_dino

    ; Desenha obstáculos
    call draw_obstacles

    ; Desenha pontuação
    call draw_score

    pop r2
    pop r1
    pop r0
    rts

draw_dino:
    push r0
    push r1
    push r2

    load r0, dino_pos
    loadn r1, #'D'
    loadn r2, #1024  ; Cor verde
    add r1, r1, r2
    outchar r1, r0

    pop r2
    pop r1
    pop r0
    rts

draw_obstacles:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r0, #0

draw_obstacles_loop:
    loadn r1, #5
    cmp r0, r1
    jeg draw_obstacles_end

    loadn r1, #obstacle_active
    add r1, r1, r0
    loadi r2, r1

    loadn r3, #0
    cmp r2, r3
    jeq draw_obstacles_next

    ; Calcula posição na tela
    loadn r1, #obstacle_x
    add r1, r1, r0
    loadi r2, r1

    loadn r3, #27  ; Linha do chão
    loadn r4, #40
    mul r3, r3, r4
    add r3, r3, r2

    ; Desenha obstáculo
    loadn r1, #'|'
    loadn r2, #2048  ; Cor vermelha
    add r1, r1, r2
    outchar r1, r3

draw_obstacles_next:
    inc r0
    jmp draw_obstacles_loop

draw_obstacles_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

draw_ground:
    push r0
    push r1
    push r2
    push r3

    loadn r0, #1120  ; Linha 28 (chão)
    loadn r1, #40    ; 40 colunas
    loadn r2, #'='
    loadn r3, #512   ; Cor marrom
    add r2, r2, r3

draw_ground_loop:
    outchar r2, r0
    inc r0
    dec r1
    loadn r3, #0
    cmp r1, r3
    jne draw_ground_loop

    pop r3
    pop r2
    pop r1
    pop r0
    rts

draw_score:
    push r0
    push r1
    push r2

    ; Desenha "SCORE: " na posição (0,0)
    loadn r0, #0
    loadn r1, #score_msg
    call print_string

    ; Desenha valor da pontuação
    loadn r0, #7
    load r1, score
    call print_number

    pop r2
    pop r1
    pop r0
    rts

draw_game_over:
    push r0
    push r1
    push r2

    ; Centraliza mensagem
    loadn r0, #600  ; Linha 15
    loadn r1, #game_over_msg
    call print_string

    pop r2
    pop r1
    pop r0
    rts

print_string:
    push r0
    push r1
    push r2
    push r3

    loadn r3, #'\0'

print_string_loop:
    loadi r2, r1
    cmp r2, r3
    jeq print_string_end

    outchar r2, r0
    inc r0
    inc r1
    jmp print_string_loop

print_string_end:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

print_number:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r2, #1000
    loadn r3, #10
    loadn r4, #'0'

print_number_loop:
    mod r5, r1, r2
    div r2, r2, r3
    div r5, r5, r2
    add r5, r5, r4
    outchar r5, r0
    inc r0

    loadn r5, #1
    cmp r2, r5
    jne print_number_loop

    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

clear_screen:
    push r0
    push r1
    push r2

    loadn r0, #0
    loadn r1, #' '
    loadn r2, #1200

clear_screen_loop:
    outchar r1, r0
    inc r0
    dec r2
    loadn r3, #0
    cmp r2, r3
    jne clear_screen_loop

    pop r2
    pop r1
    pop r0
    rts

input_wait:
    push r1

input_wait_loop:
    inchar r0
    loadn r1, #255
    cmp r0, r1
    jeq input_wait_loop

    pop r1
    rts

delay:
    push r0
    push r1

    load r0, game_speed
    loadn r1, #1000
    mul r0, r0, r1

delay_loop:
    dec r0
    loadn r1, #0
    cmp r0, r1
    jne delay_loop

    pop r1
    pop r0
    rts
