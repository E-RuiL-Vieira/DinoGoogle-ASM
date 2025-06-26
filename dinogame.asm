jmp main

; Variáveis do jogo
dino_pos: var #1
dino_y: var #1
dino_jumping: var #1
dino_jump_count: var #1

obstacle_x: var #1
obstacle_active: var #1
obstacle_timer: var #1

timer_seconds: var #1
timer_frames: var #1
game_over: var #1
game_won: var #1
game_start_delay: var #1

static dino_pos + #0, #1090    ; Linha 27, coluna 10 (27*40 + 10 = 1090)
static dino_y + #0, #27        ; Y fixo na linha 27
static dino_jumping + #0, #0   ; Não está pulando
static dino_jump_count + #0, #0 ; Contador de pulo
static obstacle_x + #0, #0     ; Sem obstáculo inicial
static obstacle_active + #0, #0 ; Obstáculo inativo
static obstacle_timer + #0, #0 ; Timer para próximo obstáculo
static timer_seconds + #0, #0  ; Tempo inicial
static timer_frames + #0, #0   ; Frames do timer
static game_over + #0, #0      ; Jogo não terminou
static game_won + #0, #0       ; Jogo não ganho
static game_start_delay + #0, #20 ; Atraso inicial

; Strings do jogo
dino_char: string "D"
obstacle_char: string "|"
ground_char: string "="
space_char: string " "

game_over_msg: string "GAME OVER"
game_won_msg: string "VITORIA!"
timer_msg: string "TEMPO: "
prepare_msg: string "PREPARE-SE"

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

    load r0, game_won
    loadn r1, #1
    cmp r0, r1
    jeq game_won_screen

    jmp game_loop

game_over_screen:
    call clear_screen
    call draw_game_over
    call input_wait

    loadn r1, #'r'
    cmp r0, r1
    jeq restart_game

    jmp game_over_screen

game_won_screen:
    call clear_screen
    call draw_game_won
    call input_wait

    loadn r1, #'r'
    cmp r0, r1
    jeq restart_game

    jmp game_won_screen

restart_game:
    call init_game
    jmp game_loop

init_game:
    push r0
    push r1

    loadn r0, #1090
    store dino_pos, r0
    loadn r0, #27
    store dino_y, r0
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    store obstacle_x, r0
    store obstacle_active, r0
    store obstacle_timer, r0
    store timer_seconds, r0
    store timer_frames, r0
    store game_over, r0
    store game_won, r0

    loadn r0, #20
    store game_start_delay, r0

    ; Desenha chão
    call draw_ground

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

    ; Verifica atraso inicial
    load r0, game_start_delay
    loadn r1, #0
    cmp r0, r1
    jeq update_game_normal

    ; Se ainda estiver no atraso, decrementar e pular atualizações
    dec r0
    store game_start_delay, r0
    jmp update_game_end

update_game_normal:
    ; Atualiza timer
    call update_timer

    ; Verifica se ganhou (99 segundos)
    load r0, timer_seconds
    loadn r1, #99
    cmp r0, r1
    jne continue_game

    loadn r0, #1
    store game_won, r0
    jmp update_game_end

continue_game:
    ; Atualiza pulo do dinossauro
    call update_dino_jump

    ; NOVA LÓGICA: Atualiza obstáculos com posicionamento fixo
    call update_obstacle_new

    ; Verifica colisões
    call check_collisions

update_game_end:
    pop r1
    pop r0
    rts

update_timer:
    push r0
    push r1

    load r0, timer_frames
    inc r0
    store timer_frames, r0


    loadn r1, #15
    cmp r0, r1
    jne update_timer_end

    ; Reset frames e incrementa segundos
    loadn r0, #0
    store timer_frames, r0

    load r0, timer_seconds
    inc r0
    store timer_seconds, r0

update_timer_end:
    pop r1
    pop r0
    rts

update_dino_jump:
    push r0
    push r1
    push r2

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

    ; Termina o pulo -
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    loadn r0, #27
    store dino_y, r0
    loadn r0, #1090
    store dino_pos, r0

    jmp update_dino_jump_end

dino_going_up:
    loadn r1, #24
    store dino_y, r1
    loadn r0, #970
    store dino_pos, r0
    jmp update_dino_jump_end

dino_going_down:
    loadn r1, #25  ; Altura intermediária y=25
    store dino_y, r1
    loadn r0, #1010
    store dino_pos, r0

update_dino_jump_end:
    pop r2
    pop r1
    pop r0
    rts

update_obstacle_new:
    push r0
    push r1
    push r2

    load r0, obstacle_active
    loadn r1, #0
    cmp r0, r1
    jeq try_create_obstacle

    ; Move obstáculo para esquerda
    load r0, obstacle_x
    loadn r1, #2  ; Velocidade do obstáculo
    sub r0, r0, r1

    ; Verifica se saiu da tela
    loadn r1, #0
    cmp r0, r1
    jle deactivate_obstacle

    store obstacle_x, r0
    jmp update_obstacle_new_end

deactivate_obstacle:
    loadn r0, #0
    store obstacle_active, r0
    store obstacle_timer, r0
    jmp update_obstacle_new_end

