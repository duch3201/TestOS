[bits 16]

;	A FAZER

;	continuar o gerenciador de memória aos poucos
;	reescrever bootloader
;	editor de texto	

;mapa de segmentos de memoria:
;0x0000 - até 0x500 não é utilizavel. após isso pode se utilizar
;0x1000 - kernel
;0x2000 - stack/dados
;0x3000 - programas
;0x4000 - programas
;0x5000 - programas
;0x6000 - programas
;0x7000 - programas
;0x8000 em diante - nao utilizar 

;--------------------------------------------

; esta carregado em 0x1000:0000 (0x10000)
; 320kb ou 5 segmentos disponiveis para programas.
; 64kb disponiveis para o código do kernel
; 16kb de stack

COR_VGA_PRETO equ 0
COR_VGA_AZUL equ 1
COR_VGA_VERDE equ 2
COR_VGA_CIANO equ 3
COR_VGA_VERMELHO equ 4
COR_VGA_MAGENTA equ 5
COR_VGA_MARROM equ 6
COR_VGA_CINZA_CLARO equ 7
COR_VGA_CINZA_ESCURO equ 8
COR_VGA_AZUL_CLARO equ 9
COR_VGA_VERDE_CLARO equ 10
COR_VGA_CIANO_CLARO equ 11
COR_VGA_VERMELHO_CLARO equ 12
COR_VGA_MAGENTA_CLARO equ 13
COR_VGA_AMARELO equ 14
COR_VGA_BRANCO equ 15

inicio_kernel:
	cli
	mov ax,0x1000
	mov es,ax
	mov ax,0x2000
	mov ss,ax
	mov sp,0x4000
	sti
	
	;copiar os dados do BIOS Parameter Block
	
	mov ax,0x7c0 ; bootloader antigo
	mov ds,ax
	mov si,3
	mov di,parametros_disco
	mov cx,0x36+5
	
	rep movsb
	
	mov ax,0x1000
	mov ds,ax
	
	;carregar interrupts do sistema para a interrupt vector table
	
	;graficos de texto
	
	mov ax,0x20
	mov cx,0x1000
	mov dx,interrupt_20
	call carregar_interrupt
	
	;teclado 
	
	mov ax,0x21
	mov dx,interrupt_21
	call carregar_interrupt
	
	;disco
	mov ax,0x22
	mov dx,interrupt_22
	call carregar_interrupt
	
	;terminação de programa
	
	mov ax,0x23
	mov dx,interrupt_23
	call carregar_interrupt
	
	;memória
	
	mov ax,0x24
	mov dx,interrupt_24
	call carregar_interrupt
	
	;limpar a tela
	
	call vga_resetar
	
	mov ch,COR_VGA_PRETO
	mov cl,COR_VGA_CINZA_CLARO
	call vga_mudar_cor
	
	; carregar programas de auto-execução
	
	call auto_exec
	
	mov bx,0x1000
	mov es,bx
	mov bx,inicio1
	
	call vga_string
	
	mov cl,COR_VGA_VERDE_CLARO
	call vga_mudar_cor
	
	mov bx,inicio2
	call vga_string
	
	mov cl,COR_VGA_CINZA_CLARO
	call vga_mudar_cor
	
	mov bx,inicio3
	call vga_string
	
	;loop principal
	
sistema_principal:
	
	mov ch,COR_VGA_PRETO
	mov cl,COR_VGA_CINZA_CLARO
	call vga_mudar_cor
	
	mov al,0xA
	call vga_colocar_caractere_cursor
	mov al,'>'
	call vga_colocar_caractere_cursor
	
	mov cl,COR_VGA_BRANCO
	mov ch,COR_VGA_PRETO
	call vga_mudar_cor
	
	; limpar buffer do texto coletado
	
	xor al,al
	mov cx,0x1000
	mov es,cx
	mov cx,12
	mov di,buffer_de_input
	
	rep stosb
	
	mov al,' '
	mov cx,11
	mov di,arquivo_selecionado
	
	rep stosb
	
	; coletar o nome do arquivo
	
	mov bx,0
	
	.input_teclado:
		
		;pegar a tecla
		
		call teclado_esperar_por_tecla
		
		;checar pelos seguintes casos:
		
		; se o retroceder foi apertado, se o enter foi apertado ou se o tamanho maximo do nome de um arquivo foi encontrado
		
		cmp al,8
		je .backspace
		
		cmp al,0xA
		je .enter
		
		cmp bx,12
		jae .fim
		
		; nenhum dos casos anteriores foi encontrado
		
		; adicionar para o buffer e colocar o caractere na tela
		
		mov buffer_de_input[bx], al
		
		call vga_colocar_caractere_cursor
		
		inc bx
		
		jmp .fim
		
		.enter:
		
			jmp abrir_arquivo
		
		.backspace:
			
			;ver se podemos retroceder
			
			test bx,bx
			jz .fim
			
			;retroceder
			
			dec bx
			mov byte buffer_de_input[bx],0
			
			call vga_retroceder
		
		
		.fim:
			
			jmp .input_teclado
	
	
abrir_arquivo:
	
	;		transformar o nome do arquivo no buffer de input 
	
	;	primeiro transformar todas as letras em maiusculas
	
	xor bx,bx
	
	.loop:
		
		mov al,buffer_de_input[bx] ; copiar o caractere do buffer
		
		;verificar se é um caractere minusculo
		
		cmp al,'a'
		jb .fim_loop
	
		cmp al,'z'
		ja .fim_loop
		
		;tornar maisculo mudando o bit 5 para off
		
		and al,0b11011111
		
		;salvar o novo caractere
		
		mov buffer_de_input[bx],al
		
		.fim_loop:
		
		inc bx
		
		cmp bx,12 ;a instrução de loop não tem o comportamento desejado aqui.
		jbe .loop
modificar_nome:
	;		agora copiar para o buffer de abrimento de arquivo, aplicando a formatação nescessaria.
	
	mov si,buffer_de_input
	
	xor bx,bx
	
	.loop:
		
		lodsb
		
		cmp al,'.'
		je .ponto
		cmp al,0
		je carregar_programa
		cmp bx,11
		je carregar_programa
		
		mov arquivo_selecionado[bx],al
		
		inc bx
		
		jmp .fim_loop
		
	.ponto:
		mov bx,8 ; extensão de arquivo
	.fim_loop:
	
	jmp .loop

