; ============================================================================
; JOGO DO DINOSSAURO PARA PROCESSADOR RISC 16-BIT
; Obstáculo reaparece quando ultrapassa (10 − velocidade), colisão em intervalo
; ============================================================================

jmp main                ; desvia para a rotina principal

; ============================================================================
; VARIÁVEIS – cada var ocupa 1 palavra em RAM
; ============================================================================

dino_pos:         var #1 ; posição absoluta (linha*40+coluna)
dino_y:           var #1 ; linha atual do dinossauro
dino_jumping:     var #1 ; 1 = pulando, 0 = no chão
dino_jump_count:  var #1 ; contador de frames do pulo

obstacle_x:       var #1 ; coluna atual do obstáculo
obstacle_speed:   var #1 ; velocidade (1-5)

timer_seconds:    var #1 ; segundos transcorridos
timer_frames:     var #1 ; frames para contar 1 s (0-14)
game_over:        var #1 ; 1 = colisão / derrota
game_won:         var #1 ; 1 = 99 s alcançados
game_start_delay: var #1 ; frames de “PREPARE-SE”

debug_mode:       var #1 ; 1 = mostra valor de obstacle_x e ignora colisão

; ============================================================================
; INICIALIZAÇÃO ESTÁTICA (memória limpa ao reset)
; ============================================================================

static dino_pos         + #0, #890      ; 21*40 + 10
static dino_y           + #0, #22       ; linha 22 (chão é 22, dinossauro 21/19)
static dino_jumping     + #0, #0        ; começa no chão
static dino_jump_count  + #0, #0
static obstacle_x       + #0, #39       ; obstáculo na borda direita
static obstacle_speed   + #0, #2        ; velocidade fixa = 2 colunas por frame
static timer_seconds    + #0, #0
static timer_frames     + #0, #0
static game_over        + #0, #0
static game_won         + #0, #0
static game_start_delay + #0, #20       ; 20 frames (~1 s) de contagem inicial
static debug_mode       + #0, #0

; ============================================================================
; STRINGS – usadas por rotinas de texto
; ============================================================================

prepare_msg:    string "PREPARE-SE"
timer_msg:      string "TEMPO: "
game_over_msg:  string "GAME OVER"
debug_label:    string "OBST: "

; ============================================================================
; PROGRAMA PRINCIPAL
; ============================================================================

main:                           ; ponto de entrada
    call init_game              ; prepara todas as variáveis

game_loop:                      ; laço principal
    call clear_screen           ; limpa tela
    call handle_input           ; verifica teclado
    call update_game            ; lógica por frame
    call render_game            ; desenha tudo
    call delay                  ; espera ~ 1 ms p/ ritmo
    load  r0, game_over         ; checa derrota
    loadn r1, #1
    cmp   r0, r1
    jeq   game_over_screen
    load  r0, game_won          ; checa vitória
    cmp   r0, r1
    jeq   game_won_screen
    jmp   game_loop             ; continua jogando

; --- telas pós-jogo ---------------------------------------------------------

game_over_screen:
    call clear_screen
    call draw_game_over
    call input_wait             ; aguarda qualquer tecla
    loadn r1, #'r'
    cmp   r0, r1
    jeq   restart_game          ; reinicia se apertar ‘r’
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
; INICIALIZAÇÃO (reset das variáveis)
; ============================================================================

init_game:
    loadn r0, #890
    store dino_pos, r0          ; coluna 10, linha 22-1
    loadn r0, #22
    store dino_y, r0
    loadn r0, #0
    store dino_jumping, r0
    store dino_jump_count, r0
    loadn r0, #39
    store obstacle_x, r0        ; obstáculo na borda
    loadn r0, #2
    store obstacle_speed, r0
    store timer_seconds, r1     ; r1 ainda vale 0
    store timer_frames, r1
    store game_over, r1
    store game_won,  r1
    loadn r0, #20
    store game_start_delay, r0
    store debug_mode, r1
    call draw_ground
    rts

; ============================================================================
; ENTRADA DE TECLADO
; ============================================================================

handle_input:                   ; lê 1 tecla por frame
    inchar r0
    loadn  r1, #255
    cmp    r0, r1
    jeq    hi_end               ; nenhum caractere
    loadn  r1, #' '
    cmp    r0, r1
    jeq    hi_jump              ; espaço = pulo
    loadn  r1, #'d'
    cmp    r0, r1
    jeq    hi_toggle_debug
    loadn  r1, #'r'
    cmp    r0, r1
    jeq    hi_reset
hi_end:
    rts

hi_jump:                        ; inicia o pulo
    load  r0, dino_jumping
    jne   hi_end
    loadn r0, #1
    store dino_jumping, r0
    store dino_jump_count, r1   ; zera contador
    rts

hi_toggle_debug:                ; alterna modo debug
    load  r0, debug_mode
    loadn r1, #0
    cmp   r0, r1
    jeq   dbg_on
    store debug_mode, r1
    rts
dbg_on:
    loadn r0, #1
    store debug_mode, r0
    rts

hi_reset:                       ; tecla ‘r’ reinicia jogo
    call init_game
    rts

; ============================================================================
; ATUALIZAÇÃO DO JOGO POR FRAME
; ============================================================================

update_game:
    load  r0, game_start_delay
    jne   ug_ready
    call update_timer
    call update_dino_jump
    call update_obstacle
    call check_collision
    rts
ug_ready:
    dec   r0
    store game_start_delay, r0
    rts

; --- temporizador simples ---------------------------------------------------
update_timer:
    load  r0, timer_frames
    inc   r0
    store timer_frames, r0
    loadn r1, #15               ; 15 frames = 1 s
    cmp   r0, r1
    jne   ut_done
    store timer_frames, r1      ; r1=0
    load  r0, timer_seconds
    inc   r0
    store timer_seconds, r0
ut_done:
    rts

; --- lógica de pulo ---------------------------------------------------------
update_dino_jump:
    load  r0, dino_jumping
    jeq   uj_done               ; se não pulando, sai
    load  r0, dino_jump_count
    inc   r0
    store dino_jump_count, r0
    loadn r1, #6
    cmp   r0, r1
    jle   uj_up                 ; 0-6 → subindo
    loadn r1, #12
    cmp   r0, r1
    jle   uj_down               ; 7-12 → descendo
    loadn r0, #0                ; >12 encerra pulo
    store dino_jumping, r0
    store dino_jump_count, r0
    loadn r0, #22
    store dino_y, r0
    loadn r0, #890
    store dino_pos, r0
    rts
uj_up:
    loadn r1, #19               ; linha 19 (3 acima)
    store dino_y, r1
    loadn r0, #770              ; 19*40+10
    store dino_pos, r0
    rts
uj_down:
    loadn r1, #20               ; linha 20 (descendo)
    store dino_y, r1
    loadn r0, #810
    store dino_pos, r0
uj_done:
    rts

; ============================================================================
; ATUALIZA OBSTÁCULO – wrap-around dinâmico (10-velocidade)
; ============================================================================

update_obstacle:
    push r0
    push r1
    push r2
    load  r0, obstacle_x        ; r0 = X atual
    load  r1, obstacle_speed    ; r1 = velocidade
    sub   r0, r0, r1            ; r0 = X – vel
    ; limite_inferior = 10 − vel
    loadn r2, #10
    sub   r2, r2, r1
    cmp   r0, r2
    jle   obs_reset             ; se passou, volta para 39
    store obstacle_x, r0
    pop   r2
    pop   r1
    pop   r0
    rts
obs_reset:
    loadn r0, #39               ; reaparece na borda
    store obstacle_x, r0
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DETECÇÃO DE COLISÃO – intervalo dinâmico 10 ± velocidade
; ============================================================================

