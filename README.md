# MathOS

MathOS is a real mode monotasking operating system made for a school project.

It supports up to 5 files loaded at once and has system calls set up in a software interrupt system

Files are run by typing their name onto the prompt that the system gives at the start. 

build it by running

``make``

test it by using

``make test``

build dependencies: NASM, mtools

test dependencies: qemu-system-x86_64

![boot prompt](https://cdn.discordapp.com/attachments/837156988668346390/909599658265952307/2021-11-14-212402_720x448_scrot.png)