carregar_programa:

	mov bx,ds
	mov es,bx
	mov bx,arquivo_selecionado
	mov dl,1 ; programa comum
	call disco_fat12_carregar_arquivo
	push ax
	mov al,0xA
	call vga_colocar_caractere_cursor
	pop ax
	test al,al
	jz .sucesso
	
	; um erro aconteceu!
	; mostrar uma mensagem ao usuario e tentar novamente
	
	;	erros:
	;	0 = sucesso
	;	1 = erro de leitura
	;	2 = não encontrado
	;	3 = sem memória livre

	mov bx,ds
	mov es,bx
	
	cmp al,1
	je .err_leitura
	cmp al,2
	je .err_nao_encontrado
	cmp al,3
	je .err_memoria
	
	;cada um tem sua própria mensagem de erro.
	
	mov bx,sh_erro_desconhecido
	jmp .err_geral
	
	.err_leitura:
	
	mov bx,sh_erro_arquivo_leitura
	jmp .err_geral
	
	.err_nao_encontrado:
	
	mov bx,sh_erro_nao_encontrado
	jmp .err_geral
	
	.err_memoria:
	
	mov bx,sh_erro_arquivo_mem_cheia
	
	.err_geral:
	
	;mudar a cor do novo texto para vermelho fundo preto e colocar a mensagem na tela.
	
	mov ch,COR_VGA_PRETO
	mov cl,COR_VGA_VERMELHO
	call vga_mudar_cor
	
	call vga_string
	
	jmp sistema_principal
	
	.sucesso:
	
	;	usar um "far return" para ir para o programa carregado
	;	também configurar o DS com o segmento em que o programa foi carregado.
	
	mov [mem_programa_atual],cl
	
	xor bx,bx

	push es
	push bx
	mov bx,es
	mov ds,bx
		
	retf


buffer_de_input: times 12 db 0 ; 12 bytes para o input. 

arquivo_selecionado: times 11 db ' '


;----------------------------------------------------------
;					   FUNÇÕES DO KERNEL                  |
;----------------------------------------------------------

;carrega uma interrupt na tabela de vetores de interrupts.

; CX = segmento da função
; DX = offset da função
; AX = id da interrupt (exemplo, 0x21 seria chamada por int 0x21)

carregar_interrupt:

	pusha
	cli
	xor bx,bx
	mov es,bx
	
	push dx
	
	mov bx,4 ; 4 bytes em cada entrada
	mul bx
	
	mov bx,ax
	pop dx
	mov [es:bx],dx
	add bx,2
	mov [es:bx],cx
	
	sti
	popa
	ret
	
auto_exec:
	
	mov bx,0x1000
	mov es,bx
	mov bx,sh_autoexec_nome
	
	mov dl,1 ; alocamento padrão
	
	call disco_fat12_carregar_arquivo
	
	test al,al
	jnz .erro_leitura_arquivo_principal
	
	; es agora contém o segmento em que foi carregado o boot.cfg e cx contém o ID
	
	mov [autoexec_bootcfg_id],cl ; salvar o ID
	
	
	; coletar o numero de arquivos para ler
	
	xor bx,bx
	xor cx,cx
	.loop_coletar_numero:
		
		mov al,[es:bx]
		cmp al,0xA ; nova linha, proceder com a inicialização
		je .loop_coletar_numero_break
	
		cmp al,'0'
		jb .loop_coletar_numero_continuar
		cmp al,'9'
		ja .loop_coletar_numero_letra
		
		;numero
		
		sub al,'0' ; converter de ascii para numero
		
		;adicionar o numero ao hex
		
		shl cx,4 
		
		add cl,al 
		
		jmp .loop_coletar_numero_continuar
	
		.loop_coletar_numero_letra:
		
		cmp al,'A'
		jb .loop_coletar_numero_continuar
		cmp al,'F'
		ja .loop_coletar_numero_continuar
		
		; letra
		
		;converter de ascii
		
		sub al,'A' - 0xA 
		
		; adicionar o numero ao hex
		
		shl cx,4
		
		add cl,al
	
	
	.loop_coletar_numero_continuar:
		
		inc bx
	
		jmp .loop_coletar_numero
	
	.loop_coletar_numero_break:
	
	; carregar arquivos e executalos
	
	; colocar os dados corretos na memória 
	
	mov [autoexec_offset], bx
	mov [autoexec_segment], es
	mov [autoexec_restante], cx
	mov [autoexec_stack_pointer], sp
	
	.continuar_carregando:
	
	mov es,[autoexec_segment]
	mov bx,[autoexec_offset]
	mov cx,[autoexec_restante]
	mov sp,[autoexec_stack_pointer]
	
	mov al,0xA ; newline
	call vga_colocar_caractere_cursor
	
	test cx,cx
	jz .finalizar_carregamento
	
	dec cx
	mov [autoexec_restante],cx
	
	add bx,12 ; tipo de alocamento
	
	mov dl,[es:bx]
	
	cmp dl,'0'
	jb .nao_numero
	cmp dl,'9'
	ja .nao_numero
	
	sub dl,'0' ; converter
	
	sub bx,11 ; inicio do nome
	
	mov al,[es:bx]
	
	call disco_fat12_carregar_arquivo
	
	test al,al
	jnz .erro_carregamento
	
	; tudo certo, preparar e ir para o arquivo
	
	add bx,12 ; proximo nome-1
	mov [autoexec_offset], bx
	
	
	xor bx,bx
	
	push es
	push bx 
	
	mov bx,es
	mov ds,bx
	
	retf ; ir para o proximo arquivo
	
	.nao_numero:
	
	; preparar para o proximo arquivo
	
	inc bx ; proximo nome-1
	mov [autoexec_offset], bx
	
	jmp .continuar_carregando
	
	.erro_carregamento:
	
	; preparar para o proximo arquivo
	add bx,12 ; proximo nome-1
	mov [autoexec_offset],bx
	
	jmp .continuar_carregando
	
	.finalizar_carregamento:
	
	xor bh,bh
	mov byte bl,[autoexec_bootcfg_id] ; coletar o id 
	
	call mem_desalocar ; desalocar o arquivo
	
	mov byte [autoexec_acontecendo],0 ; autoexec não está mais acontecendo
	
	ret
	
	.erro_leitura_arquivo_principal:
	
	mov bx,0x1000
	mov es,bx
	mov bx,sh_autoexec_erro_boot_cfg
	
	call vga_string
	
	mov byte [autoexec_acontecendo],0 ; autoexec não está mais acontecendo
	
	ret
	

