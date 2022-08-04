	.file	"xor.c"
	.text
	.globl	xor
	.type	xor, @function
xor:
.LFB0:
	.cfi_startproc
	movq	%rdi, %rax
	ret
	.cfi_endproc
.LFE0:
	.size	xor, .-xor
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
