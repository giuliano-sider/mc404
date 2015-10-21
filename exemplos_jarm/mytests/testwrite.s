.syntax unified
.text
.global main
.align
main:
push { lr }

	@ syscall write(int fd, const void *buf, size_t count)
	mov r0, 1 @ file descriptor is stdout
	ldr r1, =TongPo
	mov r2, =TongPoLength
	mov r7, #4 @ write is syscall #4. eabi convention to put it in r7
    svc #0x5555 @ invoke syscall 

pop { pc }

.data
.align
TongPo: .asciz "lutador tailandês\n"
TongPoLength = . - TongPo