autoexec_acontecendo: 	db 1 ; 1: acontecendo 0: não acontecendo
autoexec_bootcfg_id:	db 0 ; id do bootcfg carregado
autoexec_restante:		dw 0 ; numero de programas restantes
autoexec_offset:		dw 0 ; offset do caractere atual no bootcfg
autoexec_segment:		dw 0 ; segment do arquivo carregado
autoexec_stack_pointer: dw 0 ; stack pointer
	
;----------------------------------------------------------
;						   Memoria
;----------------------------------------------------------

;estados possiveis (X é o nibble de alta ordem, indica o numero do programa que o carregou. 5 seria o kernel.):
;00 = livre 
;X1 = carregado  - carregado e ficara ná memoria até o programa ser fechado/seja pedido seu descarregamento
;X2 = residente  - carregado por um programa/pelo sistema e vai ficar na memoria até o sistema ser desligado.
;X3 = temporario - carregado temporariamente por um programa e ficará na memoria até que ele seja descarregado.

mem_estado_segmentos: times 5 db 0
mem_programa_atual: db 5

; só chamavel pelo kernel

mem_desalocar_nao_residentes:
	
	push bx
	push ax
	
	xor bx,bx ; começar do primeiro programa
	
	.loop:
		cmp bx,4
		ja .done
		
		mov al, mem_estado_segmentos[bx]
		
		and al,0b00001111 ; coletar o tipo de reservamento
		cmp al,2 ; se for residente, não fazer nada
		je .continuar
		
		;não residente, desalocar.
		
		mov byte mem_estado_segmentos[bx], 0
		
		.continuar:
		
		inc bx
		
		jmp .loop
	
	
	.done:
	
	pop ax 
	pop bx
	ret 
	
	
;bx = segmento a desalocar

mem_desalocar:
	
	cmp bx,5
	jae .fim
	
	mov byte mem_estado_segmentos[bx], 0
	
	.fim:
	
	ret

;CL = estilo de reservamento (1 = normal, 2 = residente, 3 = temporario)
;CH = numero do programa que o reservou
;retorna o numero do programa em cx e AL=0< se algum erro aconteceu.

;erros possiveis são:
; 1 - sem segmento disponivel


mem_reservar:
	push bx
	push dx
	push di
	push es
	
	;encontrar segmento livre
	
	mov dx,cx
	
	mov ax,0x1000
	mov es,ax
	mov di,mem_estado_segmentos
	xor al,al
	mov cx,5
	repne scasb
	jne .sem_espaco
	
	; calcule a posição aonde fica o segmento
	
	mov ax,5
	sub ax,cx
	
	dec ax
	
	mov bx,ax
	
	;mova o novo estado para a posição
	
	shl dh,4
	and dl,0x0F
	or dl,dh
	
	mov mem_estado_segmentos[bx],dl
	mov al,100 ;TODO verificar?
	
	mov cx,bx ; salvar numero de programa
	
	xor al,al ; sucesso
	
	jmp .fim
	
	.sem_espaco:
	
	mov al,1
	mov cx,0xFF
	
	.fim:
	
	pop es
	pop di
	pop dx
	pop bx
	ret
	


;----------------------------------------------------------
;				   Leitura de disco FAT12
;----------------------------------------------------------

parametros_disco:
DiskLabel					db "        "
BytesSetor					dw 0
SetorCluster				db 0
ReservadoParaBoot			dw 0
NumeroFats					db 0
EntradasRaiz				dw 0
SetoresLogicos				dw 0
TipoDeDisco					db 0
SetoresPorFat				dw 0
SetoresPorTrack				dw 0
Lados						dw 0
SetoresOcultos				dd 0
SetoresGrande				dd 0
NumeroBoot					db 0
RESERVADO 					db 0
SinalDeBoot					db 0
IdDeVolume					dd 0
LabelDoVolume				db "           "
SistemaArquivos				db "        "

disco_buffer_nome:	times 11 db ' '
db 0

; 	ES:BX aponta para nome de arquivo ; DL é o tipo de alocamento 
; 	retorna segmento do arquivo em ES e o numero do programa em CX e se foi um sucesso ou um erro em AL

;	erros:
;	0 = sucesso
;	1 = erro de leitura
;	2 = não encontrado
;	3 = sem memória livre

disco_fat12_carregar_arquivo:
	push bx
	push dx
	push ds
	
	;copiar o nome para o buffer
	
	mov ch,[mem_programa_atual]
	mov cl,dl
	call mem_reservar
	test al,al
	jnz .sem_memoria
	
	push cx
	
	mov di,disco_buffer_nome
	mov si,bx
	
	mov ax,es
	mov ds,ax
	mov ax,0x1000
	mov es,ax
	
	mov cx,11
	
	rep movsb
	
	mov ds,ax
	
	; carregar o diretório raiz
	
	
	mov bx,0x2000
	mov es,bx
	mov bx,0x8000
	
	call disco_fat12_carregar_diretorio_raiz
	test al,al
	jnz .erro_leitura
	
	;encontrar a entrada no diretório raiz
	
	mov di,bx ; 0x8000 
	
	
	.ler_diretorio:
	
		push di
		push cx 
		
		mov cx,11
		mov si,disco_buffer_nome
		
		repe cmpsb
		je .encontrado
		
		pop cx
		pop di
		add di,32
		loop .ler_diretorio
		
		pop cx
		

		jmp .nao_encontrado
	
	
	.encontrado:
	
	pop cx ; limpar stack
	
	;salvar a cluster inicial
	
	pop bx
	add bx,0x1A ; cluster inicial
	
	mov cx,[es:bx]
	
	mov bx,0x8000
	
	call disco_fat12_carregar_FAT
	test al,al
	jnz .erro_leitura
	
	pop ax
	push ax
	
	;calcular o segmento em que ira ser carregado
	
	add ax,3
	
	mov bx,0x1000
	
	mul bx
	
	mov bx,ax
	
	mov es,bx
	xor bx,bx
	
	mov ax,cx
	
	call disco_fat12_carregar_clusters
	
	test al,al
	jnz .erro_fim
	
	pop cx
	
	xor al,al
	
	jmp .fim
	
	.erro_leitura:
	pop cx
	mov al,3
	
	jmp .erro_fim
	
	.nao_encontrado:
	
	mov al,2
	
	jmp .erro_fim
	
	
	.sem_memoria:
	
	mov al,3
	
	.erro_fim:
	
	;assume-se que CX contém o numero do programa
	mov bx,cx
	
	call mem_desalocar
	
	
	.fim:
	
	
	
	pop ds
	pop dx
	pop bx
	
	ret

