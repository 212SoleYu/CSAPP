	.file	"p342.c"
	.text
	.globl	fun
	.type	fun, @function
fun:
.LFB0:
	.cfi_startproc
	movl	$0, %eax
	jmp	.L2
.L3:
	addq	(%rdi), %rax
	movq	8(%rdi), %rdi
.L2:
	testq	%rdi, %rdi
	jne	.L3
	rep ret
	.cfi_endproc
.LFE0:
	.size	fun, .-fun
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
