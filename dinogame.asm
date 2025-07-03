; ============================================================================
; JOGO DO DINOSSAURO PARA PROCESSADOR RISC 16-BIT
; ----------------------------------------------------------------------------
; Tela: 40 colunas × 24 linhas (0–959)
; Linha 21: dinossauro e obstáculos
; Linha 22: chão (cheio de '=')
; Velocidade de obstáculos 1→5 a cada 20s
; Três obstáculos independentes (60,90,120 frames)
; Reset a qualquer momento com 'r'
; ============================================================================

jmp main                                        ; inicia o programa

; ============================================================================
; VARIÁVEIS
; ============================================================================

dino_pos:         var #1    ; posição absoluta do dinossauro (linha×40+coluna)
dino_y:           var #1    ; linha atual do dinossauro
dino_jumping:     var #1    ; 1=pulando, 0=chão
dino_jump_count:  var #1    ; conta frames do pulo

obstacle_x1:      var #1    ; coluna do obstáculo 1
obstacle_x2:      var #1    ; coluna do obstáculo 2
obstacle_x3:      var #1    ; coluna do obstáculo 3
obstacle_active1: var #1    ; 1=ativo, 0=inativo
obstacle_active2: var #1
obstacle_active3: var #1
obstacle_timer1:  var #1    ; frames até novo obstáculo 1
obstacle_timer2:  var #1    ; frames até novo obstáculo 2
obstacle_timer3:  var #1    ; frames até novo obstáculo 3
obstacle_speed:   var #1    ; velocidade atual (1–5)

timer_seconds:    var #1    ; segundos jogados
timer_frames:     var #1    ; frames contados para 1s
game_over:        var #1    ; 1=colidiu
game_won:         var #1    ; 1=99s atingidos
game_start_delay: var #1    ; frames de “PREPARE-SE”

; ============================================================================
; INICIALIZAÇÕES ESTÁTICAS
; ============================================================================

static dino_pos         + #0, #850   ; 21×40+10
static dino_y           + #0, #21
static dino_jumping     + #0, #0
static dino_jump_count  + #0, #0

static obstacle_x1      + #0, #0
static obstacle_x2      + #0, #0
static obstacle_x3      + #0, #0
static obstacle_active1 + #0, #0
static obstacle_active2 + #0, #0
static obstacle_active3 + #0, #0
static obstacle_timer1  + #0, #0
static obstacle_timer2  + #0, #0
static obstacle_timer3  + #0, #0
static obstacle_speed   + #0, #1

static timer_seconds    + #0, #0
static timer_frames     + #0, #0
static game_over        + #0, #0
static game_won         + #0, #0
static game_start_delay + #0, #20

; ============================================================================
; STRINGS
; ============================================================================

dino_char:      string "D"
obstacle_char:  string "|"
ground_char:    string "="
space_char:     string " "
game_over_msg:  string "GAME OVER"
game_won_msg:   string "VITORIA!"
timer_msg:      string "TEMPO: "
prepare_msg:    string "PREPARE-SE"

; ============================================================================
; INÍCIO DO PROGRAMA
; ============================================================================

main:
    call init_game

game_loop:
    call clear_screen
    call handle_input
    call update_game
    call render_game
    call delay
    load  r0, game_over
    loadn r1, #1
    cmp   r0, r1
    jeq   game_over_screen
    load  r0, game_won
    cmp   r0, r1
    jeq   game_won_screen
    jmp   game_loop

game_over_screen:
    call clear_screen
    call draw_game_over
    call input_wait
    loadn r1, #'r'
    cmp   r0, r1
    jeq   restart_game
    jmp   game_over_screen

game_won_screen:
    call clear_screen
    call draw_game_won
    call input_wait
    loadn r1, #'r'
    cmp   r0, r1
    jeq   restart_game
    jmp   game_won_screen

restart_game:
    call init_game
    jmp  game_loop

