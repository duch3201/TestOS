[bits 16]


mov bx,ds
mov es,bx

loop_principal:
	
	call coletar_dados
	
	mov al,[tipo_atual]
	and al,1
	jnz .mostrar_ascii
	call mostrar_dados_hex
	jmp .dados_teclado
	.mostrar_ascii:
	call mostrar_dados_ascii
	.dados_teclado:
	mov ah, 1
	int 0x21
	;se não for uma tecla valida, pegue denovo
	test al,al
	jz .dados_teclado
	
	cmp al,'s'
	je retornar_ao_sistema
	
	cmp al,'o'
	jne .letra_i
	
	inc word [setor_atual]
	
	.letra_i:
	
	cmp al,'i'
	jne .letra_e
	
	dec word [setor_atual]
	
	.letra_e:
	
	cmp al,'e'
	jne .letra_a
	
	call selecionar_setor
	
	.letra_a:
	cmp al,'a'
	jne loop_principal
	
	xor byte [tipo_atual],1
	
	jmp loop_principal

retornar_ao_sistema:

	int 0x23

selecionar_setor:
	
	;limpar tela
	
	mov ah,0
	int 0x20
	
	;fundo preto com letras cinzas claras
	mov ah,1
	mov ch,0
	mov cl,7
	int 0x20
	
	;colocar texto de informação na tela
	
	mov ah,3
	mov bx,mensagem_escolher_setor
	int 0x20
	
	;coletar setor do usuario
	
	xor bx,bx
	
	.loop:
	
		mov ah,1
		int 0x21
		cmp al,'q'
		je .fim
		cmp al,0xA
		je .aplicar_mudancas
		cmp al,8
		jne .verificar_numero
		
		;se bx for 0, não faça nada
		
		test bx,bx
		jz .loop
		
		;remover um numero do buffer
		
		dec bx
		mov byte buffer_coleta_dados[bx], 0
		
		;retroceder no vga
		
		mov ah,5
		int 0x20
		
		jmp .loop
		
		.verificar_numero:
		
		;verificar se é um numero
		
		cmp al,'0'
		jb .loop
		cmp al,'9'
		ja .verificar_letra
		
		;é um numero.
		;verificar se iremos ultrapassar o limite:
		
		cmp bx,4
		jae .loop
		
		;transformar em um numero valido
		
		mov cl,al
		sub cl,'0'
		
		;tudo certo, colocar o caractere na tela e no buffer.
		
		call .colocar_caractere
		
		jmp .loop
		
		.verificar_letra:
		
		;verificar se é uma letra hex 
		
		cmp al,'a'
		jb .loop
		cmp al,'f'
		ja .loop
		
		;é uma letra hex
		;verificar se iremos ultrapassar o limite:
		
		cmp bx,4
		jae .loop
		
		;transformar em um numero valido
		
		mov cl,al
		sub cl,'a'
		add cl,0xA
		
		;tudo certo, colocar o caratere na tela e no buffer.
		
		call .colocar_caractere
	
	jmp .loop
	
	.aplicar_mudancas:
	
		mov cx,4
		mov si,buffer_coleta_dados+3
		xor dx,dx
		xor bx,bx
		std
		
		.loop_mudancas:
			
			push cx
			
			mov cx,bx
			
			lodsb
			
			movzx ax,al
			
			shl ax,cl
			
			or dx,ax
			
			add bl,4
			
			pop cx
		
		loop .loop_mudancas
		
		cld
		
		mov [setor_atual],dx
	
	.fim:
	
	ret 
	
	
	.colocar_caractere:
		
		;colocar o caractere na tela e no buffer.
		
		mov ah,2
		int 0x20
		
		mov buffer_coleta_dados[bx], cl
		inc bx
		
		ret

coletar_dados:
	
	mov ah,2
	mov dx,[setor_atual]
	mov cx,1
	mov bx,dados
	
	int 0x22
	
	;A FAZER: em caso de erro de leitura, faça algo lol
	
	ret 

mostrar_header:

;limpar tela 

	mov ah,0
	int 0x20
	
	;fundo verde claro letra preta
	
	mov ah,1
	mov ch,0xA
	mov cl,0
	
	int 0x20
	
	;colocar header na tela
	
	mov ah,3
	mov bx,topo
	
	int 0x20
	
	mov ah,6
	mov al,[setor_atual+1]
	int 0x20
	mov al,[setor_atual]
	int 0x20
	
	;preenchero o espaço vazio com a cor verde
	
	mov cx,80 - 74
	
	.loop_preencher:
		mov al,' '
		mov ah,2
		int 0x20
	loop .loop_preencher
	
	ret

mostrar_dados_ascii:
	
	call mostrar_header
	
	;duas linhas para baixo
	
	mov al,0xA
	int 0x20
	mov al,0xA
	int 0x20
	
	;fundo escuro com letras brancas
	
	mov ah,1
	mov ch,0
	mov cl,7
	
	int 0x20
	
	;mostrar dados na tela

	mov si,dados
	
	mov cx,20
	
	.loop_y:
		
		mov ah,2
		mov al,' '
		int 0x20
		
		push cx 
		
		mov cx,26
		
		.loop_x:
		
			mov ah,2
		
			lodsb
			
			cmp al,0xA
			jne .continuar
			
			mov al,' '
			
			.continuar:
			
			int 0x20
			
			mov ah,2
			mov al,' '
			int 0x20
			
		
		loop .loop_x
		
		pop cx 
		
		mov ah,2
		mov al,' '
		int 0x20
	
	loop .loop_y
	
	;retirar 25 caracteres do final
	
	mov cx,25
	
	mov ah,5
	
	.loop_retirar:
	
		int 0x20
	
	loop .loop_retirar
	
	ret
	
	ret

mostrar_dados_hex:

	call mostrar_header
	
	;duas linhas para baixo
	
	mov al,0xA
	int 0x20
	mov al,0xA
	int 0x20
	
	;fundo escuro com letras brancas
	
	mov ah,1
	mov ch,0
	mov cl,7
	
	int 0x20
	
	;mostrar dados na tela

	mov si,dados
	
	mov cx,20
	
	.loop_y:
		
		mov ah,2
		mov al,' '
		int 0x20
		
		push cx 
		
		mov cx,26
		
		.loop_x:
		
			mov ah,6
		
			lodsb
			
			int 0x20
			
			mov ah,2
			mov al,' '
			int 0x20
			
		
		loop .loop_x
		
		pop cx 
		
		mov ah,2
		mov al,' '
		int 0x20
	
	loop .loop_y
	
	;retirar 25 caracteres do final
	
	mov cx,25
	
	mov ah,5
	
	.loop_retirar:
	
		int 0x20
	
	loop .loop_retirar
	
	ret


tipo_atual:	db 0 ; 0 = hex 1 = ascii
buffer_coleta_dados: times 4 db 0
topo:	db "(S)air | Pr(O)ximo | Anter(I)or | S(E)tor | (A)lternar | Setor atual: ", 0
mensagem_escolher_setor: db "Insira o setor a ser lido (em hexadecimal, limite de FFFF) ou aperte Q para cancelar: ", 0
setor_atual: dw 0

dados:
