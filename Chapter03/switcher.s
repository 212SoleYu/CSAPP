	.file	"switcher.c"
	.text
	.globl	switcher
	.type	switcher, @function
switcher:
.LFB0:
	.cfi_startproc
	cmpq	$7, %rdi
	ja	.L8
	jmp	*.L4(,%rdi,8)
	.section	.rodata
	.align 8
	.align 4
.L4:
	.quad	.L3
	.quad	.L8
	.quad	.L5
	.quad	.L8
	.quad	.L2
	.quad	.L7
	.quad	.L8
	.quad	.L5
	.text
.L7:
	xorq	$15, %rsi
	movq	%rsi, %rdx
.L3:
	leaq	112(%rdx), %rdi
	jmp	.L2
.L5:
	leaq	(%rdx,%rsi), %rdi
	salq	$2, %rdi
	jmp	.L2
.L8:
	movq	%rsi, %rdi
.L2:
	movq	%rdi, (%rcx)
	ret
	.cfi_endproc
.LFE0:
	.size	switcher, .-switcher
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
