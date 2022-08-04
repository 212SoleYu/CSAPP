	.file	"p326.c"
	.text
	.globl	fun_a
	.type	fun_a, @function
fun_a:
.LFB0:
	.cfi_startproc
	movl	$0, %eax
	jmp	.L2
.L3:
	xorq	%rdi, %rax
	shrq	%rdi
.L2:
	testq	%rdi, %rdi
	jne	.L3
	andl	$1, %eax
	ret
	.cfi_endproc
.LFE0:
	.size	fun_a, .-fun_a
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
