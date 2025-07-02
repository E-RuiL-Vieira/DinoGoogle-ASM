; ============================================================================
; JOGO DO DINOSSAURO PARA PROCESSADOR RISC 16-BIT
; ============================================================================
; Este programa implementa um jogo estilo "dinossauro do Chrome" para um
; processador RISC de 16 bits com 8 registradores (r0-r7).
; O objetivo é sobreviver por 99 segundos pulando sobre obstáculos.
; A velocidade aumenta a cada 20 segundos, de 1 até 5.
; ============================================================================

jmp main                        ; Salta para o início do programa principal

; ============================================================================
; DECLARAÇÃO DE VARIÁVEIS DO JOGO
; ============================================================================

; --- Variáveis do Dinossauro ---
dino_pos: var #1                ; Posição absoluta do dinossauro na tela
dino_y: var #1                  ; Coordenada Y (linha) do dinossauro
dino_jumping: var #1            ; Flag: 1 = pulando, 0 = no chão
dino_jump_count: var #1         ; Contador de frames do pulo

; --- Variáveis dos Obstáculos ---
obstacle_x: var #1              ; Posição horizontal do obstáculo
obstacle_active: var #1         ; Flag: 1 = obstáculo ativo, 0 = inativo
obstacle_timer: var #1          ; Contador para criação de novos obstáculos
obstacle_speed: var #1          ; Velocidade de movimento do obstáculo

; --- Variáveis do Sistema de Jogo ---
timer_seconds: var #1           ; Contador de segundos transcorridos
timer_frames: var #1            ; Contador de frames para calcular segundos
game_over: var #1               ; Flag: 1 = jogo terminou, 0 = jogando
game_won: var #1                ; Flag: 1 = jogador venceu, 0 = jogando
game_start_delay: var #1        ; Contador de atraso inicial

; ============================================================================
; INICIALIZAÇÕES ESTÁTICAS
; ============================================================================

static dino_pos + #0, #1090     ; Define posição inicial: linha 27, coluna 10
static dino_y + #0, #27         ; Define linha inicial do dinossauro
static dino_jumping + #0, #0    ; Define estado inicial: não pulando
static dino_jump_count + #0, #0 ; Define contador de pulo inicial
static obstacle_x + #0, #0      ; Define posição inicial do obstáculo
static obstacle_active + #0, #0 ; Define estado inicial: obstáculo inativo
static obstacle_timer + #0, #0  ; Define timer inicial de obstáculos
static obstacle_speed + #0, #1  ; Define velocidade inicial
static timer_seconds + #0, #0   ; Define tempo inicial: 0 segundos
static timer_frames + #0, #0    ; Define contador de frames inicial
static game_over + #0, #0       ; Define estado inicial: jogo não terminou
static game_won + #0, #0        ; Define estado inicial: jogador não venceu
static game_start_delay + #0, #20 ; Define atraso inicial de 20 frames

; ============================================================================
; DECLARAÇÃO DE STRINGS
; ============================================================================

dino_char: string "D"           ; Caractere que representa o dinossauro
obstacle_char: string "|"       ; Caractere que representa obstáculos
ground_char: string "="         ; Caractere que representa o chão
space_char: string " "          ; Caractere espaço para limpar tela
game_over_msg: string "GAME OVER" ; Mensagem de fim de jogo
game_won_msg: string "VITORIA!" ; Mensagem de vitória
timer_msg: string "TEMPO: "     ; Texto do contador de tempo
prepare_msg: string "PREPARE-SE" ; Mensagem de preparação inicial

; ============================================================================
; PROGRAMA PRINCIPAL
; ============================================================================

main:
    call init_game              ; Chama função de inicialização do jogo

game_loop:
    call clear_screen           ; Chama função para limpar toda a tela
    call handle_input           ; Chama função para processar entrada do teclado
    call update_game            ; Chama função para atualizar lógica do jogo
    call render_game            ; Chama função para desenhar elementos na tela
    call delay                  ; Chama função para controlar velocidade do jogo
    load r0, game_over          ; Carrega flag de game over no registrador r0
    loadn r1, #1                ; Carrega valor 1 no registrador r1
    cmp r0, r1                  ; Compara r0 com r1 (game_over == 1?)
    jeq game_over_screen        ; Salta para tela de game over se igual
    load r0, game_won           ; Carrega flag de vitória no registrador r0
    loadn r1, #1                ; Carrega valor 1 no registrador r1
    cmp r0, r1                  ; Compara r0 com r1 (game_won == 1?)
    jeq game_won_screen         ; Salta para tela de vitória se igual
    jmp game_loop               ; Salta de volta para o início do loop principal

game_over_screen:
    call clear_screen           ; Chama função para limpar a tela
    call draw_game_over         ; Chama função para desenhar mensagem de game over
    call input_wait             ; Chama função para esperar entrada do usuário
    loadn r1, #'r'              ; Carrega código ASCII da tecla 'r' em r1
    cmp r0, r1                  ; Compara tecla pressionada com 'r'
    jeq restart_game            ; Salta para reiniciar se pressionou 'r'
    jmp game_over_screen        ; Salta de volta para tela de game over

game_won_screen:
    call clear_screen           ; Chama função para limpar a tela
    call draw_game_won          ; Chama função para desenhar mensagem de vitória
    call input_wait             ; Chama função para esperar entrada do usuário
    loadn r1, #'r'              ; Carrega código ASCII da tecla 'r' em r1
    cmp r0, r1                  ; Compara tecla pressionada com 'r'
    jeq restart_game            ; Salta para reiniciar se pressionou 'r'
    jmp game_won_screen         ; Salta de volta para tela de vitória

restart_game:
    call init_game              ; Chama função para reinicializar todas as variáveis
    jmp game_loop               ; Salta para o loop principal do jogo

; ============================================================================
; FUNÇÃO DE INICIALIZAÇÃO DO JOGO
; ============================================================================

init_game:
    push r0
    push r1
    loadn r0, #1090             ; Carrega posição inicial em r0
    store dino_pos, r0          ; Armazena posição inicial na variável dino_pos
    loadn r0, #27               ; Carrega linha inicial em r0
    store dino_y, r0            ; Armazena linha inicial na variável dino_y
    loadn r0, #0                ; Carrega valor 0 em r0
    store dino_jumping, r0      ; Define dinossauro como não pulando
    store dino_jump_count, r0   ; Zera contador de pulo
    store obstacle_x, r0        ; Zera posição X do obstáculo
    store obstacle_active, r0   ; Define obstáculo como inativo
    store obstacle_timer, r0    ; Zera timer de obstáculos
    loadn r1, #1                ; Carrega velocidade inicial em r1
    store obstacle_speed, r1    ; Define velocidade inicial do obstáculo
    store timer_seconds, r0     ; Zera contador de segundos
    store timer_frames, r0      ; Zera contador de frames
    store game_over, r0         ; Define jogo como não terminado
    store game_won, r0          ; Define jogador como não vencedor
    loadn r0, #20               ; Carrega atraso inicial em r0
    store game_start_delay, r0  ; Define atraso inicial
    call draw_ground            ; Chama função para desenhar o chão
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE TRATAMENTO DE ENTRADA DO TECLADO
; ============================================================================

handle_input:
    push r0
    push r1
    inchar r0                   ; Lê caractere do teclado para r0
    loadn r1, #255              ; Carrega código "nenhuma tecla" em r1
    cmp r0, r1                  ; Compara tecla lida com código "nenhuma tecla"
    jeq end_handle_input        ; Salta para fim se nenhuma tecla pressionada
    loadn r1, #' '              ; Carrega código ASCII da tecla espaço em r1
    cmp r0, r1                  ; Compara tecla lida com espaço
    jeq start_jump              ; Salta para iniciar pulo se espaço
    loadn r1, #'r'              ; Carrega código ASCII da tecla 'r' em r1
    cmp r0, r1                  ; Compara tecla lida com 'r'
    jeq reset_in_game           ; Salta para reset se 'r'
    jmp end_handle_input        ; Salta para fim se outra tecla

start_jump:
    load r0, dino_jumping       ; Carrega estado de pulo em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara estado atual com 0 (não pulando)
    jne end_handle_input        ; Salta para fim se já está pulando
    loadn r0, #1                ; Carrega valor 1 em r0
    store dino_jumping, r0      ; Define dinossauro como pulando
    loadn r0, #0                ; Carrega valor 0 em r0
    store dino_jump_count, r0   ; Zera contador de frames do pulo
    jmp end_handle_input        ; Salta para fim da função

reset_in_game:
    call init_game              ; Chama função de inicialização
    jmp end_handle_input        ; Salta para fim da função

end_handle_input:
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO PRINCIPAL DE ATUALIZAÇÃO DO JOGO
; ============================================================================

update_game:
    push r0
    push r1
    load r0, game_start_delay   ; Carrega contador de atraso em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara atraso com 0
    jeq update_game_normal      ; Salta para atualização normal se zero
    dec r0                      ; Decrementa contador de atraso
    store game_start_delay, r0  ; Armazena novo valor de atraso
    jmp end_update_game         ; Salta para fim da função

update_game_normal:
    call update_timer_with_speed ; Chama função de atualização do timer
    load r0, timer_seconds      ; Carrega segundos transcorridos em r0
    loadn r1, #99               ; Carrega valor 99 em r1
    cmp r0, r1                  ; Compara segundos com 99
    jne continue_game           ; Salta para continuar se não igual
    loadn r0, #1                ; Carrega valor 1 em r0
    store game_won, r0          ; Define jogador como vencedor
    jmp end_update_game         ; Salta para fim da função

continue_game:
    call update_dino_jump       ; Chama função de atualização do pulo
    call update_obstacles       ; Chama função de atualização dos obstáculos
    call check_collisions       ; Chama função de detecção de colisões

end_update_game:
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE ATUALIZAÇÃO DO TIMER COM SISTEMA DE VELOCIDADE
; ============================================================================

update_timer_with_speed:
    push r0
    push r1
    push r2
    load r0, timer_frames       ; Carrega contador de frames em r0
    inc r0                      ; Incrementa contador de frames
    store timer_frames, r0      ; Armazena novo valor de frames
    loadn r1, #15               ; Carrega valor 15 em r1 (frames por segundo)
    cmp r0, r1                  ; Compara frames com 15
    jne end_update_timer_with_speed ; Salta para fim se não completou 1 segundo
    loadn r0, #0                ; Carrega valor 0 em r0
    store timer_frames, r0      ; Zera contador de frames
    load r0, timer_seconds      ; Carrega contador de segundos em r0
    inc r0                      ; Incrementa contador de segundos
    store timer_seconds, r0     ; Armazena novo valor de segundos
    ; Velocidade aumenta a cada 20 segundos
    loadn r1, #20               ; Carrega valor 20 em r1
    mod r2, r0, r1              ; Calcula resto da divisão por 20
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r2, r1                  ; Compara resto com 0
    jne end_update_timer_with_speed ; Salta para fim se não é múltiplo de 20
    ; Velocidade máxima é 5
    load r1, obstacle_speed     ; Carrega velocidade atual em r1
    loadn r2, #5                ; Carrega velocidade máxima em r2
    cmp r1, r2                  ; Compara velocidade atual com máxima
    jeg end_update_timer_with_speed ; Salta para fim se já no máximo
    inc r1                      ; Incrementa velocidade
    store obstacle_speed, r1    ; Armazena nova velocidade

end_update_timer_with_speed:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE ATUALIZAÇÃO DO PULO DO DINOSSAURO
; ============================================================================