disco_setor_atual: dw 0

; ENTRADA
; ES = segmento da fat
; BX = entrada a ser lida
; RETORNA
; DX 

disco_fat12_ler_entrada_fat:
	push bx
	
	; calcular a posição correta
	push ax 
	mov ax,3
	mul bx
	mov bx,2
	div bx
	mov bx,ax
	pop ax
	
	or dx,dx
	mov dx, [es:bx]
	jnz .impar
	
	; even
	
	and dx, 0b0000111111111111 ; zerar os 4 bits mais significantes
	
	jmp .entrada_lida
	
	.impar:
	
	shr dx,4 ; coletar os 12 bits mais significantes
	
	.entrada_lida:
	
	pop bx
	ret
	

; ENTRADA
; ES = segmenta da fat
; BX = entrada
; DX = valor a ser escrito

disco_fat12_escrever_entrada_fat:
	
	push dx
	push ax
	push bx
	
	push dx
	
	; calcular a posição correta
	
	mov ax,3
	mul bx
	mov bx,2
	div bx
	mov bx,ax
	
	mov ax,[es:bx]
	
	or dx,dx
	pop dx
	jnz .impar
	
	;zerar os 12 bits menos significantes de ax
	;e colocar os 12 bits menos significantes de dx no lugar

	and ax,0b1111000000000000
	and dx,0b0000111111111111
	or  ax,dx
	
	jmp .escrever
	
	.impar:
	
	;zerar os 12 bits mais significantes de ax
	;e colocar os 12 bits menos significantes de dx no lugar
	
	and ax,0b0000000000001111
	shl dx,4
	or  ax,dx
	
	.escrever:
	
	mov [es:bx],ax
	
	pop bx
	pop ax
	pop dx
	ret

;ES:BX = aonde carregar, AX = cluster inicial
;destroi AH e retorna não zero em AL se tiver erro
disco_fat12_carregar_clusters:

	push bx
	push cx
	push dx
	push ds
	
	mov [disco_setor_atual],ax ; salvar o cluster inicial 
	
	push bx
	
	.carregar_setor_fat:
	
	; calcular o setor real do setor logico
	
	mov cx,1
	mov ax,[disco_setor_atual]
	add ax,31
	
	pop bx
	
	call disco_carregar_setores
	test al,al
	jnz .fim
	;avançar 512 bytes
	
	add bx,512
	push bx
	
	.proximo:
	
	;calcular o proximo cluster
	
	mov ax,[disco_setor_atual]
	
	xor dx,dx
	mov cx,3
	mul cx
	mov cx,2
	xor dx,dx
	div cx
	
	;coletar o cluster
	
	mov si,0x8000
	add si,ax
	
	push ds
	
	mov ax,0x2000
	mov ds,ax
	
	mov ax,[ds:si]
	
	pop ds
	
	test dx,dx
	
	jz .par
	
	
	.impar:
	
	shr ax,4
	jmp .proximo_fim
	
	.par:
	
	and ax,0x0FFF
	
	.proximo_fim:
	
	mov [disco_setor_atual], ax
	
	cmp ax, 0xFF8
	
	jb .carregar_setor_fat
	
	xor ax,ax
	pop bx
	.fim:
	pop ds
	pop dx
	pop cx
	pop bx
	ret

;ES:BX = aonde carregar a FAT 

disco_fat12_carregar_FAT:
	push cx
	
	;localização no disco
	
	mov ax,[ReservadoParaBoot]
	mov cx,[SetoresPorFat]
	
	call disco_carregar_setores
	
	pop cx
	ret


;ES:DI aponta para o diretório raiz
;DS:SI aponta para o nome de arquivo

;destroi AH

;retorna o pointer para o inicio da entrada de arquivo em ES:DI e se achou em AL (zero se encontrado)

disco_fat12_encontrar_arquivo:
	
	push cx
	
	mov cx,[EntradasRaiz]
	
	.loop:
		push cx
		push di
		push si
		mov cx,11
		
		repe cmpsb
		
		je .fim
		
		pop si
		pop di
		add di,32
		pop cx
	
	loop .loop
	
	pop cx
	
	mov al,1
	
	ret
	
	.fim:
	
	pop si
	pop di
	
	pop cx
	
	pop cx
	
	xor al,al 
	
	ret
	
;ES:BX = lugar para carregar o diretório.

disco_fat12_carregar_diretorio_raiz:
	push cx
	push dx
	
	;calcular o numero de setores para abrir
	
	mov ax,32
	mul word [EntradasRaiz]
	mov cx,512
	xor dx,dx
	div cx
	mov cx,ax
	
	;calcular a localização no disco
	
	mov ax,2
	mul word [SetoresPorFat]
	add word ax,[ReservadoParaBoot]
	
	call disco_carregar_setores
	
	
	pop dx
	pop cx
	ret

;ES:BX pointer para o nome do arquivo
;CX:DX pointer para o inicio dos dados a se escrever
;AL = numero de setores a se escrever (limite de 128)
;retorna status em AL.