; ============================================================================
; INICIALIZAÇÃO
; ============================================================================

init_game:
    push r0
    push r1
    loadn r0, #850
    store dino_pos, r0
    loadn r0, #21
    store dino_y, r0
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    store obstacle_x1, r0
    store obstacle_x2, r0
    store obstacle_x3, r0
    store obstacle_active1, r0
    store obstacle_active2, r0
    store obstacle_active3, r0
    store obstacle_timer1, r0
    store obstacle_timer2, r0
    store obstacle_timer3, r0
    loadn r1, #1
    store obstacle_speed, r1
    store timer_seconds, r0
    store timer_frames, r0
    store game_over, r0
    store game_won, r0
    loadn r0, #20
    store game_start_delay, r0
    call draw_ground
    pop  r1
    pop  r0
    rts

; ============================================================================
; TRATAMENTO DE ENTRADA
; ============================================================================

handle_input:
    push r0
    push r1
    inchar r0                   ; lê teclado
    loadn r1, #255
    cmp   r0, r1
    jeq   end_handle_input
    loadn r1, #' '
    cmp   r0, r1
    jeq   start_jump
    loadn r1, #'r'
    cmp   r0, r1
    jeq   reset_in_game
    jmp   end_handle_input

start_jump:
    load  r0, dino_jumping
    loadn r1, #0
    cmp   r0, r1
    jne   end_handle_input
    loadn r0, #1
    store dino_jumping, r0
    loadn r0, #0
    store dino_jump_count, r0
    jmp   end_handle_input

reset_in_game:
    call init_game

end_handle_input:
    pop r1
    pop r0
    rts

; ============================================================================
; LÓGICA DO JOGO
; ============================================================================

update_game:
    push r0
    push r1
    load  r0, game_start_delay
    loadn r1, #0
    cmp   r0, r1
    jeq   update_game_normal
    dec   r0
    store game_start_delay, r0
    jmp   end_update_game

update_game_normal:
    call update_timer_with_speed
    load  r0, timer_seconds
    loadn r1, #99
    cmp   r0, r1
    jne   continue_game
    loadn r0, #1
    store game_won, r0
    jmp   end_update_game

continue_game:
    call update_dino_jump
    call update_obstacles
    call check_collisions

end_update_game:
    pop r1
    pop r0
    rts

; ============================================================================
; TIMER + VELOCIDADE
; ============================================================================

update_timer_with_speed:
    push r0
    push r1
    push r2
    load  r0, timer_frames
    inc   r0
    store timer_frames, r0
    loadn r1, #15               ; 15 frames = 1s
    cmp   r0, r1
    jne   end_update_timer_with_speed
    loadn r0, #0
    store timer_frames, r0
    load  r0, timer_seconds
    inc   r0
    store timer_seconds, r0
    loadn r1, #20               ; a cada 20s
    mod   r2, r0, r1
    loadn r1, #0
    cmp   r2, r1
    jne   end_update_timer_with_speed
    load  r1, obstacle_speed
    loadn r2, #5
    cmp   r1, r2
    jeg   end_update_timer_with_speed
    inc   r1
    store obstacle_speed, r1

end_update_timer_with_speed:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; PULO
; ============================================================================

update_dino_jump:
    push r0
    push r1
    push r2
    load  r0, dino_jumping
    loadn r1, #0
    cmp   r0, r1
    jeq   end_update_dino_jump
    load  r0, dino_jump_count
    inc   r0
    store dino_jump_count, r0
    loadn r1, #6
    cmp   r0, r1
    jle   dino_going_up
    loadn r1, #12
    cmp   r0, r1
    jle   dino_going_down
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    loadn r0, #21
    store dino_y, r0
    loadn r0, #850
    store dino_pos, r0
    jmp   end_update_dino_jump

dino_going_up:
    loadn r1, #18
    store dino_y, r1
    loadn r0, #730
    store dino_pos, r0
    jmp   end_update_dino_jump