update_dino_jump:
    push r0
    push r1
    push r2
    load r0, dino_jumping       ; Carrega estado de pulo em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara estado com 0 (não pulando)
    jeq end_update_dino_jump    ; Salta para fim se não está pulando
    load r0, dino_jump_count    ; Carrega contador de pulo em r0
    inc r0                      ; Incrementa contador de pulo
    store dino_jump_count, r0   ; Armazena novo valor do contador
    loadn r1, #6                ; Carrega valor 6 em r1 (fim da subida)
    cmp r0, r1                  ; Compara contador com 6
    jle dino_going_up           ; Salta para subida se menor ou igual
    loadn r1, #12               ; Carrega valor 12 em r1 (fim da descida)
    cmp r0, r1                  ; Compara contador com 12
    jle dino_going_down         ; Salta para descida se menor ou igual
    loadn r0, #0                ; Carrega valor 0 em r0
    store dino_jumping, r0      ; Define dinossauro como não pulando
    store dino_jump_count, r0   ; Zera contador de pulo
    loadn r0, #27               ; Carrega linha do chão em r0
    store dino_y, r0            ; Define dinossauro no chão
    loadn r0, #1090             ; Carrega posição absoluta em r0
    store dino_pos, r0          ; Define posição absoluta do dinossauro
    jmp end_update_dino_jump    ; Salta para fim da função

dino_going_up:
    loadn r1, #24               ; Carrega linha 24 em r1 (altura máxima)
    store dino_y, r1            ; Define nova altura do dinossauro
    loadn r0, #970              ; Carrega posição absoluta em r0 (24*40+10)
    store dino_pos, r0          ; Define nova posição absoluta
    jmp end_update_dino_jump    ; Salta para fim da função

dino_going_down:
    loadn r1, #25               ; Carrega linha 25 em r1 (altura intermediária)
    store dino_y, r1            ; Define nova altura do dinossauro
    loadn r0, #1010             ; Carrega posição absoluta em r0 (25*40+10)
    store dino_pos, r0          ; Define nova posição absoluta

end_update_dino_jump:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE ATUALIZAÇÃO DOS OBSTÁCULOS
; ============================================================================

update_obstacles:
    push r0
    push r1
    push r2
    load r0, obstacle_active    ; Carrega flag de obstáculo ativo em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara flag com 0 (inativo)
    jeq try_create_obstacle     ; Salta para criar se inativo
    load r0, obstacle_x         ; Carrega posição X do obstáculo em r0
    load r1, obstacle_speed     ; Carrega velocidade em r1
    sub r0, r0, r1              ; Subtrai velocidade da posição X
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara posição X com 0
    jle deactivate_obstacle     ; Salta para desativar se saiu da tela
    store obstacle_x, r0        ; Armazena nova posição X
    jmp end_update_obstacles    ; Salta para fim da função

deactivate_obstacle:
    loadn r0, #0                ; Carrega valor 0 em r0
    store obstacle_x, r0        ; Zera posição X do obstáculo
    store obstacle_active, r0   ; Define obstáculo como inativo
    store obstacle_timer, r0    ; Zera timer de obstáculos
    jmp end_update_obstacles    ; Salta para fim da função

try_create_obstacle:
    load r0, obstacle_timer     ; Carrega timer de obstáculos em r0
    inc r0                      ; Incrementa timer
    store obstacle_timer, r0    ; Armazena novo valor do timer
    loadn r1, #60               ; Carrega valor 60 em r1 (intervalo)
    cmp r0, r1                  ; Compara timer com 60
    jne end_update_obstacles    ; Salta para fim se não chegou no intervalo
    loadn r0, #1                ; Carrega valor 1 em r0
    store obstacle_active, r0   ; Define obstáculo como ativo
    loadn r0, #39               ; Carrega posição X inicial em r0
    store obstacle_x, r0        ; Define posição X do obstáculo
    loadn r0, #0                ; Carrega valor 0 em r0
    store obstacle_timer, r0    ; Zera timer de obstáculos

