; ============================================================================
; JOGO DO DINOSSAURO PARA PROCESSADOR RISC 16-BIT
; Obstáculo reaparece baseado na velocidade atual (dinâmico)
; Reset quando passa de (10 - velocidade_atual)
; ============================================================================

jmp main                ; Salta para o rótulo main (início do programa)

; ============================================================================
; VARIÁVEIS – cada var ocupa 1 palavra (16 bits) na memória RAM
; ============================================================================

dino_pos:         var #1 ; Posição absoluta do dinossauro na tela (linha*40 + coluna)
dino_y:           var #1 ; Altura do dinossauro (número da linha)
dino_jumping:     var #1 ; Flag (sinalizador) de pulo: 1 = pulando, 0 = no chão
dino_jump_count:  var #1 ; Contador de frames para controlar a duração e altura do pulo

obstacle_x:       var #1 ; Posição horizontal (coluna) do obstáculo
obstacle_speed:   var #1 ; Velocidade atual do obstáculo (valores de 1 a 5)

timer_seconds:    var #1 ; Contador de segundos transcorridos no jogo
timer_frames:     var #1 ; Contador de frames para medir a passagem de um segundo (0 a 14)
game_over:        var #1 ; Flag de derrota: 1 = jogador colidiu
game_won:         var #1 ; Flag de vitória: 1 = jogador atingiu 99 segundos
game_start_delay: var #1 ; Contador de frames para o delay inicial ("PREPARE-SE")

debug_mode:       var #1 ; Flag de depuração: 1 = exibe informações e desativa colisão

; ============================================================================
; INICIALIZAÇÃO ESTÁTICA - Valores padrão na memória ao carregar o programa
; ============================================================================

static dino_pos         + #0, #890      ; Posição inicial: linha 22, coluna 10 (22*40 - 40 + 10)
static dino_y           + #0, #22       ; Linha inicial 22
static dino_jumping     + #0, #0        ; Dinossauro começa no chão (não pulando)
static dino_jump_count  + #0, #0        ; Contador do pulo zerado
static obstacle_x       + #0, #39       ; Obstáculo começa na borda direita da tela
static obstacle_speed   + #0, #2        ; Velocidade inicial é 2
static timer_seconds    + #0, #0        ; Zera o contador de segundos
static timer_frames     + #0, #0        ; Zera o contador de frames
static game_over        + #0, #0        ; Jogo não começa em "game over"
static game_won         + #0, #0        ; Jogo não começa com vitória
static game_start_delay + #0, #20       ; Define um delay de ~1 segundo (20 frames)
static debug_mode       + #0, #0        ; Modo de depuração começa desativado

; ============================================================================
; STRINGS – constantes de texto armazenadas na memória
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
    call init_game       ; Chama a rotina que inicializa/reseta todas as variáveis

game_loop:
    call clear_screen    ; Chama a rotina para limpar toda a tela
    call handle_input    ; Chama a rotina que processa a entrada do teclado
    call update_game     ; Chama a rotina que atualiza toda a lógica do jogo
    call render_game     ; Chama a rotina que desenha todos os elementos na tela
    call delay           ; Chama uma pequena pausa para controlar o ritmo do jogo

    load  r0, game_over  ; Carrega a flag de derrota no registrador r0
    loadn r1, #1         ; Carrega o número 1 no registrador r1 para comparação
    cmp   r0, r1         ; Compara r0 com r1 (game_over == 1?)
    jeq   game_over_screen ; Se for igual, salta para a tela de game over

    load  r0, game_won   ; Carrega a flag de vitória no registrador r0
    cmp   r0, r1         ; Compara r0 com r1 (game_won == 1?)
    jeq   game_won_screen  ; Se for igual, salta para a tela de vitória

    jmp   game_loop      ; Se nenhuma condição de fim de jogo for atendida, volta ao início do laço

; ============================================================================
; TELAS DE FIM DE JOGO
; ============================================================================

game_over_screen:
    call clear_screen    ; Limpa a tela
    call draw_game_over  ; Desenha a mensagem "GAME OVER"

    call input_wait      ; Pausa o jogo e aguarda o jogador pressionar qualquer tecla
    loadn r1, #'r'       ; Carrega o código ASCII da tecla 'r' em r1
    cmp   r0, r1         ; Compara a tecla pressionada (em r0) com 'r'
    jeq   restart_game   ; Se for 'r', salta para reiniciar o jogo

    jmp   game_over_screen ; Se for outra tecla, continua na tela de game over

