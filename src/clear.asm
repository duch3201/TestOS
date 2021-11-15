[bits 16]

;programa simples que apenas limpa a tela.

mov ah,0 ; resetar driver
int 0x20 ; 

int 0x23 ; retornar controle ao sistema