nasm -fbin -o bin\kernel.bin src\kernel.asm
nasm -fbin -o bin\boot.bin src\boot.asm
nasm -fbin -o bin\listar src\listar.asm
nasm -fbin -o bin\limpar src\limpar.asm
nasm -fbin -o bin\lerdisco src\lerdisco.asm
nasm -fbin -o bin\snake.aex src\snake.asm
nasm -fbin -o bin\editor.aex src\edit.asm

del bootdisk.img||echo no image found

fat_imgen -c -f bootdisk.img
fat_imgen -m -f bootdisk.img -s bin\boot.bin
fat_imgen -m -f bootdisk.img -i bin\kernel.bin
fat_imgen -m -f bootdisk.img -i bin\listar
fat_imgen -m -f bootdisk.img -i bin\limpar
fat_imgen -m -f bootdisk.img -i bin\lerdisco
fat_imgen -m -f bootdisk.img -i bin\snake.aex
fat_imgen -m -f bootdisk.img -i src\boot.cfg
fat_imgen -m -f bootdisk.img -i bin\editor.aex