game_won_screen:
    call clear_screen    ; Limpa a tela
    call draw_game_won   ; Desenha a mensagem "VITORIA!"

    call input_wait      ; Pausa o jogo e aguarda o jogador pressionar qualquer tecla
    loadn r1, #'r'       ; Carrega o código ASCII da tecla 'r' em r1
    cmp   r0, r1         ; Compara a tecla pressionada (em r0) com 'r'
    jeq   restart_game   ; Se for 'r', salta para reiniciar o jogo

    jmp   game_won_screen  ; Se for outra tecla, continua na tela de vitória

restart_game:
    call init_game       ; Chama a rotina de inicialização para resetar tudo
    jmp  game_loop       ; Salta de volta para o laço principal do jogo

; ============================================================================
; INICIALIZAÇÃO - Rotina para configurar/resetar as variáveis do jogo
; ============================================================================

init_game:
    push r0
    push r1

    loadn r0, #890       ; Carrega a posição inicial do dinossauro em r0
    store dino_pos, r0   ; Armazena o valor na variável dino_pos
    loadn r0, #22        ; Carrega a linha inicial do dinossauro em r0
    store dino_y, r0     ; Armazena o valor na variável dino_y

    loadn r0, #0         ; Carrega 0 em r0
    store dino_jumping, r0 ; Armazena 0 na flag de pulo (não está pulando)
    store dino_jump_count, r0; Zera o contador de pulo

    loadn r0, #39        ; Carrega a posição inicial do obstáculo em r0
    store obstacle_x, r0 ; Armazena o valor na variável obstacle_x
    loadn r1, #2         ; Carrega a velocidade inicial (2) em r1
    store obstacle_speed, r1 ; Armazena o valor na variável obstacle_speed

    loadn r0, #0         ; Carrega 0 em r0
    store timer_seconds, r0; Zera o timer de segundos
    store timer_frames, r0 ; Zera o contador de frames
    store game_over, r0    ; Zera a flag de derrota
    store game_won, r0     ; Zera a flag de vitória

    loadn r0, #20        ; Carrega 20 em r0 para o delay inicial
    store game_start_delay, r0 ; Armazena o valor na variável de delay
    loadn r0, #0         ; Carrega 0 em r0
    store debug_mode, r0 ; Desativa o modo de depuração

    call draw_ground     ; Desenha o chão inicial

    pop  r1
    pop  r0
    rts

; ============================================================================
; ENTRADA DO TECLADO - Processa a entrada do jogador
; ============================================================================

handle_input:
    push r0
    push r1

    inchar r0            ; Lê uma tecla do buffer do teclado e armazena em r0 (ou 255 se vazio)
    loadn r1, #255       ; Carrega 255 em r1
    cmp   r0, r1         ; Compara a tecla lida com 255
    jeq   end_handle_input ; Se for igual (nenhuma tecla), termina a rotina

    loadn r1, #' '       ; Carrega o código ASCII de 'espaço' em r1
    cmp   r0, r1         ; Compara a tecla lida com 'espaço'
    jeq   start_jump     ; Se for igual, salta para a lógica de pulo

    loadn r1, #'r'       ; Carrega o código ASCII de 'r' em r1
    cmp   r0, r1         ; Compara a tecla lida com 'r'
    jeq   reset_in_game  ; Se for igual, salta para a lógica de reset

    loadn r1, #'d'       ; Carrega o código ASCII de 'd' em r1
    cmp   r0, r1         ; Compara a tecla lida com 'd'
    jeq   toggle_debug   ; Se for igual, salta para alternar o modo debug

    jmp   end_handle_input ; Se não for nenhuma das teclas, termina

start_jump:
    load  r0, dino_jumping ; Carrega a flag de pulo em r0
    loadn r1, #0         ; Carrega 0 em r1
    cmp   r0, r1         ; Compara se já está pulando
    jne   end_handle_input ; Se for diferente de zero (já está pulando), ignora e sai

    loadn r0, #1         ; Carrega 1 em r0
    store dino_jumping, r0 ; Define a flag de pulo como 1 (inicia o pulo)
    loadn r0, #0         ; Carrega 0 em r0
    store dino_jump_count, r0; Zera o contador de frames do pulo
    jmp   end_handle_input