; AL = 0 > sucesso
; AL = 1 > limite maximo de setores para o arquivo
; AL = 2 > arquivo não foi encontrado após criação
; AL = 3 > arquivo já existe!
; AL = 4 > erro de escrita no disco
disco_fat12_escrever_para_arquivo:
	
	;copiar nome para o buffer
	
	mov [.segmento_ler], cx
	mov [.offset_ler],   dx
	
	push bx
	
	mov bx,es
	mov ds,bx
	
	mov bx,0x1000
	mov es,bx
	
	mov di,.buffer
	
	pop bx 
	
	mov si,bx 
	
	mov cx,11
	
	rep movsb 
	
	;verificar o limite
	
	cmp al,128
	jae .erro_setor_limite
	
	;criar arquivo
	
	mov bx,0x1000
	mov ds,bx
	mov bx,.buffer
	
	
	; criar o arquivo com nenhum atributo
	
	xor dl,dl
	
	push ax
	
	call disco_criar_arquivo
	test al,al
	
	jnz .nao_existe_continuar ; arquivo já existe! retorne com o código de erro apropriado
	
	pop ax
	jmp .erro_existe
	
	.nao_existe_continuar:
	
	;encontrar arquivo no diretório
	
	mov bx,0x2000
	mov es,bx
	
	mov di,0x8000
	
	mov si,.buffer
	
	call disco_fat12_encontrar_arquivo
	
	; carregar a fat para a memoria
	
	mov bx,0xB000 ; carregar em 0x2B000
	
	call disco_fat12_carregar_FAT
	
	; encontrar a primeira cluster
	
	;apontar ES para 0x2B000
	
	mov bx,0x2B00
	mov es,bx
	xor bx,bx
	
	.encontrar_primeira:
		
		call disco_fat12_ler_entrada_fat
		
		test dx,dx
		
		jz .primeira_encontrada
		
		inc bx
		
		jmp .encontrar_primeira
		
	.primeira_encontrada:
	
	; modificar a entrada no diretório raiz para conter a primeira cluster do arquivo
	
	; di contém o inicio da entrada do arquivo no diretório raiz
	
	mov ax,0x2000
	mov es,ax
	mov ax,bx
	add di, 0x1A ; offset 0x1A: inicio das clusters
	
	stosw 
	
	mov [.cluster_antiga], bx

	
	pop cx ; numero de clusters
	
	xor ch, ch ; byte mais significante não importa para nós.
	
	.escrever_clusters:
	
		mov ax,31 ; transformar cluster em setor fisico
		add word ax,[.cluster_antiga]
		
		mov bx,[.segmento_ler]
		mov es,bx
		mov bx,[.offset_ler]
		
		push cx
		mov cx,1 ; 1 setor 
		
		call disco_escrever_setores
		test al,al
		jz .continuar_clusters
		pop cx
		jmp .erro_escrita
		
		.continuar_clusters:
		
		add word [.offset_ler], 512
		
		pop cx 
		
		;se a ultima cluster for escrita, escreva o EOF
		
		cmp cx,1
		je .finalizar_escrita
		
		mov bx,0x2B00
		mov es,bx
		
		mov bx,[.cluster_antiga]
		
		.encontrar_proxima_cluster_livre:
			
			call disco_fat12_ler_entrada_fat
			
			test dx,dx
			jz .proxima_encontrada
			
			inc bx
			
			
			
		jmp .encontrar_proxima_cluster_livre
			
		.proxima_encontrada:
		
			; bx contém a proxima cluster
			
			mov dx,bx
			
			mov bx, [.cluster_antiga]
			
			call disco_fat12_escrever_entrada_fat
			
			; salvar a nova cluster
			
			mov [.cluster_antiga], dx 
			
		
	
	loop .escrever_clusters
	
	;escrever o EOF na entrada final.
	
	.finalizar_escrita:
		mov bx,0x2B00
		mov es,bx
	
		mov bx, [.cluster_antiga]
		
		
		mov dx, 0xFF8 ; EOF
		
		call disco_fat12_escrever_entrada_fat
		
	
		; escrever diretório raiz novo ao disco
		
		;calcular o numero de setores para escrever
	
		mov cx, [EntradasRaiz]
		shl cx, 5 ; multiplicar por 32
		
		shr cx, 9 ; dividir por 512
		
		;calcular a localização no disco
		
		
		mov ax, [SetoresPorFat]
		shl ax,1 ; multiplicar por 2
		add word ax,[ReservadoParaBoot]
		
		mov bx,0x2000
		mov es,bx
		mov bx,0x8000
		
		call disco_escrever_setores
		
		test al,al
		jnz .erro_escrita
		
		; escrever a fat nova ao disco
		
		
		mov cx, [SetoresPorFat]
		
		mov ax, [ReservadoParaBoot]
		
		mov bx,0xB000
		
		call disco_escrever_setores
		
		test al,al
		jnz .erro_escrita
		
		;sucesso, retornar 0
		
		xor al,al		
		ret
		
	.erro_escrita:
	
	mov al,4
	ret
		
	.erro_existe:
	
	mov al,3
	ret
		
	.erro_nao_encontrado:
	
	mov al,2
	ret
	
	.erro_setor_limite:
	
	mov al,1
	ret
	
.buffer: times 11 db 0

.cluster_antiga: dw 0
.segmento_ler: dw 0
.offset_ler: dw 0

;ES:BX pointer para o nome de arquivo, DL = attributes
;retorna status em AL

; AL=0 - existe
; AL=1 - sem espaço
; AL=2 - erro de escrita
; AL=3 - sucesso

disco_criar_arquivo:

	push es
	push bx
	push cx
	push ds 
	
	;copiar nome para o buffer
	
	mov ax,es
	mov ds,ax
	mov si,bx
	
	mov ax,0x1000
	mov es,ax
	mov di,.buffer
	
	mov cx,11
	
	rep movsb
	
	mov ax,es
	mov ds,ax
	
	;carregar o diretório raiz para a memória
	
	mov bx,0x2000
	mov es,bx
	mov bx,0x8000
	
	call disco_fat12_carregar_diretorio_raiz
	
	;verificar se arquivo existe no diretorio raiz
	
	mov di,bx
	
	mov si,.buffer
	
	call disco_fat12_encontrar_arquivo
	
	
	test al,al
	jz .existe
	
	;encontrar a proxima entrada livre.
	
	mov cx,[EntradasRaiz]
	
	.loop:
		
		mov al,[es:bx]
		
		cmp al,0 ; entrada disponivel, nenhuma entrada alem dela
		je .criar_arquivo
		cmp al,0xE5 ; entrada disponivel
		je .criar_arquivo
		
		add bx,32
		
	
	loop .loop
	
	mov al,1
	
	jmp .existe
	
	.criar_arquivo:
	
	; copiar o nome para a entrada
	
	mov si,.buffer
	mov di,bx
	mov cx,11
	
	rep movsb
	
	; copiar atributos
	
	mov al,dl 
	
	lodsb
	
	;escrever no disco o diretório raiz
	
	;calcular o numero de setores para escrever
	
	mov ax,32
	mul word [EntradasRaiz]
	mov cx,512
	xor dx,dx
	div cx
	mov cx,ax
	
	;calcular a localização no disco
	
	mov ax,2
	mul word [SetoresPorFat]
	add word ax,[ReservadoParaBoot]
	
	mov bx,0x8000
	
	;es é 0x2000
	
	call disco_escrever_setores
	
	mov al,2
	
	jnz .existe
	
	mov al,3
	
	.existe:
	
	pop ds
	pop cx 
	pop bx
	pop es
	
	ret
	
	.buffer: times 11 db 0
	