end_update_obstacles:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DETECÇÃO DE COLISÕES
; ============================================================================

check_collisions:
    push r0
    push r1
    push r2
    load r0, dino_y             ; Carrega altura do dinossauro em r0
    loadn r1, #27               ; Carrega linha 27 em r1 (chão)
    cmp r0, r1                  ; Compara altura com linha do chão
    jne end_check_collisions    ; Salta para fim se não está no chão
    load r0, obstacle_active    ; Carrega flag de obstáculo ativo em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara flag com 0 (inativo)
    jeq end_check_collisions    ; Salta para fim se obstáculo inativo
    load r0, obstacle_x         ; Carrega posição X do obstáculo em r0
    loadn r1, #9                ; Carrega limite inferior em r1
    cmp r0, r1                  ; Compara posição X com limite inferior
    jle end_check_collisions    ; Salta para fim se passou do dinossauro
    loadn r1, #12               ; Carrega limite superior em r1
    cmp r0, r1                  ; Compara posição X com limite superior
    jgr end_check_collisions    ; Salta para fim se ainda distante
    loadn r0, #1                ; Carrega valor 1 em r0
    store game_over, r0         ; Define jogo como terminado por colisão

end_check_collisions:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO PRINCIPAL DE RENDERIZAÇÃO
; ============================================================================

render_game:
    push r0
    load r0, game_start_delay   ; Carrega contador de atraso em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara atraso com 0
    jne show_prepare            ; Salta para mostrar preparação se há atraso
    call draw_ground            ; Chama função para desenhar chão
    call draw_dino              ; Chama função para desenhar dinossauro
    call draw_obstacles         ; Chama função para desenhar obstáculos
    call draw_timer             ; Chama função para desenhar timer
    call draw_speed_indicator   ; Chama função para desenhar indicador de velocidade
    jmp end_render_game         ; Salta para fim da função

show_prepare:
    call draw_ground            ; Chama função para desenhar chão
    call draw_prepare           ; Chama função para desenhar mensagem de preparação

end_render_game:
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DO DINOSSAURO
; ============================================================================

draw_dino:
    push r0
    push r1
    push r2
    load r0, dino_pos           ; Carrega posição absoluta do dinossauro em r0
    loadn r1, #'D'              ; Carrega código ASCII do caractere 'D' em r1
    loadn r2, #1024             ; Carrega código de cor verde em r2
    add r1, r1, r2              ; Adiciona cor ao caractere
    outchar r1, r0
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DOS OBSTÁCULOS
; ============================================================================

draw_obstacles:
    push r0
    push r1
    push r2
    push r3
    load r0, obstacle_active    ; Carrega flag de obstáculo ativo em r0
    loadn r1, #0                ; Carrega valor 0 em r1
    cmp r0, r1                  ; Compara flag com 0 (inativo)
    jeq end_draw_obstacles      ; Salta para fim se obstáculo inativo
    load r1, obstacle_x         ; Carrega posição X do obstáculo em r1
    loadn r0, #1080             ; Carrega base da linha 27 em r0 (27*40=1080)
    add r0, r0, r1              ; Adiciona posição X à base da linha
    loadn r1, #'|'              ; Carrega código ASCII do caractere '|' em r1
    loadn r2, #2048             ; Carrega código de cor vermelha em r2
    add r1, r1, r2              ; Adiciona cor ao caractere
    outchar r1, r0

end_draw_obstacles:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DO INDICADOR DE VELOCIDADE
; ============================================================================