reset_in_game:
    call init_game       ; Chama a rotina para reiniciar o jogo
    jmp   end_handle_input

toggle_debug:
    load  r0, debug_mode ; Carrega o estado atual do modo debug
    loadn r1, #0         ; Carrega 0 em r1
    cmp   r0, r1         ; Compara o modo debug com 0
    jeq   set_debug_on   ; Se estiver desativado (0), salta para ativar

    loadn r0, #0         ; Se estava ativado, carrega 0
    store debug_mode, r0 ; e desativa
    jmp   end_handle_input
set_debug_on:
    loadn r0, #1         ; Carrega 1
    store debug_mode, r0 ; e ativa o modo debug
    jmp   end_handle_input

end_handle_input:
    pop r1
    pop r0
    rts

; ============================================================================
; LÓGICA DO JOGO - Orquestra as atualizações de estado
; ============================================================================

update_game:
    push r0
    push r1

    load  r0, game_start_delay ; Carrega o contador do delay inicial
    loadn r1, #0         ; Carrega 0 para comparação
    cmp   r0, r1         ; Compara o delay com 0
    jeq   update_game_normal ; Se o delay acabou, salta para a lógica normal do jogo

    dec   r0             ; Se não, decrementa o contador de delay
    store game_start_delay, r0 ; Salva o novo valor
    jmp   end_update_game

update_game_normal:
    call update_timer    ; Atualiza o timer
    load  r0, timer_seconds; Carrega o total de segundos
    loadn r1, #99        ; Carrega 99
    cmp   r0, r1         ; Compara os segundos com 99
    jne   continue_game  ; Se for diferente, continua o jogo

    loadn r0, #1         ; Se chegou a 99 segundos, carrega 1
    store game_won, r0   ; e define a flag de vitória
    jmp   end_update_game

continue_game:
    call update_dino_jump; Atualiza a lógica do pulo
    call update_obstacle ; Atualiza a posição do obstáculo
    call check_collision ; Verifica se houve colisão

end_update_game:
    pop r1
    pop r0
    rts

; ============================================================================
; TIMER - Apenas conta o tempo, não altera mais a velocidade
; ============================================================================

update_timer:
    push r0
    push r1

    load  r0, timer_frames   ; Carrega o contador de frames
    inc   r0               ; Incrementa o contador
    store timer_frames, r0   ; Salva o novo valor

    loadn r1, #15            ; Carrega 15 em r1 (15 frames ~ 1 segundo)
    cmp   r0, r1             ; Compara o contador de frames com 15
    jne   end_update_timer ; Se for menor, sai da rotina

    loadn r0, #0             ; Se chegou a 15, zera o contador de frames
    store timer_frames, r0
    load  r0, timer_seconds  ; Carrega o contador de segundos
    inc   r0               ; Incrementa os segundos
    store timer_seconds, r0  ; Salva o novo valor

end_update_timer:
    pop r1
    pop r0
    rts

; ============================================================================
; PULO - Controla a animação e a posição do dinossauro durante o pulo
; ============================================================================

update_dino_jump:
    push r0
    push r1
    push r2

    load  r0, dino_jumping   ; Carrega a flag de pulo
    loadn r1, #0         ; Carrega 0
    cmp   r0, r1         ; Compara se está pulando
    jeq   end_update_dino_jump ; Se não estiver (igual a 0), sai da rotina

    load  r0, dino_jump_count; Carrega o contador de frames do pulo
    inc   r0               ; Incrementa o contador
    store dino_jump_count, r0; Salva o novo valor

    loadn r1, #6             ; Carrega 6 (duração da subida)
    cmp   r0, r1             ; Compara o contador com 6
    jle   dino_going_up    ; Se for menor ou igual, salta para a lógica de subida

    loadn r1, #12            ; Carrega 12 (duração total no ar)
    cmp   r0, r1             ; Compara o contador com 12
    jle   dino_going_down  ; Se for menor ou igual, salta para a lógica de descida

    loadn r0, #0             ; Se o contador for > 12, o pulo terminou
    store dino_jumping, r0   ; Zera a flag de pulo
    store dino_jump_count, r0; Zera o contador de pulo
    loadn r0, #22            ; Carrega a linha do chão
    store dino_y, r0         ; Reseta a altura do dinossauro
    loadn r0, #890           ; Carrega a posição do chão
    store dino_pos, r0       ; Reseta a posição do dinossauro
    jmp   end_update_dino_jump