;AX = LBA, CX = numero de setores a serem escritos, ES:BX, onde acessar da memoria
;retorna 0 em AL ou código de erro se aconteceu algum

disco_escrever_setores:
	
	push bx
	push cx
	push dx
	
	push cx
	push bx
	
	mov byte [.tentativas], 0
	
	; converter LBA para CHS
	
	mov bx,ax ;salvar LBA
	
	xor dx,dx
	
	;setor
	
	div word [SetoresPorTrack] 
	add dl, 1
	mov cl, dl
	
	mov ax,bx
	
	;lado e track
	
	xor dx,dx
	div word [SetoresPorTrack]
	xor dx,dx
	div word [Lados]
	mov dh, dl
	mov ch, al
	
	; carregar dados para int 0x13
	
	pop bx
	pop ax
	
	mov dl, [NumeroBoot]
	
	call disco_resetar
	
	mov ah,3 ; escrever ao disco
	
	int 0x13
	
	pop dx
	pop cx
	pop bx
	
	jc .disco_erro_escrita
	
	xor al,al
	
	ret
	
	.disco_erro_escrita:
	
		cmp byte [.tentativas],5
		jae .impossivel_escrever
		
		inc byte [.tentativas]
		jmp disco_escrever_setores
	
		.impossivel_escrever:
			
			mov al,1
			
			ret
			
		.tentativas: db 0

;AX = LBA, CX = numero de setores para serem carregados, ES:BX aonde carregar na memória.
;retorna 0 em AL ou código de erro se aconteceu algum.
disco_carregar_setores:
	
	push bx
	push cx
	push dx
	
	push cx
	push bx
	
	mov byte [.tentativas], 0
	
	; converter LBA para CHS
	
	mov bx,ax ;salvar LBA
	
	xor dx,dx
	
	;setor
	
	div word [SetoresPorTrack] 
	add dl, 1
	mov cl, dl
	
	mov ax,bx
	
	;lado e track
	
	xor dx,dx
	div word [SetoresPorTrack]
	xor dx,dx
	div word [Lados]
	mov dh, dl
	mov ch, al
	
	; carregar dados para int 0x13
	
	pop bx
	pop ax
	
	mov dl, [NumeroBoot]
	
	call disco_resetar
	
	mov ah, 2 ; ler disco
	
	int 0x13
	
	pop dx
	pop cx
	pop bx
	
	jc .disco_erro_leitura
	
	xor al,al
	
	ret
	
	.disco_erro_leitura:
		cmp byte [.tentativas],5
		jae .impossivel_carregar
		
		inc byte [.tentativas]
		jmp disco_carregar_setores
	
		.impossivel_carregar:
			
			mov al,1
			
			ret
			
		.tentativas: db 0

disco_resetar:
	pusha
	
	xor ah,ah ; 0 - resetar disco
	mov dl, [NumeroBoot]
	
	int 0x13
	
	popa
	ret

;----------------------------------------------------------
;						   Teclado
;----------------------------------------------------------

teclado_dados_BR_min: db	0, 27, "1234567890-=", 8, 9, "qwertyuiop'[", 0xA,
db 					 	0, "asdfghjklc~'", 0, "]zxcvbnm,.;", 0, 0
db						0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
db						0, 0, 0, 0, 0, 0, '-', 0, 0, 0, '+'
times 0x56 - 0x4E - 1 db 0
db '\'
times 0x73 - 0x56 - 1 db 0
db '/'
teclado_dados_BR_mai: db	0, 27, "!@#$% &*()_+", 8, 9, "QWERTYUIOP`{", 0xA,
db 					 	0, "ASDFGHJKLC^", '"', 0, "}ZXCVBNM<>:", 0, 0
db						0, ' ', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
db						0, 0, 0, 0, 0, 0, '-', 0, 0, 0, '+'
times 0x56 - 0x4E - 1 db 0
db '|'
times 0x73 - 0x56 - 1 db 0
db '?'

;	retorna a ultima tecla apertada (caractere ascii) ou 0 se nenhuma tiver sido apertada desde a ultima leitura/é uma tecla especial
;	al = tecla ou 00

teclado_ultima_apertada:
	push dx
	push bx
	push es
	
	mov dx,0x64 ;porta das flags do teclado
	
	in al,dx
	
	and al,1 ; ver se o buffer está cheio. se não estiver, vá para o fim e retorne 0
	jz .nenhuma_tecla
	
	
	mov dx,0x60 ; porta do scancode da ultima tecla pressionada/solta 
	in al,dx
	
	;detectar se a tecla está sendo solta
	
	mov ah,al
	and ah,0b10000000
	jnz .nenhuma_tecla ;se estiver, não conte como uma tecla e retorne.
	
	mov bx,ax ; ah deve ser 0 se chegar aqui.
	mov al,teclado_dados_BR_min[bx] ; coletar o caractere ascii do mapa de teclado
	
	mov dx,bx
	
	; coletar o primeiro byte de flags de teclas especiais da area de dados da BIOS (shift, control, etc)
	
	mov bx,0x40
	mov es,bx
	mov bx,0x17
	
	mov ah,[es:bx]
	
	;ver se shift foi pressionado
	
	and ah,0b00000011
	jz .fim
	
	;shift
	
	mov bx,dx
	
	mov al,teclado_dados_BR_mai[bx]
	
	jmp .fim
	
	.nenhuma_tecla:
	
	xor al,al
	
	.fim:
	
	pop es
	pop bx
	pop dx
	
	ret
	
;espera por um aperto de tecla do teclado e retorna um caractere em al

teclado_esperar_por_tecla:
	
	.loop:
		call teclado_ultima_apertada
		test al,al
		jnz .tecla_apertada
	jmp .loop
	
	.tecla_apertada:
	
	ret 


;----------------------------------------------------------
;							 VGA
;----------------------------------------------------------

vga_cursor_x: db 0
vga_cursor_y: db 0
vga_cor:      db 0b00000111 ; preto com letras cinzas

;	limpa a tela, move o cursor para o topo superior esquerdo e torna a cor cinza com o fundo escuro


vga_resetar:
	pusha
	push es
	
	;retornar as variaveis para o padrão
	
	mov byte [vga_cor], 0b00000111
	mov word [vga_cursor_x], 0
	
	; limpar a tela
	
	mov bx,0xB800 ; endereço de memoria VGA
	mov es,bx
	
	xor cx,cx
	
	mov al, 0
	mov ah,[vga_cor]
	
	.loop:
	
		mov bx,cx
		
		mov [es:bx], ax
		
		add cx,2	
			
		cmp cx,80*25*2
		
		jbe .loop
	
	call vga_atualizar_cursor
	
	pop es
	popa
	ret


