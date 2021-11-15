all:
	mkdir -p bin
	nasm -f bin src/boot.asm     -o bin/boot.o
	nasm -f bin src/kernel.asm   -o bin/kernel.bin
	nasm -f bin src/list.asm   -o bin/list
	nasm -f bin src/clear.asm   -o bin/clear
	nasm -f bin src/readdisk.asm -o bin/readdisk
	nasm -f bin src/snake.asm    -o bin/snake.aex
	cp boot.cfg bin
	dd if=/dev/zero of=bootdisk.img bs=512 count=2880
	dd if=bin/boot.o of=bootdisk.img bs=512 conv=notrunc count=1
	cd bin; mcopy -i ../bootdisk.img {kernel.bin,list,clear,readdisk,boot.cfg,snake.aex} ::/
	
test: all
	
	qemu-system-x86_64  -monitor stdio -drive file=bootdisk.img,format=raw,if=floppy -soundhw pcspk

clean:
	rm bin/*
