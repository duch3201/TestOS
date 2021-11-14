all:
	nasm -f bin src/boot.asm     -o bin/boot.o
	nasm -f bin src/kernel.asm   -o bin/kernel.bin
	nasm -f bin src/listar.asm   -o bin/listar
	nasm -f bin src/limpar.asm   -o bin/limpar
	nasm -f bin src/lerdisco.asm -o bin/lerdisco
	nasm -f bin src/snake.asm    -o bin/snake.aex
	cp boot.cfg bin	

pack: all
	
	dd if=/dev/zero of=bootdisk.img bs=512 count=2880
	dd if=bin/boot.o of=bootdisk.img bs=512 conv=notrunc count=1
	cd bin; mcopy -i ../bootdisk.img {kernel.bin,listar,limpar,lerdisco,boot.cfg,snake.aex} ::/
 


test: pack
	
	qemu-system-x86_64  -monitor stdio -drive file=bootdisk.img,format=raw,if=floppy -soundhw pcspk

clean:
	rm bin/*