dino_going_up:
    loadn r1, #19            ; Carrega a linha de altura máxima do pulo
    store dino_y, r1         ; Define a nova altura
    loadn r0, #770           ; Carrega a posição correspondente (19*40+10)
    store dino_pos, r0       ; Define a nova posição
    jmp   end_update_dino_jump

dino_going_down:
    loadn r1, #20            ; Carrega a linha intermediária da descida
    store dino_y, r1         ; Define a nova altura
    loadn r0, #810           ; Carrega a posição correspondente (20*40+10)
    store dino_pos, r0       ; Define a nova posição

end_update_dino_jump:
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; ATUALIZAÇÃO DO OBSTÁCULO - Move o obstáculo e o reseta
; ============================================================================

update_obstacle:
    push r0
    push r1
    push r2

    load  r0, obstacle_x     ; Carrega a posição X atual do obstáculo
    load  r1, obstacle_speed ; Carrega a velocidade atual
    sub   r0, r0, r1         ; Calcula a nova posição: X = X - velocidade

    loadn r2, #10            ; Carrega 10
    sub   r2, r2, r1         ; Calcula o limite dinâmico: limite = 10 - velocidade

    cmp   r0, r2             ; Compara a nova posição com o limite
    jle   reset_obstacle_x   ; Se a posição for menor ou igual ao limite, salta para resetar

    store obstacle_x, r0     ; Se não, apenas armazena a nova posição
    pop   r2
    pop   r1
    pop   r0
    rts

reset_obstacle_x:
    loadn r0, #39            ; Carrega 39 (borda direita)
    store obstacle_x, r0     ; Reseta a posição do obstáculo
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; DETECÇÃO DE COLISÃO - Verifica se o dinossauro e o obstáculo colidiram
; ============================================================================

check_collision:
    push r0
    push r1
    push r2
    push r3

    load  r0, debug_mode     ; Carrega o estado do modo debug
    loadn r1, #1         ; Carrega 1
    cmp   r0, r1         ; Compara debug com 1
    jeq   end_check_collision; Se o modo debug estiver ativo, pula toda a verificação

    load  r0, dino_jumping   ; Carrega a flag de pulo
    loadn r1, #0         ; Carrega 0
    cmp   r0, r1         ; Compara se está pulando
    jne   end_check_collision; Se estiver pulando, não há colisão no chão

    load  r0, dino_y         ; Carrega a altura do dinossauro
    loadn r1, #22        ; Carrega a linha do chão
    cmp   r0, r1         ; Compara a altura com a do chão
    jne   end_check_collision; Se não estiver no chão, não há colisão

    load  r0, obstacle_x     ; Carrega a posição do obstáculo
    load  r1, obstacle_speed ; Carrega a velocidade

    loadn r2, #10            ; Carrega 10
    sub   r2, r2, r1         ; Limite inferior = 10 - velocidade
    cmp   r0, r2             ; Compara X do obstáculo com o limite inferior
    jle   end_check_collision; Se for menor ou igual, está à esquerda, sem colisão

    loadn r3, #10            ; Carrega 10
    add   r3, r3, r1         ; Limite superior = 10 + velocidade
    cmp   r0, r3             ; Compara X do obstáculo com o limite superior
    jeg   end_check_collision; Se for maior ou igual, ainda não alcançou, sem colisão

    loadn r0, #1             ; Se chegou aqui, está dentro do intervalo de colisão
    store game_over, r0      ; Define a flag de game over

end_check_collision:
    pop r3
    pop r2
    pop r1
    pop r0
    rts

; ============================================================================
; RENDERIZAÇÃO - Orquestra o desenho de todos os elementos na tela
; ============================================================================

render_game:
    push r0
    load  r0, game_start_delay ; Carrega o contador do delay inicial
    loadn r1, #0         ; Carrega 0
    cmp   r0, r1         ; Compara o delay com 0
    jne   show_prepare   ; Se o delay for > 0, salta para desenhar "PREPARE-SE"

    call  draw_ground    ; Desenha o chão
    call  draw_dino      ; Desenha o dinossauro
    call  draw_obstacle  ; Desenha o obstáculo
    call  draw_timer     ; Desenha o timer
    call  draw_debug     ; Desenha as informações de debug (se ativo)
    jmp   end_render_game

