[bits 16]

;==========================================================
;	Programa de listamento de arquivos do SSE.
;==========================================================


;	Carregar o diretório raiz para memória

mov ax,ds
mov es,ax
mov bx,file_end
mov ah,1 ; carregar diretório

int 0x22 ; função de leitura de disco

;mudar a cor para fundo preto com letras cinza claro

mov ah,1
mov ch,0
mov cl,7

int 0x20

mov si,file_end
push si
mostrar_nome:
	
	lodsb
	cmp al,0 ; checar se o fim da directory foi encontrada.
	je retornar
	cmp al,0xE5 ; checar se a entrada está vazia
	je .proximo
	
	mov di,name_buffer
	stosb
	
	mov cx,7 ; 7 caracteres, um já foi feito
	xor dx,dx
	
	.loop:
		
		lodsb
		
		; se for espaço aumentar o numero de caracteres a retirar depois.
		
		cmp al,' '
		jne .cont
		
		inc dx
		
		.cont:
		
		;se tiver caracteres para retirar mas um caractere que não é um espaço for encontrado, reinicie o contador.
		
		test dx,dx
		jz .cont2
		
		cmp al,' '
		je .cont2
		
		xor dx,dx
		
		.cont2:
		
		stosb
	
	loop .loop
	
	;retirar os caracteres não nescessarios no final.
	
	mov cx,dx
	
	xor al,al
	inc cx
	std
	rep stosb
	cld
	
	;copiar a extensão para o buffer
	
	mov di,ext_buffer
	
	mov cx,3
	
	.ext_loop:
	
		lodsb
		
		cmp al,' ' ;se um espaço for encontrado, o fim da extensão foi alcançado e podemos já colocar o nome de arquivo na tela.
		je .colocar_nome
		
		stosb
	
	loop .ext_loop
	
	.colocar_nome:
	
	;colocar o nome na seguinte maneira:
	; "(name_buffer).(ext_buffer), "
	
	mov bx,name_buffer
	mov ah,3
	int 0x20
	
	mov ah,2
	mov al,'.'
	int 0x20
	
	mov ah,3
	mov bx,ext_buffer
	int 0x20
	
	mov bx,entre_nomes
	int 0x20
	
	.proximo:
		
		;ir para a proxima entrada do diretório raiz
		
		pop si 
		add si,32
		push si
		
		;zerar os buffers
		
		mov cx,13
		xor al,al
		mov di,name_buffer
		rep stosb
		
		jmp mostrar_nome

retornar:

;	2 caracteres extras que podem ser removidos foram colocados na tela.

mov cx,2
.remover:
	mov ah,5
	int 0x20
loop .remover

pop di ; limpar stack

int 0x23 ; retornar controle ao sistema.


name_buffer:	times 9 db 0
ext_buffer:		times 4	db 0
entre_nomes:	db ", ", 0
	
file_end: