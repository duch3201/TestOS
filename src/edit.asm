; Editor de texto para o SSE

mov [segmento_programa], es

mov ah,0
mov cl,1
int 0x24 

mov [segmento_texto], es
mov [texto_num], cl

xor bx,bx

; end of file

mov byte [es:bx], 26

call desenhar_cabecalho 

loop_principal:

cli
hlt

int 0x23 ; retornar 


;	SUBROTINAS


desenhar_cabecalho:
	
	xor ah,ah ; limpar tela
	int 0x20
	
	mov ch,0xA 	; fundo verde claro 
	xor cl,cl  	; letras pretas
	mov ah,1	; mudar cor
	int 0x20
	
	mov es,[segmento_programa]
	mov bx,cabecalho
	mov ah,3	; string
	int 0x20 

	xor bx,bx ; offset 0
	mov ah, 2 ; desenhar caractere
	.loop1:
		mov al, nomearquivo_h[bx]
		test al,al
		jz .loop1_break
		int 0x20
		inc bx
		jmp .loop1
	.loop1_break:
		
		


;	VARIAVEIS

segmento_programa: 	dw 0
segmento_texto: 	dw 0
offset_texto:		dw 0
texto_num:			db 0
nomearquivo_h: times 12 db ""
db 0
cabecalho: db "THIS IS A TEST."
cabecalho_fim: db 0
cabecalho_tamanho equ cabecalho_fim - cabecalho