show_prepare:
    call draw_ground     ; Desenha o chão
    call draw_prepare    ; Desenha a mensagem "PREPARE-SE"

end_render_game:
    pop r0
    rts

; ============================================================================
; ROTINAS DE DESENHO - Funções que desenham elementos específicos
; ============================================================================

draw_dino:
    push r0
    push r1
    push r2

    load  r0, dino_pos       ; Carrega a posição absoluta do dinossauro
    loadn r1, #'D'           ; Carrega o caractere 'D'
    loadn r2, #1024          ; Carrega o valor para a cor branca (bit 10)
    add   r1, r1, r2         ; Soma o caractere com a cor
    outchar r1, r0           ; Desenha o caractere colorido na posição correta

    pop   r2
    pop   r1
    pop   r0
    rts

draw_obstacle:
    push r0
    push r1
    push r2

    load  r1, obstacle_x     ; Carrega a posição X do obstáculo
    loadn r2, #0         ; Carrega 0
    cmp   r1, r2         ; Compara a posição com 0
    jle   end_draw_obstacle; Se for menor ou igual, não desenha

    loadn r2, #39        ; Carrega 39
    cmp   r1, r2         ; Compara a posição com 39
    jgr   end_draw_obstacle; Se for maior, não desenha

    loadn r0, #880           ; Carrega a posição base da linha 22
    add   r0, r0, r1         ; Calcula a posição absoluta (880 + X)
    loadn r1, #'|'           ; Carrega o caractere do obstáculo
    loadn r2, #2048          ; Carrega o valor para a cor verde (bit 11)
    add   r1, r1, r2         ; Soma o caractere com a cor
    outchar r1, r0           ; Desenha o obstáculo colorido

end_draw_obstacle:
    pop   r2
    pop   r1
    pop   r0
    rts

draw_debug:
    push r0
    push r1
    push r2

    load  r0, debug_mode     ; Carrega o estado do modo debug
    loadn r1, #1         ; Carrega 1
    cmp   r0, r1         ; Compara se o modo debug está ativo
    jne   end_draw_debug ; Se não estiver, sai

    loadn r0, #1             ; Define a posição para o texto de debug
    loadn r1, #debug_label   ; Carrega o endereço do texto "OBST: "
    call  print_string     ; Escreve o texto

    loadn r0, #7             ; Define a posição para o número
    load  r1, obstacle_x     ; Carrega a posição X do obstáculo
    call  print_number_2digits; Escreve o número

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

    loadn r0, #920           ; Posição inicial do chão (linha 23, coluna 0)
    loadn r1, #40            ; Define o contador para 40 colunas
    loadn r2, #'='           ; Carrega o caractere do chão
    loadn r3, #512           ; Carrega o valor para a cor cinza
    add   r2, r2, r3         ; Soma o caractere com a cor
dg_loop:
    outchar r2, r0           ; Desenha um caractere do chão
    inc   r0               ; Move para a próxima coluna
    dec   r1               ; Decrementa o contador de colunas
    loadn r3, #0         ; Carrega 0
    cmp   r1, r3         ; Compara o contador com 0
    jne   dg_loop          ; Se o contador não for 0, repete o laço

    pop   r3
    pop   r2
    pop   r1
    pop   r0
    rts

draw_timer:
    push r0
    push r1
    push r2

    loadn r0, #0             ; Define a posição inicial do texto
    loadn r1, #timer_msg     ; Carrega o endereço do texto "TEMPO: "
    call  print_string     ; Chama a rotina para escrever o texto

    loadn r0, #7             ; Define a posição para desenhar o número
    load  r1, timer_seconds  ; Carrega o valor dos segundos
    call  print_number_2digits; Chama a rotina para escrever o número

    pop   r2
    pop   r1
    pop   r0
    rts

draw_prepare:
    push r0
    push r1
    loadn r0, #480           ; Define a posição no meio da tela
    loadn r1, #prepare_msg   ; Carrega o endereço do texto "PREPARE-SE"
    call  print_string     ; Escreve o texto
    pop   r1
    pop   r0
    rts

