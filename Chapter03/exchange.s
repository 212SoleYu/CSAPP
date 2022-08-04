	.file	"exchange.c"
	.text
	.globl	exchange
	.type	exchange, @function
exchange:
.LFB0:
	.cfi_startproc
	movl	4(%esp), %edx
	movl	(%edx), %eax
	movl	8(%esp), %ecx
	movl	%ecx, (%edx)
	ret
	.cfi_endproc
.LFE0:
	.size	exchange, .-exchange
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.4) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