draw_speed_indicator:
    push r0
    push r1
    push r2
    loadn r0, #30               ; Carrega posição inicial em r0 (coluna 30)
    loadn r1, #'V'              ; Carrega código ASCII do caractere 'V' em r1
    outchar r1, r0
    inc r0                      ; Incrementa posição para próximo caractere
    loadn r1, #':'              ; Carrega código ASCII do caractere ':' em r1
    outchar r1, r0
    inc r0                      ; Incrementa posição para próximo caractere
    load r1, obstacle_speed     ; Carrega velocidade atual em r1
    loadn r2, #'0'              ; Carrega código ASCII do caractere '0' em r2
    add r1, r1, r2              ; Converte velocidade para código ASCII
    outchar r1, r0
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DO CHÃO
; ============================================================================

draw_ground:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #1120             ; Carrega posição inicial da linha 28 em r0
    loadn r1, #40               ; Carrega largura da tela em r1 (40 colunas)
    loadn r2, #'='              ; Carrega código ASCII do caractere '=' em r2
    loadn r3, #512              ; Carrega código de cor marrom em r3
    add r2, r2, r3              ; Adiciona cor ao caractere

draw_ground_loop:
    outchar r2, r0              ; Escreve caractere colorido na posição atual
    inc r0                      ; Incrementa posição para próxima coluna
    dec r1                      ; Decrementa contador de colunas
    loadn r3, #0                ; Carrega valor 0 em r3 para comparação
    cmp r1, r3                  ; Compara contador com 0
    jne draw_ground_loop        ; Continua loop se ainda há colunas
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DO TIMER
; ============================================================================

draw_timer:
    push r0
    push r1
    push r2
    loadn r0, #0                ; Carrega posição inicial em r0 (canto superior esquerdo)
    loadn r1, #timer_msg        ; Carrega endereço da string "TEMPO: " em r1
    call print_string           ; Chama função para imprimir string
    loadn r0, #7                ; Carrega posição após "TEMPO: " em r0
    load r1, timer_seconds      ; Carrega valor dos segundos em r1
    call print_number_2digits   ; Chama função para imprimir número com 2 dígitos
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DA MENSAGEM DE PREPARAÇÃO
; ============================================================================

draw_prepare:
    push r0
    push r1
    loadn r0, #600              ; Carrega posição central da tela em r0
    loadn r1, #prepare_msg      ; Carrega endereço da string "PREPARE-SE" em r1
    call print_string           ; Chama função para imprimir string
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DA TELA DE GAME OVER
; ============================================================================

draw_game_over:
    push r0
    push r1
    loadn r0, #580              ; Carrega posição central em r0
    loadn r1, #game_over_msg    ; Carrega endereço da string "GAME OVER" em r1
    call print_string           ; Chama função para imprimir string
    loadn r0, #620              ; Carrega posição da linha seguinte em r0
    loadn r1, #timer_msg        ; Carrega endereço da string "TEMPO: " em r1
    call print_string           ; Chama função para imprimir string
    loadn r0, #627              ; Carrega posição após "TEMPO: " em r0
    load r1, timer_seconds      ; Carrega segundos alcançados em r1
    call print_number_2digits   ; Chama função para imprimir número
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO DE DESENHO DA TELA DE VITÓRIA
; ============================================================================

draw_game_won:
    push r0
    push r1
    push r2
    loadn r0, #580              ; Carrega posição central em r0
    loadn r1, #game_won_msg     ; Carrega endereço da string "VITORIA!" em r1
    call print_string_colored   ; Chama função para imprimir string colorida
    loadn r0, #620              ; Carrega posição da linha seguinte em r0
    loadn r1, #timer_msg        ; Carrega endereço da string "TEMPO: " em r1
    call print_string           ; Chama função para imprimir string
    loadn r0, #627              ; Carrega posição após "TEMPO: " em r0
    loadn r1, #99               ; Carrega valor 99 em r1 (tempo de vitória)
    call print_number_2digits   ; Chama função para imprimir número
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO AUXILIAR: IMPRESSÃO DE STRING
; ============================================================================

print_string:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #0                ; Carrega terminador nulo em r3

