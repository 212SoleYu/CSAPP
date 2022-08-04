	.file	"arith.c"
	.text
	.globl	arith
	.type	arith, @function
arith:
.LFB0:
	.cfi_startproc
	xorq	%rdi, %rsi
	leaq	(%rdx,%rdx,2), %rdx
	movq	%rdx, %rax
	salq	$4, %rax
	andl	$252645135, %esi
	subq	%rsi, %rax
	ret
	.cfi_endproc
.LFE0:
	.size	arith, .-arith
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