check_collision:
    push r0
    push r1
    push r2
    push r3
    load  r0, debug_mode
    jne   col_end               ; debug desativa colisão
    load  r0, dino_jumping
    jne   col_end               ; se pulando, sem colisão
    load  r0, dino_y
    loadn r1, #22
    cmp   r0, r1
    jne   col_end               ; dinossauro deve estar no chão
    load  r0, obstacle_x
    load  r1, obstacle_speed
    loadn r2, #10
    sub   r2, r2, r1            ; limite inferior
    cmp   r0, r2
    jle   col_end
    loadn r3, #10
    add   r3, r3, r1            ; limite superior
    cmp   r0, r3
    jgr   col_end
    loadn r0, #1                ; dentro do intervalo ⇒ colisão
    store game_over, r0
col_end:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; RENDERIZAÇÃO – desenha solo, dino, obstáculo, timer e debug
; ============================================================================

render_game:
    load  r0, game_start_delay
    jne   render_prepare
    call draw_ground
    call draw_dino
    call draw_obstacle
    call draw_timer
    call draw_debug
    rts
render_prepare:
    call draw_ground
    call draw_prepare
    rts

; --- desenho das entidades --------------------------------------------------

draw_dino:
    load  r0, dino_pos
    loadn r1, #'D'
    loadn r2, #1024
    add   r1, r1, r2            ; cor branca (bit 10)
    outchar r1, r0
    rts

draw_obstacle:
    push r0
    push r1
    push r2
    load  r1, obstacle_x
    loadn r2, #1
    cmp   r1, r2
    jle   do_end                ; 0-1 ficam fora da tela
    loadn r2, #39
    cmp   r1, r2
    jgr   do_end
    loadn r0, #880              ; linha 22-1
    add   r0, r0, r1
    loadn r1, #'|'
    loadn r2, #2048
    add   r1, r1, r2            ; cor verde (bit 11)
    outchar r1, r0
do_end:
    pop   r2
    pop   r1
    pop   r0
    rts

; --- chão -------------------------------------------------------------------

draw_ground:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #920              ; linha 23
    loadn r1, #40               ; 40 colunas
    loadn r2, #'='
    loadn r3, #512
    add   r2, r2, r3            ; cor cinza
dg_loop:
    outchar r2, r0
    inc   r0
    dec   r1
    jne   dg_loop
    pop   r3
    pop   r2
    pop   r1
    pop   r0
    rts

draw_timer:
    loadn r0, #0
    loadn r1, #timer_msg
    call print_string
    loadn r0, #7
    load  r1, timer_seconds
    call print_number_2digits
    rts

draw_debug:
    load  r0, debug_mode
    jeq   dd_end
    loadn r0, #1
    loadn r1, #debug_label
    call print_string
    loadn r0, #7
    load  r1, obstacle_x
    call print_number_2digits
dd_end:
    rts

draw_prepare:
    loadn r0, #480
    loadn r1, #prepare_msg
    call print_string
    rts

draw_game_over:
    loadn r0, #560
    loadn r1, #game_over_msg
    call print_string
    rts

; ============================================================================
; ROTINAS DE TEXTO – mesmas do arquivo original
; ============================================================================

print_string:          ; percorre string até byte 0
    push r2
ps_loop:
    loadi r2, r1
    jne   ps_out
    pop   r2
    rts
ps_out:
    outchar r2, r0
    inc   r0
    inc   r1
    jmp   ps_loop

print_number_2digits:  ; imprime número 00-99
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
    rts

; ============================================================================
; CLEAR SCREEN  – preenche espaço em 960 posições
; ============================================================================

clear_screen:
    push r0
    push r1
    loadn r0, #0
    loadn r1, #' '
    push r2
    loadn r2, #960
cs_loop:
    outchar r1, r0
    inc     r0
    dec     r2
    jne     cs_loop
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; DELAY – simples espera ocupada
; ============================================================================

delay:
    loadn r0, #800
dloop:
    dec   r0
    jne   dloop
    rts

; ============================================================================
; INPUT_WAIT – bloqueia até tecla ≠ 255
; ============================================================================

input_wait:
iw_loop:
    inchar r0
    loadn r1, #255
    cmp   r0, r1
    jeq   iw_loop
    rts
