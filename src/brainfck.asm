


[bits 16]


;			Brainfuck Interpreter for my OS.


;   Print a message asking for a file

mov ah,3
mov bx, ds
mov es, bx
mov bx,msg_welcome

int 0x20

;	Get the file name from the user 

mov bx,0

get_filename_loop:
	
	
	mov ah,1 ; get input
	int 0x21

	.enter:

	cmp al,0xA
	jne .backspace
	
	mov ah,2 ; print character
	int 12h
	
	jmp load_file
	
	.backspace:
	
	cmp al,8
	jne .general_key
	
	test bx,bx
	jz .continue
	
	mov ah,5 ;return
	int 0x20
	
	dec bx
	
	mov byte filename_user_buffer[bx], 0
	
	jmp .continue
	
	.general_key:
	
	cmp bx,12
	je .continue
	
	mov ah,2
	int 0x20
	
	mov filename_user_buffer[bx], al
	inc bx
	
	.continue:
	
	jmp get_filename_loop


load_file:
	
	;convert the filename from human readable to FAT12 8.3 name
	
	mov si,filename_user_buffer
	mov di,filename_buffer
	
	.loop:
		lodsb
		
		test al,al
		jz .converted
		
		cmp al,'.'
		jne .test_char
		
		mov di,filename_buffer+8
		jmp .continue
		
		.test_char:
		
		cmp al,'a'
		jb .all_good
		
		cmp al,'z'
		ja .all_good
		
		;make it uppercase
		
		and al,0b11011111
		
		.all_good:
		
		stosb
		
		
		.continue:
		
	jmp .loop
	
	.converted:
	
	mov ah,3
	mov bx,filename_buffer
	int 0x20
	
	cli
	hlt
	
	
int 0x23

filename_user_buffer: times 13 db 0
filename_buffer: times 11 db " "
db 0
msg_welcome: db "Brainfuck Interpreter for SSE", 0xA, "Insert file name: ", 0
msg_file_not_found: db "File not found!",0