; atualiza a posição do cursor

vga_atualizar_cursor:
	
	pusha
	
	mov ah,02
	mov bh,0
	mov dh,[vga_cursor_y]
	mov dl,[vga_cursor_x]
	
	int 10h
	
	popa
	ret

;	mudar a cor em que as novas entradas vão ser feitas 
; 	CH = cor do fundo, CL = cor da letra.

vga_mudar_cor:
	
	
	shl ch,4
	and cl,0x0F
	or cl,ch
	
	mov byte [vga_cor],cl
	
	ret
	
;	coloca um caractere na posição do cursor
;	AL = caractere

vga_colocar_caractere_cursor:
	pusha
	
	; coletar os dados para a função vga_caractere
	
	mov bh,[vga_cor]
	xor ch,ch
	mov cl,[vga_cursor_x]
	xor dh,dh
	mov dl,[vga_cursor_y]
	
	cmp al,0xA
	je .x_max
	
	call vga_caractere
	
	;checar se é para dar scroll
	
	cmp byte [vga_cursor_x], 79
	jae .x_max
	
	inc byte [vga_cursor_x]
	
	jmp .fim
	
	.x_max:
		
		;checar para ver se é um scroll no final da tela
		
		cmp byte [vga_cursor_y], 24
		jae .y_max
		
		;mova o cursor para o inicio da proxima linha
		
		mov byte [vga_cursor_x], 0
		inc byte [vga_cursor_y]
		
		jmp .fim
		
		.y_max:
			
			;scroll no final da tela, chame a função
			
			call vga_scroll
			jmp .fim
	
	.fim:
	
	call vga_atualizar_cursor
	
	popa
	ret

vga_scroll:
	
	pusha
	push es
	push ds
	
	;entrada a ser coloda usando o stosw
	
	mov byte [vga_cursor_x],0
	
	mov ah,[vga_cor]
	mov al,' '
	
	;configurar destino e fonte para o movsb
	
	mov bx,0xB800
	mov ds,bx
	mov es,bx
	
	mov di,0
	mov si,80*2
	
	mov cx,80*24*2
	
	rep movsb
	
	;destino para o stosw
	
	mov di,80*24*2
	mov cx,80
	
	rep stosw
	
	call vga_atualizar_cursor
	
	pop ds
	pop es
	popa
	ret


;	colocar caractere em um lugar da tela
;	AL = caractere, BH = cor, CX = x, DX = y
vga_caractere:
	pusha
	push es
	
	mov ah,bh
	
	mov bx,0xB800
	mov es,bx
	
	push ax
	
	; entrada = Y*80+X
	
	mov ax,80
	mul dx
	add ax,cx
	
	mov bx,2 ; calcular o offset correto
	mul bx 
	
	mov bx,ax
	
	pop ax
		
	mov [es:bx], ax
	
	pop es
	popa
	ret
	
	
;	escreve uma string terminada em 0 na tela na posição do cursor

;	ES:BX = inicio da string terminada em 0

vga_string:
	push ax
	push bx
	.loop:
		mov al,[es:bx]
		cmp al,0
		je .fim
		call vga_colocar_caractere_cursor
		inc bx
		jmp .loop
	.fim:
		pop bx
		pop ax
		ret
		
		

;retrocede uma letra		

vga_retroceder:
	push ax
	
	mov al,' ' ; espaço
	
	cmp byte [vga_cursor_x],0
	jne .mesma_linha
	
	cmp byte [vga_cursor_y],0
	je .fim
	
	;retroceder y e deixar o x no lado direito da tela inteiramente
	
	dec byte [vga_cursor_y]
	mov byte [vga_cursor_x], 79
	
	call vga_colocar_caractere_cursor
	
	dec byte [vga_cursor_y]
	mov byte [vga_cursor_x], 79
	
	jmp .fim
	
	.mesma_linha:
	
	; retroceder x uma vez
	
	dec byte [vga_cursor_x]
	call vga_colocar_caractere_cursor
	dec byte [vga_cursor_x]
	
	.fim:
	
	call vga_atualizar_cursor
	
	pop ax
	ret
	
	; da print em um by
	
	
;AL = byte a colocar
	
vga_colocar_byte_cursor:
	pusha
	
	;deixar o nibble baixo de al em ah
	mov ah,al
	shr al,4
	
	mov cx,2
	
	;colocar na tela a nibble alta e a baixa.
	
	.loop:
	
		and al,0x0F
		
		movzx bx,al
		
		mov al,.dados_hex[bx]
		
		call vga_colocar_caractere_cursor
	
		mov al,ah
	loop .loop
	
	popa
	ret 
	
	.dados_hex: db "0123456789ABCDEF"
	
vga_colocar_word_cursor:
	
	push ax
		
	mov al,ah
	call vga_colocar_byte_cursor
		
	pop ax
	
	call vga_colocar_byte_cursor
	
	ret
	
;----------------------------------------------------------
;						 Interrupts                       |
;----------------------------------------------------------

;		As interrupts vão ser feitas assim como as da BIOS são.
;		AH é a função de uma interrupt a ser chamada

interrupt_head:
	push ax
	mov ax,0x1000
	mov ds,ax
	pop ax
	ret

;
;		A interrupt 0x20 vai ser utilizada para funções de dar output de texto na tela
;
;		AH
;		0x0: resetar configurações anteriores (limpa a tela, move o cursor para o topo superior esquerdo e torna a cor cinza com o fundo escuro)
;		0x1: mudar a cor - CH = cor do fundo, CL = cor da letra. 
;		0x2: colocar caractere na posição do cursor - AL = caractere
;		0x3: colocar string na posição do cursor - ES:BX = inicio da string terminada em 0
;		0x4: colocar caractere em um lugar da tela - AL = caractere, BH = cor, CX = x, DX = y
;		0x5: retrocede o cursor em um, limpando o caractere antigo
;		0x6: coloca os conteudos do registro AL na tela.