draw_game_over:
    push r0
    push r1
    loadn r0, #560           ; Define a posição na tela
    loadn r1, #game_over_msg ; Carrega o endereço do texto "GAME OVER"
    call  print_string     ; Escreve o texto

    loadn r0, #600           ; Define a posição para o timer
    loadn r1, #timer_msg     ; Carrega o texto "TEMPO: "
    call  print_string     ; Escreve o texto

    loadn r0, #607           ; Define a posição para o número
    load  r1, timer_seconds  ; Carrega os segundos
    call  print_number_2digits; Escreve o número
    pop   r1
    pop   r0
    rts

draw_game_won:
    push r0
    push r1
    push r2
    loadn r0, #560           ; Define a posição na tela
    loadn r1, #game_won_msg  ; Carrega o endereço do texto "VITORIA!"
    call  print_string_colored; Escreve o texto colorido

    loadn r0, #600           ; Define a posição para o timer
    loadn r1, #timer_msg     ; Carrega o texto "TEMPO: "
    call  print_string     ; Escreve o texto

    loadn r0, #607           ; Define a posição para o número
    loadn r1, #99        ; Carrega 99
    call  print_number_2digits; Escreve o número
    pop   r2
    pop   r1
    pop   r0
    rts

; ============================================================================
; ROTINAS AUXILIARES - Funções de propósito geral
; ============================================================================

print_string:
    push r0
    push r1
    push r2
    push r3
    loadn r3, #0         ; Carrega 0 (terminador de string)
ps_loop:
    loadi r2, r1             ; Carrega um caractere da string (endereçada por r1)
    cmp   r2, r3             ; Compara o caractere com 0
    jeq   ps_end           ; Se for igual, fim da string, salta para o final

    outchar r2, r0           ; Desenha o caractere
    inc   r0               ; Avança a posição na tela
    inc   r1               ; Avança para o próximo caractere na string
    jmp   ps_loop          ; Repete o laço
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
    loadn r3, #0         ; Carrega 0 (terminador de string)
    loadn r4, #3072          ; Carrega o valor da cor
psc_loop:
    loadi r2, r1             ; Carrega um caractere da string
    cmp   r2, r3             ; Compara com 0
    jeq   psc_end          ; Se for igual, fim da string

    add   r2, r2, r4         ; Adiciona a cor ao caractere
    outchar r2, r0           ; Desenha o caractere colorido
    inc   r0               ; Avança a posição na tela
    inc   r1               ; Avança para o próximo caractere
    jmp   psc_loop         ; Repete
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
    loadn r2, #10            ; Carrega 10
    div   r3, r1, r2         ; Calcula o dígito da dezena (r1 / 10)
    loadn r2, #'0'           ; Carrega o código ASCII de '0'
    add   r3, r3, r2         ; Converte o dígito para seu caractere ASCII
    outchar r3, r0           ; Desenha o dígito

    inc   r0               ; Avança a posição na tela
    loadn r2, #10            ; Carrega 10
    mod   r3, r1, r2         ; Calcula o dígito da unidade (r1 % 10)
    loadn r2, #'0'           ; Carrega o código ASCII de '0'
    add   r3, r3, r2         ; Converte o dígito para seu caractere ASCII
    outchar r3, r0           ; Desenha o dígito
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
    loadn r0, #0             ; Posição inicial da tela (0)
    loadn r1, #' '           ; Caractere de espaço
    loadn r2, #960           ; Número total de posições na tela (40x24)
cs_loop:
    outchar r1, r0           ; Desenha um espaço
    inc   r0               ; Avança a posição
    dec   r2               ; Decrementa o contador

    loadn r3, #0         ; Carrega 0
    cmp   r2, r3         ; Compara o contador com 0
    jne   cs_loop          ; Se não for 0, repete
    pop   r3
    pop   r2
    pop   r1
    pop   r0
    rts

input_wait:
    push r1
iw_loop:
    inchar r0                ; Lê uma tecla
    loadn r1, #255           ; Carrega 255
    cmp   r0, r1             ; Compara a tecla com 255
    jeq   iw_loop          ; Se for igual (nenhuma tecla), continua esperando
    pop r1
    rts

delay:
    push r0
    push r1
    loadn r0, #1000          ; Carrega um valor para o contador do delay
dl_loop:
    dec   r0               ; Decrementa o contador
    loadn r1, #0         ; Carrega 0
    cmp   r0, r1         ; Compara o contador com 0
    jne   dl_loop          ; Se não for 0, repete
    pop   r1
    pop   r0
    rts