dino_going_down:
    loadn r1, #19
    store dino_y, r1
    loadn r0, #770
    store dino_pos, r0

end_update_dino_jump:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; ATUALIZAÇÃO DE OBSTÁCULOS
; ============================================================================

update_obstacles:
    call update_obstacle1
    call update_obstacle2
    call update_obstacle3
    rts

; obstáculo 1 (60f)
update_obstacle1:
    push r0
    push r1
    push r2
    load  r0, obstacle_active1
    loadn r1, #0
    cmp   r0, r1
    jeq   try_create_obstacle1
    load  r0, obstacle_x1
    load  r1, obstacle_speed
    sub   r0, r0, r1
    jle   deactivate_obstacle1    ; X≤0?
    store obstacle_x1, r0         ; só grava se X>0
    pop   r2
    pop   r1
    pop   r0
    rts

deactivate_obstacle1:
    loadn r0, #0
    store obstacle_active1, r0
    store obstacle_x1, r0
    store obstacle_timer1, r0
    pop   r2
    pop   r1
    pop   r0
    rts

try_create_obstacle1:
    load  r0, obstacle_timer1
    inc   r0
    store obstacle_timer1, r0
    loadn r1, #60
    cmp   r0, r1
    jne   skip_ob1
    loadn r0, #1
    store obstacle_active1, r0
    loadn r0, #39
    store obstacle_x1, r0
    loadn r0, #0
    store obstacle_timer1, r0
skip_ob1:
    pop   r2
    pop   r1
    pop   r0
    rts

; obstáculo 2 (90f)
update_obstacle2:
    push r0
    push r1
    push r2
    load  r0, obstacle_active2
    loadn r1, #0
    cmp   r0, r1
    jeq   try_create_obstacle2
    load  r0, obstacle_x2
    load  r1, obstacle_speed
    sub   r0, r0, r1
    jle   deactivate_obstacle2
    store obstacle_x2, r0
    pop   r2
    pop   r1
    pop   r0
    rts

deactivate_obstacle2:
    loadn r0, #0
    store obstacle_active2, r0
    store obstacle_x2, r0
    store obstacle_timer2, r0
    pop   r2
    pop   r1
    pop   r0
    rts

try_create_obstacle2:
    load  r0, obstacle_timer2
    inc   r0
    store obstacle_timer2, r0
    loadn r1, #90
    cmp   r0, r1
    jne   skip_ob2
    loadn r0, #1
    store obstacle_active2, r0
    loadn r0, #39
    store obstacle_x2, r0
    loadn r0, #0
    store obstacle_timer2, r0
skip_ob2:
    pop   r2
    pop   r1
    pop   r0
    rts

; obstáculo 3 (120f)
update_obstacle3:
    push r0
    push r1
    push r2
    load  r0, obstacle_active3
    loadn r1, #0
    cmp   r0, r1
    jeq   try_create_obstacle3
    load  r0, obstacle_x3
    load  r1, obstacle_speed
    sub   r0, r0, r1
    jle   deactivate_obstacle3
    store obstacle_x3, r0
    pop   r2
    pop   r1
    pop   r0
    rts

deactivate_obstacle3:
    loadn r0, #0
    store obstacle_active3, r0
    store obstacle_x3, r0
    store obstacle_timer3, r0
    pop   r2
    pop   r1
    pop   r0
    rts

try_create_obstacle3:
    load  r0, obstacle_timer3
    inc   r0
    store obstacle_timer3, r0
    loadn r1, #120
    cmp   r0, r1
    jne   skip_ob3
    loadn r0, #1
    store obstacle_active3, r0
    loadn r0, #39
    store obstacle_x3, r0
    loadn r0, #0
    store obstacle_timer3, r0
skip_ob3:
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DETECÇÃO DE COLISÃO
; ============================================================================

check_collisions:
    push r0
    push r1
    load  r0, dino_y
    loadn r1, #21
    cmp   r0, r1
    jne   end_check_collisions

    load  r0, obstacle_active1
    loadn r1, #0
    cmp   r0, r1
    jeq   check2
    load  r0, obstacle_x1
    loadn r1, #10
    cmp   r0, r1
    jeq   collision_trigger

check2:
    load  r0, obstacle_active2
    loadn r1, #0
    cmp   r0, r1
    jeq   check3
    load  r0, obstacle_x2
    cmp   r0, r1
    jeq   collision_trigger

check3:
    load  r0, obstacle_active3
    loadn r1, #0
    cmp   r0, r1
    jeq   end_check_collisions
    load  r0, obstacle_x3
    cmp   r0, r1
    jeq   collision_trigger
    jmp   end_check_collisions

collision_trigger:
    loadn r0, #1
    store game_over, r0

end_check_collisions:
    pop r1
    pop r0
    rts

; ============================================================================
; RENDERIZAÇÃO
; ============================================================================

render_game:
    push r0
    load  r0, game_start_delay
    loadn r1, #0
    cmp   r0, r1
    jne   show_prepare
    call  draw_ground
    call  draw_dino
    call  draw_obstacles
    call  draw_timer
    call  draw_speed_indicator
    jmp   end_render_game

show_prepare:
    call draw_ground
    call draw_prepare

end_render_game:
    pop r0
    rts

; ============================================================================
; DESENHO DO DINOSSAURO
; ============================================================================

draw_dino:
    push r0
    push r1
    push r2
    load  r0, dino_pos
    loadn r1, #'D'
    loadn r2, #1024
    add   r1, r1, r2
    outchar r1, r0
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DESENHO DOS OBSTÁCULOS
; ============================================================================

draw_obstacles:
    call draw_obstacle1
    call draw_obstacle2
    call draw_obstacle3
    rts

draw_obstacle1:
    push r0
    push r1
    push r2
    load  r0, obstacle_active1
    loadn r1, #0
    cmp   r0, r1
    jeq   end_draw_ob1
    load  r1, obstacle_x1
    loadn r2, #0
    cmp   r1, r2
    jle   end_draw_ob1
    loadn r0, #840           ; 21×40
    add   r0, r0, r1
    loadn r1, #'|'
    loadn r2, #2048
    add   r1, r1, r2
    outchar r1, r0
end_draw_ob1:
    pop   r2
    pop   r1
    pop   r0
    rts

draw_obstacle2:
    push r0
    push r1
    push r2
    load  r0, obstacle_active2
    loadn r1, #0
    cmp   r0, r1
    jeq   end_draw_ob2
    load  r1, obstacle_x2
    loadn r2, #0
    cmp   r1, r2
    jle   end_draw_ob2
    loadn r0, #840
    add   r0, r0, r1
    loadn r1, #'|'
    loadn r2, #2048
    add   r1, r1, r2
    outchar r1, r0
end_draw_ob2:
    pop   r2
    pop   r1
    pop   r0
    rts

draw_obstacle3:
    push r0
    push r1
    push r2
    load  r0, obstacle_active3
    loadn r1, #0
    cmp   r0, r1
    jeq   end_draw_ob3
    load  r1, obstacle_x3
    loadn r2, #0
    cmp   r1, r2
    jle   end_draw_ob3
    loadn r0, #840
    add   r0, r0, r1
    loadn r1, #'|'
    loadn r2, #2048
    add   r1, r1, r2
    outchar r1, r0
end_draw_ob3:
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; INDICADOR DE VELOCIDADE
; ============================================================================

draw_speed_indicator:
    push r0
    push r1
    push r2
    loadn r0, #30
    loadn r1, #'V'
    outchar r1, r0
    inc   r0
    loadn r1, #':'
    outchar r1, r0
    inc   r0
    load  r1, obstacle_speed
    loadn r2, #'0'
    add   r1, r1, r2
    outchar r1, r0
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DESENHO DO CHÃO
; ============================================================================

draw_ground:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #880           ; 22×40
    loadn r1, #40
    loadn r2, #'='
    loadn r3, #512
    add   r2, r2, r3
dg_loop:
    outchar r2, r0
    inc   r0
    dec   r1
    loadn r3, #0
    cmp   r1, r3
    jne   dg_loop
    pop   r3
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DESENHO DO TIMER
; ============================================================================

draw_timer:
    push r0
    push r1
    push r2
    loadn r0, #0
    loadn r1, #timer_msg
    call  print_string
    loadn r0, #7
    load  r1, timer_seconds
    call  print_number_2digits
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; “PREPARE-SE”
; ============================================================================

draw_prepare:
    push r0
    push r1
    loadn r0, #480           ; linha 12
    loadn r1, #prepare_msg
    call  print_string
    pop   r1
    pop   r0
    rts

; ============================================================================
; GAME OVER
; ============================================================================

draw_game_over:
    push r0
    push r1
    loadn r0, #560           ; linha 14
    loadn r1, #game_over_msg
    call  print_string
    loadn r0, #600           ; linha 15
    loadn r1, #timer_msg
    call  print_string
    loadn r0, #607
    load  r1, timer_seconds
    call  print_number_2digits
    pop   r1
    pop   r0
    rts

; ============================================================================
; VITÓRIA
; ============================================================================

draw_game_won:
    push r0
    push r1
    push r2
    loadn r0, #560
    loadn r1, #game_won_msg
    call  print_string_colored
    loadn r0, #600
    loadn r1, #timer_msg
    call  print_string
    loadn r0, #607
    loadn r1, #99
    call  print_number_2digits
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; AUXILIAR: PRINT STRING
; ============================================================================

print_string:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #0
ps_loop:
    loadi r2, r1
    cmp   r2, r3
    jeq   ps_end
    outchar r2, r0
    inc   r0
    inc   r1
    jmp   ps_loop
ps_end:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; AUXILIAR: PRINT STRING COLORIDA
; ============================================================================

print_string_colored:
    push r0
    push r1
    push r2
    push r3
    push r4
    loadn r3, #0
    loadn r4, #3072
psc_loop:
    loadi r2, r1
    cmp   r2, r3
    jeq   psc_end
    add   r2, r2, r4
    outchar r2, r0
    inc   r0
    inc   r1
    jmp   psc_loop
psc_end:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; AUXILIAR: PRINT 2-DÍGITOS
; ============================================================================

print_number_2digits:
    push r0
    push r1
    push r2
    push r3
    loadn r2, #10
    div   r3, r1, r2
    loadn r2, #'0'
    add   r3, r3, r2
    outchar r3, r0
    inc   r0
    loadn r2, #10
    mod   r3, r1, r2
    loadn r2, #'0'
    add   r3, r3, r2
    outchar r3, r0
    pop   r3
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; AUXILIAR: CLEAR SCREEN (960 posições)
; ============================================================================

clear_screen:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #0
    loadn r1, #' '
    loadn r2, #960
cs_loop:
    outchar r1, r0
    inc   r0
    dec   r2
    loadn r3, #0
    cmp   r2, r3
    jne   cs_loop
    pop   r3
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; AUXILIAR: INPUT WAIT
; ============================================================================

input_wait:
    push r1
iw_loop:
    inchar r0
    loadn r1, #255
    cmp   r0, r1
    jeq   iw_loop
    pop r1
    rts

; ============================================================================
; AUXILIAR: DELAY
; ============================================================================

delay:
    push r0
    push r1
    loadn r0, #1000
dl_loop:
    dec   r0
    loadn r1, #0
    cmp   r0, r1
    jne   dl_loop
    pop   r1
    pop   r0
    rts