interrupt_20:
	
	push ds
	call interrupt_head
	
	cmp ah,0
	je .ah_0
	cmp ah,1
	je .ah_1
	cmp ah,2
	je .ah_2
	cmp ah,3
	je .ah_3
	cmp ah,4
	je .ah_4
	cmp ah,5
	je .ah_5
	cmp ah,6
	je .ah_6
	
	pop ds
	iret
	
	.ah_0:
		call vga_resetar
		pop ds
		iret
	.ah_1:
		call vga_mudar_cor
		pop ds
		iret
	.ah_2:
		call vga_colocar_caractere_cursor
		pop ds
		iret
	.ah_3:
		call vga_string
		pop ds
		iret
	.ah_4:
		call vga_caractere
		pop ds
		iret
	.ah_5:
		call vga_retroceder
		pop ds
		iret
	.ah_6:
		call vga_colocar_byte_cursor
		pop ds
		iret
		

;		A interrupt 0x21 vai ser utilizada para funções de teclado
;
;		AH
;		0x0: retornar a ultima tecla apertada (retorna o caractere ascii em AL ou 00 se não for uma tecla valida ou não ter nenhuma sendo pressionada)
;		0x1: esperar por um aperto de tecla (retorna o caractere ascii em AL)
;

interrupt_21:

	push ds
	call interrupt_head
	
	cmp ah,0
	je .ah_0
	cmp ah,1
	je .ah_1
	
	pop ds
	iret
	
	.ah_0:
		call teclado_ultima_apertada
		pop ds
		iret
		
	.ah_1:
		call teclado_esperar_por_tecla
		pop ds
		iret
		
		

;        A interrupt 0x22 vai ser utilizada para serviços de leitura de disco
;
;        AH
;        0x0: carrega um arquivo para memoria - ES:BX aponta para o nome do arquivo e retorna o seguimento do arquivo em ES, o numero do programa em CX e se foi um sucesso ou um erro em AL, DL significa o tipo de alocamento
;        0x1: carrega o diretório raiz - ES:BX aponta para o lugar na memoria aonde carrega-lo
;        0x2: carrega setores para a memoria - DX é o numero do setor em LBA, CX é o numero de setores a serem carregados e ES:BX aponta para aonde carregar-los. retorna 0 em AL ou um código de erro.
;        0x3: reseta o disco
;        0x4: carrega uma cluster chain para e memória - ES:BX aponta para aonde carregar e DX é o cluster inicial. Destroi AH e retorna não zero em AL se ocorreu um erro.
;        0x5: carrega a FAT para memória. ES:BX aponta para aonde carregar a FAT.
;		 0x6: escreve setores no disco - DX é o numero do setor em LBA, CX é o numero de setores a serem escrevidos e ES:BX aponta para o lugar onde vai ser usado para escrever
;		 0x7: cria um arquivo no disco - ES:BX aponta para o nome e dl são os atributos.
;		 0x8: escreve um arquivo no disco - ES:BX aponta para o nome, AL é o numero de clusters, CX:DX aponta para aos dados que serão escritos no disco

interrupt_22:

	push ds
	call interrupt_head

	cmp ah,0
	je .ah_0
	cmp ah,1
	je .ah_1
	cmp ah,2
	je .ah_2
	cmp ah,3
	je .ah_3
	cmp ah,4
	je .ah_4	
	cmp ah,5
	je .ah_5
	cmp ah,6
	je .ah_6
	cmp ah,7
	je .ah_7
	cmp ah,8
	je .ah_8
	
	
	pop ds
	iret 
	
	.ah_0:
		call disco_fat12_carregar_arquivo
		pop ds
		iret
	.ah_1:
		call disco_fat12_carregar_diretorio_raiz
		pop ds
		iret
	.ah_2:
		mov ax,dx
		call disco_carregar_setores
		pop ds
		iret
	.ah_3:
		call disco_resetar
		pop ds
		iret
	.ah_4:
		mov ax,dx
		call disco_fat12_carregar_clusters
		pop ds
		iret
	.ah_5:
		call disco_fat12_carregar_FAT
		pop ds
		iret
	.ah_6:
		mov ax,dx
		call disco_escrever_setores
		pop ds
		iret
	.ah_7:
		call disco_criar_arquivo
		pop ds
		iret
	.ah_8:
		call disco_fat12_escrever_para_arquivo
		pop ds
		iret


;		A interrupt 0x23 vai ser utilizada para retornar o controle ao sistema não importa o que estiver carregado na memória.
;		Retira todos os programas não residentes e deixa o espaço livre.

interrupt_23:

;reconfigurar o stack, o DS e o ES
	mov ax,0x2000
	mov ss,ax
	mov sp,0x3FFE
	mov ax,0x1000
	mov es,ax
	mov ds,ax
	
	call mem_desalocar_nao_residentes
	
	mov byte [mem_programa_atual],5
	
	sti
	
	; se o sistema estiver inicializando, retornar a inicialização
	
	mov al,[autoexec_acontecendo]
	
	test al,al
	jnz auto_exec.continuar_carregando
	
	mov sp,0x4000
	
	jmp sistema_principal


;		A interrupt 0x24 vai ser utilizada para gerenciamento de memória.

;		AH
;		0x0: Aloca 64k para o programa. CL = estilo de reservamento (1 = normal, 2 = residente, 3 = temporario); Retorna segmento em ES e numero de programa em CX e AL =/= 0 se um erro aconteceu. (1 = sem memoria livre)
;		0x1: Desaloca um segmento. BX = segmento a desalocar
	
interrupt_24:
	
	push ds
	call interrupt_head
	
	cmp ah,0
	je .ah_0
	cmp ah,1
	je .ah_1
	
	pop ds
	iret
	
	.ah_0:
		
		mov ch,[mem_programa_atual]
		call mem_reservar
		pop ds
		iret
		
	.ah_1:
		call mem_desalocar
		pop ds
		iret


inicio1: db "Bem vindo ao ",0
inicio2: db "MathOS",0
inicio3: db "!",0xA,"Insira um arquivo para carregar ou 'listar' para listar arquivos no disco:",0
sh_erro_nao_encontrado: db    "ERRO: Arquivo nao encontrado!",0
sh_erro_arquivo_leitura: db   "ERRO: Falha na leitura!", 0
sh_erro_arquivo_mem_cheia: db "ERRO: Memoria do sistema cheia!", 0
sh_erro_desconhecido:      db "ERRO: Um erro desconhecido aconteceu!",  0
sh_autoexec_erro_boot_cfg: db "Falha ao carregar BOOT.CFG!", 0xA, 0
sh_autoexec_nome:	db "BOOT    CFG"
