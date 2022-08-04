	.file	"rfun.c"
	.text
	.globl	rfun
	.type	rfun, @function
rfun:
.LFB0:
	.cfi_startproc
	testq	%rdi, %rdi
	je	.L3
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	movq	%rdi, %rbx
	shrq	$2, %rdi
	call	rfun
	addq	%rbx, %rax
	jmp	.L2
.L3:
	.cfi_def_cfa_offset 8
	.cfi_restore 3
	movl	$0, %eax
	ret
.L2:
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	popq	%rbx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE0:
	.size	rfun, .-rfun
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.5) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
