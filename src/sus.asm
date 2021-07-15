[bits 16]

mov bx,ds
mov es,bx
mov bx,hate_crimes
mov ah,3

int 20h

mov ch,0b0
mov cl,4
mov ah,1

int 20h

mov bx,why
mov ah,3
int 20h

mov cl,7
mov ah,1
int 20h

mov bx,please
mov ah,3
int 20h

mov ah,1
int 21h

mov al,'a'

mov ah,1
mov ch,7
mov cl,4
int 20h

mov ah,3
mov bx,i_cant
int 20h

mov ax,0xAA
push ax
push ax
push ax

int 23h


hate_crimes: db 0xA, "WHEN THE ", 0
why:		 db "IMPOSTER ", 0
please:		 db "IS SUS!", 0xA, 0
i_cant:		 db "AMOGUS!", 0