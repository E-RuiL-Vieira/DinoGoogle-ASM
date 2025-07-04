; ============================================================================
; JOGO DO DINOSSAURO PARA PROCESSADOR RISC 16-BIT
; Obstáculo reaparece baseado na velocidade atual (dinâmico)
; Reset quando passa de (10 - velocidade_atual)
; ============================================================================

jmp main

; ============================================================================
; VARIÁVEIS
; ============================================================================

dino_pos:         var #1
dino_y:           var #1
dino_jumping:     var #1
dino_jump_count:  var #1

obstacle_x:       var #1
obstacle_speed:   var #1

timer_seconds:    var #1
timer_frames:     var #1
game_over:        var #1
game_won:         var #1
game_start_delay: var #1

debug_mode:       var #1

; ============================================================================
; INICIALIZAÇÃO ESTÁTICA
; ============================================================================

static dino_pos         + #0, #890
static dino_y           + #0, #22
static dino_jumping     + #0, #0
static dino_jump_count  + #0, #0
static obstacle_x       + #0, #39
static obstacle_speed   + #0, #2
static timer_seconds    + #0, #0
static timer_frames     + #0, #0
static game_over        + #0, #0
static game_won         + #0, #0
static game_start_delay + #0, #20
static debug_mode       + #0, #0

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
debug_label:    string "OBST: "

; ============================================================================
; PROGRAMA PRINCIPAL
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
    loadn r0, #890
    store dino_pos, r0
    loadn r0, #22
    store dino_y, r0
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    loadn r0, #39
    store obstacle_x, r0
    loadn r1, #2
    store obstacle_speed, r1
    loadn r0, #0
    store timer_seconds, r0
    store timer_frames, r0
    store game_over, r0
    store game_won, r0
    loadn r0, #20
    store game_start_delay, r0
    loadn r0, #0
    store debug_mode, r0
    call draw_ground
    pop  r1
    pop  r0
    rts

; ============================================================================
; ENTRADA DO TECLADO
; ============================================================================

handle_input:
    push r0
    push r1
    inchar r0
    loadn r1, #255
    cmp   r0, r1
    jeq   end_handle_input
    loadn r1, #' '
    cmp   r0, r1
    jeq   start_jump
    loadn r1, #'r'
    cmp   r0, r1
    jeq   reset_in_game
    loadn r1, #'d'
    cmp   r0, r1
    jeq   toggle_debug
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
    jmp   end_handle_input

toggle_debug:
    load  r0, debug_mode
    loadn r1, #0
    cmp   r0, r1
    jeq   set_debug_on
    loadn r0, #0
    store debug_mode, r0
    jmp   end_handle_input
set_debug_on:
    loadn r0, #1
    store debug_mode, r0
    jmp   end_handle_input

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
    call update_timer
    load  r0, timer_seconds
    loadn r1, #99
    cmp   r0, r1
    jne   continue_game
    loadn r0, #1
    store game_won, r0
    jmp   end_update_game

continue_game:
    call update_dino_jump
    call update_obstacle
    call check_collision

end_update_game:
    pop r1
    pop r0
    rts

; ============================================================================
; TIMER
; ============================================================================

update_timer:
    push r0
    push r1
    load  r0, timer_frames
    inc   r0
    store timer_frames, r0
    loadn r1, #15
    cmp   r0, r1
    jne   end_update_timer
    loadn r0, #0
    store timer_frames, r0
    load  r0, timer_seconds
    inc   r0
    store timer_seconds, r0
end_update_timer:
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
    loadn r0, #22
    store dino_y, r0
    loadn r0, #890
    store dino_pos, r0
    jmp   end_update_dino_jump

dino_going_up:
    loadn r1, #19
    store dino_y, r1
    loadn r0, #770
    store dino_pos, r0
    jmp   end_update_dino_jump

dino_going_down:
    loadn r1, #20
    store dino_y, r1
    loadn r0, #810
    store dino_pos, r0
    jmp   end_update_dino_jump

end_update_dino_jump:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; ATUALIZAÇÃO DO OBSTÁCULO (CORRIGIDO: Reset baseado na velocidade atual)
; ============================================================================

update_obstacle:
    push r0
    push r1
    push r2

    ; Carrega posição atual e velocidade
    load  r0, obstacle_x
    load  r1, obstacle_speed

    ; Calcula nova posição: obstacle_x = obstacle_x - velocidade
    sub   r0, r0, r1

    ; Calcula limite inferior dinâmico: 10 - velocidade_atual
    loadn r2, #10
    sub   r2, r2, r1      ; r2 = 10 - velocidade_atual

    ; Verifica se passou do limite inferior
    cmp   r0, r2
    jle   reset_obstacle_x   ; Se obstacle_x <= limite_inferior, reseta

    ; Senão, armazena nova posição
    store obstacle_x, r0
    pop   r2
    pop   r1
    pop   r0
    rts

reset_obstacle_x:
    loadn r0, #39
    store obstacle_x, r0
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DETECÇÃO DE COLISÃO (CORRIGIDA: Usa intervalo dinâmico)
; ============================================================================

check_collision:
    push r0
    push r1
    push r2
    push r3

    ; Se debug mode ativo, pula colisão
    load  r0, debug_mode
    loadn r1, #1
    cmp   r0, r1
    jeq   end_check_collision

    ; Se dinossauro pulando, pula colisão
    load  r0, dino_jumping
    loadn r1, #0
    cmp   r0, r1
    jne   end_check_collision

    ; Se dinossauro não está no chão, pula colisão
    load  r0, dino_y
    loadn r1, #22
    cmp   r0, r1
    jne   end_check_collision

    ; COLISÃO POR INTERVALO DINÂMICO:
    ; limite_inferior = 10 - velocidade
    ; limite_superior = 10 + velocidade
    load  r0, obstacle_x
    load  r1, obstacle_speed

    ; Calcula limite inferior: 10 - velocidade
    loadn r2, #10
    sub   r2, r2, r1
    cmp   r0, r2
    jle   end_check_collision

    ; Calcula limite superior: 10 + velocidade
    loadn r3, #10
    add   r3, r3, r1
    cmp   r0, r3
    jeg   end_check_collision

    ; Se chegou aqui, há colisão!
    loadn r0, #1
    store game_over, r0

end_check_collision:
    pop r3
    pop r2
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
    call  draw_obstacle
    call  draw_timer
    call  draw_debug
    jmp   end_render_game

show_prepare:
    call draw_ground
    call draw_prepare

end_render_game:
    pop r0
    rts

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

draw_obstacle:
    push r0
    push r1
    push r2
    load  r1, obstacle_x
    loadn r2, #0
    cmp   r1, r2
    jle   end_draw_obstacle
    loadn r2, #39
    cmp   r1, r2
    jgr   end_draw_obstacle
    loadn r0, #880
    add   r0, r0, r1
    loadn r1, #'|'
    loadn r2, #2048
    add   r1, r1, r2
    outchar r1, r0
end_draw_obstacle:
    pop   r2
    pop   r1
    pop   r0
    rts

draw_debug:
    push r0
    push r1
    push r2
    load  r0, debug_mode
    loadn r1, #1
    cmp   r0, r1
    jne   end_draw_debug
    loadn r0, #1
    loadn r1, #debug_label
    call  print_string
    loadn r0, #7
    load  r1, obstacle_x
    call  print_number_2digits
end_draw_debug:
    pop   r2
    pop   r1
    pop   r0
    rts

draw_ground:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #920
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

draw_prepare:
    push r0
    push r1
    loadn r0, #480
    loadn r1, #prepare_msg
    call  print_string
    pop   r1
    pop   r0
    rts

draw_game_over:
    push r0
    push r1
    loadn r0, #560
    loadn r1, #game_over_msg
    call  print_string
    loadn r0, #600
    loadn r1, #timer_msg
    call  print_string
    loadn r0, #607
    load  r1, timer_seconds
    call  print_number_2digits
    pop   r1
    pop   r0
    rts

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
; AUXILIARES
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

input_wait:
    push r1
iw_loop:
    inchar r0
    loadn r1, #255
    cmp   r0, r1
    jeq   iw_loop
    pop r1
    rts

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