print_string_loop:
    loadi r2, r1                ; Carrega caractere da posição apontada por r1
    cmp r2, r3                  ; Compara caractere com terminador nulo
    jeq end_print_string        ; Salta para fim se encontrou terminador
    outchar r2, r0
    inc r0                      ; Incrementa posição na tela
    inc r1                      ; Incrementa posição na string
    jmp print_string_loop       ; Continua loop de impressão

end_print_string:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO AUXILIAR: IMPRESSÃO DE STRING COLORIDA
; ============================================================================

print_string_colored:
    push r0
    push r1
    push r2
    push r3
    push r4
    loadn r3, #0                ; Carrega terminador nulo em r3
    loadn r4, #3072             ; Carrega código de cor amarela em r4

print_string_colored_loop:
    loadi r2, r1                ; Carrega caractere da posição apontada por r1
    cmp r2, r3                  ; Compara caractere com terminador nulo
    jeq end_print_string_colored ; Salta para fim se encontrou terminador
    add r2, r2, r4              ; Adiciona código de cor ao caractere
    outchar r2, r0
    inc r0                      ; Incrementa posição na tela
    inc r1                      ; Incrementa posição na string
    jmp print_string_colored_loop ; Continua loop de impressão

end_print_string_colored:
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO AUXILIAR: IMPRESSÃO DE NÚMERO COM 2 DÍGITOS
; ============================================================================

print_number_2digits:
    push r0
    push r1
    push r2
    push r3
    loadn r2, #10               ; Carrega divisor 10 em r2
    div r3, r1, r2              ; Calcula dezena (r3 = r1 ÷ 10)
    loadn r2, #'0'              ; Carrega código ASCII do '0' em r2
    add r3, r3, r2              ; Converte dezena para código ASCII
    outchar r3, r0
    inc r0                      ; Incrementa posição para próximo dígito
    loadn r2, #10               ; Carrega divisor 10 em r2
    mod r3, r1, r2              ; Calcula unidade (r3 = r1 % 10)
    loadn r2, #'0'              ; Carrega código ASCII do '0' em r2
    add r3, r3, r2              ; Converte unidade para código ASCII
    outchar r3, r0
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO AUXILIAR: LIMPEZA DA TELA
; ============================================================================

clear_screen:
    push r0
    push r1
    push r2
    push r3
    loadn r0, #0                ; Carrega posição inicial em r0 (canto superior esquerdo)
    loadn r1, #' '              ; Carrega código ASCII do espaço em r1
    loadn r2, #1200             ; Carrega total de posições na tela em r2

clear_screen_loop:
    outchar r1, r0
    inc r0                      ; Incrementa posição na tela
    dec r2                      ; Decrementa contador de posições
    loadn r3, #0                ; Carrega valor 0 em r3 para comparação
    cmp r2, r3                  ; Compara contador com 0
    jne clear_screen_loop       ; Continua loop se ainda há posições
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; FUNÇÃO AUXILIAR: ESPERA POR ENTRADA DO USUÁRIO
; ============================================================================

input_wait:
    push r1

input_wait_loop:
    inchar r0                   ; Lê caractere do teclado para r0
    loadn r1, #255              ; Carrega código "nenhuma tecla" em r1
    cmp r0, r1                  ; Compara tecla lida com código "nenhuma tecla"
    jeq input_wait_loop         ; Continua esperando se nenhuma tecla pressionada
    pop r1
    rts

; ============================================================================
; FUNÇÃO AUXILIAR: DELAY (CONTROLE DE VELOCIDADE)
; ============================================================================

delay:
    push r0
    push r1
    loadn r0, #1000             ; Carrega número de iterações para delay em r0

delay_loop:
    dec r0                      ; Decrementa contador de delay
    loadn r1, #0                ; Carrega valor 0 em r1 para comparação
    cmp r0, r1                  ; Compara contador com 0
    jne delay_loop              ; Continua loop se contador não é zero
    pop r1
    pop r0
    rts