try_create_obstacle:
    ; Incrementa timer
    load r0, obstacle_timer
    inc r0
    store obstacle_timer, r0

    ; Cria obstáculo a cada 60 frames
    loadn r1, #60
    cmp r0, r1
    jne update_obstacle_new_end

    ; Cria novo obstáculo
    loadn r0, #1
    store obstacle_active, r0
    loadn r0, #39
    store obstacle_x, r0
    loadn r0, #0
    store obstacle_timer, r0

update_obstacle_new_end:
    pop r2
    pop r1
    pop r0
    rts

check_collisions:
    push r0
    push r1
    push r2

    load r0, dino_y
    loadn r1, #27
    cmp r0, r1
    jne check_collisions_end  ; Dinossauro no ar, sem colisão

    load r0, obstacle_active
    loadn r1, #0
    cmp r0, r1
    jeq check_collisions_end  ; Sem obstáculo ativo

    ; Verifica posição X do obstáculo
    load r0, obstacle_x

    ; Colisão se obstáculo está nas posições 9-12 (dinossauro na 10)
    loadn r1, #9
    cmp r0, r1
    jle check_collisions_end

    loadn r1, #12
    cmp r0, r1
    jgr check_collisions_end

    ; Colisão detectada!
    loadn r0, #1
    store game_over, r0

check_collisions_end:
    pop r2
    pop r1
    pop r0
    rts

render_game:
    push r0

    ; Verifica se ainda está no atraso inicial
    load r0, game_start_delay
    loadn r1, #0
    cmp r0, r1
    jne show_prepare

    ; Renderização normal
    call draw_ground
    call draw_dino
    call draw_obstacle_new
    call draw_timer
    jmp render_game_end

show_prepare:
    call draw_ground
    call draw_prepare

render_game_end:
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

; NOVA FUNÇÃO: Desenha obstáculo com posição Y FIXA
draw_obstacle_new:
    push r0
    push r1
    push r2
    push r3

    load r0, obstacle_active
    loadn r1, #0
    cmp r0, r1
    jeq draw_obstacle_new_end

    load r1, obstacle_x  ; Carrega posição X
    loadn r0, #1080      ; FIXO: linha 27 * 40 = 1080
    add r0, r0, r1       ; Adiciona apenas X

    ; Desenha obstáculo
    loadn r1, #'|'
    loadn r2, #2048  ; Cor vermelha
    add r1, r1, r2
    outchar r1, r0

draw_obstacle_new_end:
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
    loadn r3, #512   ; Cor
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

draw_timer:
    push r0
    push r1
    push r2

    ; Desenha "TEMPO: " na posição (0,0)
    loadn r0, #0
    loadn r1, #timer_msg
    call print_string

    ; Desenha valor do timer
    loadn r0, #7
    load r1, timer_seconds
    call print_number_2digits

    pop r2
    pop r1
    pop r0
    rts

draw_prepare:
    push r0
    push r1

    ; Centraliza mensagem "PREPARE-SE"
    loadn r0, #600  ; Linha 15
    loadn r1, #prepare_msg
    call print_string

    pop r1
    pop r0
    rts

draw_game_over:
    push r0
    push r1

    ; "GAME OVER" centralizado
    loadn r0, #580  ; Linha 14
    loadn r1, #game_over_msg
    call print_string

    ; "TEMPO: XX" na linha seguinte
    loadn r0, #620  ; Linha 15
    loadn r1, #timer_msg
    call print_string

    loadn r0, #627  ; Posição após "TEMPO: "
    load r1, timer_seconds
    call print_number_2digits

    pop r1
    pop r0
    rts

draw_game_won:
    push r0
    push r1
    push r2

    ; "VITORIA!" centralizado em amarelo
    loadn r0, #580  ; Linha 14
    loadn r1, #game_won_msg
    call print_string_colored

    ; "TEMPO: 99" na linha seguinte
    loadn r0, #620  ; Linha 15
    loadn r1, #timer_msg
    call print_string

    loadn r0, #627
    loadn r1, #99
    call print_number_2digits

    pop r2
    pop r1
    pop r0
    rts

print_string:
    push r0
    push r1
    push r2
    push r3

    loadn r3, #0  ; Terminador nulo

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

print_string_colored:
    push r0
    push r1
    push r2
    push r3
    push r4

    loadn r3, #0     ; Terminador nulo
    loadn r4, #3072  ; Cor amarela

print_string_colored_loop:
    loadi r2, r1
    cmp r2, r3
    jeq print_string_colored_end

    add r2, r2, r4  ; Adiciona cor
    outchar r2, r0
    inc r0
    inc r1
    jmp print_string_colored_loop

print_string_colored_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

print_number_2digits:
    push r0
    push r1
    push r2
    push r3

    ; Dezena
    loadn r2, #10
    div r3, r1, r2
    loadn r2, #'0'
    add r3, r3, r2
    outchar r3, r0
    inc r0

    ; Unidade
    loadn r2, #10
    mod r3, r1, r2
    loadn r2, #'0'
    add r3, r3, r2
    outchar r3, r0

    pop r3
    pop r2
    pop r1
    pop r0
    rts

clear_screen:
    push r0
    push r1
    push r2
    push r3

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

    pop r3
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

    loadn r0, #1000

delay_loop:
    dec r0
    loadn r1, #0
    cmp r0, r1
    jne delay_loop

    pop r1
    pop r0
    rts
