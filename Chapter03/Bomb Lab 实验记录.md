# Bomb Lab 实验记录

本实验运行在Ubuntu22.04-arm64-Desktop版本虚拟机上。

实验文件包含一个可执行文件和一个C代码文件。README文件只是简单的说明。

实验的主要内容是对可执行文件反汇编得到的汇编代码进行分析。

## Phase 1

通过查看源代码文件，炸弹程序的前面是初始化工作以及判断炸弹程序的输入方式，我们直接看到phase1部分：

首先phase1接收的参数是一个字符串数组的起始地址，存放在%rdi寄存器中。

phase1调用一个string_not_equal的函数，该函数再调用一个string_length的函数。先来分析此两个函数。

```
000000000040131b <string_length>:
  40131b:	80 3f 00             	cmpb   $0x0,(%rdi)
  40131e:	74 12                	je     401332 <string_length+0x17>
  401320:	48 89 fa             	mov    %rdi,%rdx
  401323:	48 83 c2 01          	add    $0x1,%rdx
  401327:	89 d0                	mov    %edx,%eax
  401329:	29 f8                	sub    %edi,%eax
  40132b:	80 3a 00             	cmpb   $0x0,(%rdx)
  40132e:	75 f3                	jne    401323 <string_length+0x8>
  401330:	f3 c3                	repz ret 
  401332:	b8 00 00 00 00       	mov    $0x0,%eax
  401337:	c3                   	ret
```

string_length函数返回字符串的长度：字符数组的起始地址存放在%rdi中，起始阶段判断是否为0，如果为0代表到达字符串的结尾，直接返回；否则将%rdi的该地址值存放在%rdx寄存器中，对**地址值**不断加一，将**地址值减去起始地址值后结果保存至%eax寄存器**，然后判断当前%rdx地址对应的字节是否为0x0，如果为0则返回此时的%eax，即为字符串长度。

```
0000000000401338 <strings_not_equal>:
  401338:	41 54                	push   %r12
  40133a:	55                   	push   %rbp
  40133b:	53                   	push   %rbx
  40133c:	48 89 fb             	mov    %rdi,%rbx						# 将参数地址放入%rbx中进行运算
  40133f:	48 89 f5             	mov    %rsi,%rbp						# 将正确的字符串指针置入%rbp寄存器
  401342:	e8 d4 ff ff ff       	call   40131b <string_length>			# 计算参数字符串长度，结果保存至%eax
  401347:	41 89 c4             	mov    %eax,%r12d						# %r12d保存的是input的长度
  40134a:	48 89 ef             	mov    %rbp,%rdi						# %rbp指向的是正确字符串
  40134d:	e8 c9 ff ff ff       	call   40131b <string_length>			# 正确字符串的长度。
  401352:	ba 01 00 00 00       	mov    $0x1,%edx						
  401357:	41 39 c4             	cmp    %eax,%r12d		# 判断两个字符数组长度，如果长度不相等就跳转结束并返回1.
  40135a:	75 3f                	jne    40139b <strings_not_equal+0x63>	
  40135c:	0f b6 03             	movzbl (%rbx),%eax		# 将字符串的每一个字节无符号填充
  40135f:	84 c0                	test   %al,%al			# 一旦为0则说明字符串结束了
  401361:	74 25                	je     401388 <strings_not_equal+0x50>	# 跳转结束
  401363:	3a 45 00             	cmp    0x0(%rbp),%al	# 比较两个字符串数组的字节
  401366:	74 0a                	je     401372 <strings_not_equal+0x3a>	# 相等则跳转自增
  401368:	eb 25                	jmp    40138f <strings_not_equal+0x57>	# 不相等就跳转结束
  40136a:	3a 45 00             	cmp    0x0(%rbp),%al	# 比较两个字符串数组的字节
  40136d:	0f 1f 00             	nopl   (%rax)
  401370:	75 24                	jne    401396 <strings_not_equal+0x5e> 	# 不相等则跳转结束返回1
  401372:	48 83 c3 01          	add    $0x1,%rbx		# %rbp和%rbx同时自增1
  401376:	48 83 c5 01          	add    $0x1,%rbp
  40137a:	0f b6 03             	movzbl (%rbx),%eax		# 再判断是否为0
  40137d:	84 c0                	test   %al,%al		
  40137f:	75 e9                	jne    40136a <strings_not_equal+0x32> 	# 不为0则跳转
  401381:	ba 00 00 00 00       	mov    $0x0,%edx	# 此时为0说明字符串到结尾且全部相等，因此返回0表示字符串相等
  401386:	eb 13                	jmp    40139b <strings_not_equal+0x63>
  401388:	ba 00 00 00 00       	mov    $0x0,%edx
  40138d:	eb 0c                	jmp    40139b <strings_not_equal+0x63>
  40138f:	ba 01 00 00 00       	mov    $0x1,%edx 						# 跳转结束返回1
  401394:	eb 05                	jmp    40139b <strings_not_equal+0x63>
  401396:	ba 01 00 00 00       	mov    $0x1,%edx
  40139b:	89 d0                	mov    %edx,%eax
  40139d:	5b                   	pop    %rbx
  40139e:	5d                   	pop    %rbp
  40139f:	41 5c                	pop    %r12
  4013a1:	c3                   	ret 
```

通过对string_not_equal来判断给定的字符串是否与保存的字符串相等，若相等则返回0，任意不相等的情况都返回1。

```
0000000000400ee0 <phase_1>:
  400ee0:	48 83 ec 08          	sub    $0x8,%rsp
  400ee4:	be 00 24 40 00       	mov    $0x402400,%esi		# 将存放在地址0x402400中的字符串起始地址放入esi
  400ee9:	e8 4a 04 00 00       	call   401338 <strings_not_equal>
  400eee:	85 c0                	test   %eax,%eax
  400ef0:	74 05                	je     400ef7 <phase_1+0x17>
  400ef2:	e8 43 05 00 00       	call   40143a <explode_bomb>
  400ef7:	48 83 c4 08          	add    $0x8,%rsp
  400efb:	c3                   	ret    
```

phase_1的汇编代码如上，将%rsi寄存器置为一个地址0x402400，该地址指向的是正确字符串的起始地址。然后调用strings_not_equal函数，判断返回值，如果为0（字符串相等）则通过，如果为1（字符串不相等）则显示炸弹爆炸。然后恢复栈指针返回函数。

因此，我们只需要知道$0x402400处存放的字符数组，并输入相同的字符串即可。使用GDB来查看当函数phase_1执行时该处的的值即可。由于是字符数组，因此不需要考虑大小端的问题，只需要将内存的值以字节为单位打印出来即可。使用x命令读出十六进制的值，翻译为ascii码为：**Border relations with Canada have never been better.**炸弹1成功拆除。

## Phase 2

phase2中调用了一个叫做read_six_numbers的函数。先来研究这个调用的函数。

首先在phase_2中程序在栈上开辟了0x28 = 40个字节的空间，然后将栈顶指针放入%rsi传给了函数read_six_numbers。

```
000000000040145c <read_six_numbers>:
  40145c:	48 83 ec 18          	sub    $0x18,%rsp		# 在栈中开辟24个字节的空间
  401460:	48 89 f2             	mov    %rsi,%rdx		# 将参数传入的地址放入%rdx进行运算
  401463:	48 8d 4e 04          	lea    0x4(%rsi),%rcx	# %rcx = %rsi+4 地址运算
  401467:	48 8d 46 14          	lea    0x14(%rsi),%rax	# %rax = %rsi+20 地址运算
  40146b:	48 89 44 24 08       	mov    %rax,0x8(%rsp)	# 将%rax的地址值放入%rsp+0x8
  401470:	48 8d 46 10          	lea    0x10(%rsi),%rax	# %rax = %rsi+16 地址运算
  401474:	48 89 04 24          	mov    %rax,(%rsp)		# 将%rax的地址值放入%rsp栈顶
  401478:	4c 8d 4e 0c          	lea    0xc(%rsi),%r9	# %r9 = %rsi+0xc
  40147c:	4c 8d 46 08          	lea    0x8(%rsi),%r8	# %r8 = %rsi+0x8
  401480:	be c3 25 40 00       	mov    $0x4025c3,%esi	# 将0x4025c3这个地址值放入%esi作为参数
  401485:	b8 00 00 00 00       	mov    $0x0,%eax		# 返回值
  40148a:	e8 61 f7 ff ff       	call   400bf0 <__isoc99_sscanf@plt>
  40148f:	83 f8 05             	cmp    $0x5,%eax		# 返回值大于5即可返回 否则炸弹爆炸
  401492:	7f 05                	jg     401499 <read_six_numbers+0x3d>
  401494:	e8 a1 ff ff ff       	call   40143a <explode_bomb>
  401499:	48 83 c4 18          	add    $0x18,%rsp
  40149d:	c3                   	ret    
```

其中调用了sscanf函数，经过实验和资料查询，该函数是格式化输入的函数，其第一个参数是我们的输入，第二个参数是对应的格式化字符串，在本实验中是“%d %d %d %d %d %d”，表示接收6个十进制数字。因此read_six_numbers函数就是从我们的标准输入中依次读取6个十进制数字。并且其调用sscanf函数时，将读取数字所存放的位置设置为了phase2函数起始部分开辟的0x28个字节中的前0x18=24个字节，读取的数据就存放在这些位置中，让phase2来使用。

```
0000000000400efc <phase_2>:
  400efc:	55                   	push   %rbp
  400efd:	53                   	push   %rbx
  400efe:	48 83 ec 28          	sub    $0x28,%rsp		# 开辟一块长为0x28字节的空间
  400f02:	48 89 e6             	mov    %rsp,%rsi		# 将目前的栈顶指针传入read_six_numbers
  400f05:	e8 52 05 00 00       	call   40145c <read_six_numbers>
  400f0a:	83 3c 24 01          	cmpl   $0x1,(%rsp)		# 比较栈顶的4字节数与0x1的大小
  400f0e:	74 20                	je     400f30 <phase_2+0x34>	# 如果相等则跳转
  400f10:	e8 25 05 00 00       	call   40143a <explode_bomb>	# 否则炸弹爆炸
  400f15:	eb 19                	jmp    400f30 <phase_2+0x34>
  400f17:	8b 43 fc             	mov    -0x4(%rbx),%eax			# 将%rbx前一个4字节数放入%eax
  400f1a:	01 c0                	add    %eax,%eax				# %eax自增一倍
  400f1c:	39 03                	cmp    %eax,(%rbx)				# 比较%rbx对应的数和%eax大小
  400f1e:	74 05                	je     400f25 <phase_2+0x29>	# 如果相等则跳转
  400f20:	e8 15 05 00 00       	call   40143a <explode_bomb>	# 如果不等则炸弹爆炸
  400f25:	48 83 c3 04          	add    $0x4,%rbx				# %rbx向右移动4字节
  400f29:	48 39 eb             	cmp    %rbp,%rbx				# 比较%rbx和%rbp的地址关系
  400f2c:	75 e9                	jne    400f17 <phase_2+0x1b>	# 如果不为0，则循环
  400f2e:	eb 0c                	jmp    400f3c <phase_2+0x40>	# 如果为0，则跳转返回，返回值为%eax中的值
  400f30:	48 8d 5c 24 04       	lea    0x4(%rsp),%rbx	# 将栈顶第二个数地址放入%rbx
  400f35:	48 8d 6c 24 18       	lea    0x18(%rsp),%rbp	# 将栈顶后0x18 = 24字节的地址放入%rbp
  400f3a:	eb db                	jmp    400f17 <phase_2+0x1b>	# 无条件跳转
  400f3c:	48 83 c4 28          	add    $0x28,%rsp
  400f40:	5b                   	pop    %rbx
  400f41:	5d                   	pop    %rbp
  400f42:	c3                   	ret  
```

phase2函数在完成数字读取后，对应六个数字会在%rsp指针所知地址起始处依次排列。首先将第一个整数与1比较，如果不等于1则直接爆炸。因此第一个数字确定为1.后续是一个循环，从第二个整数开始比较前一个整数的两倍是否等于该函数，直到6个整数全部完成对比。因此我们的输入需要从1开始，后面的每一个输入都是前面一个数的两倍即可。**需要注意的是，如果是使用文件作为输入的情况下，最后一个数32后面需要添加一个空格或者换行符，否则不能成功读取32这个数。**最终的输入为：**1 2 4 8 16 32**。

## Phase 3

```
0000000000400f43 <phase_3>:
  400f43:	48 83 ec 18          	sub    $0x18,%rsp			# 栈指针减少0x18 = 24字节
  400f47:	48 8d 4c 24 0c       	lea    0xc(%rsp),%rcx		# 第四个参数为%rcx+0xc
  400f4c:	48 8d 54 24 08       	lea    0x8(%rsp),%rdx		# 第三个参数为%rsx+0x8
  400f51:	be cf 25 40 00       	mov    $0x4025cf,%esi		# 位于0x4025cf的格式化字符串“%d %d”
  400f56:	b8 00 00 00 00       	mov    $0x0,%eax			
  400f5b:	e8 90 fc ff ff       	call   400bf0 <__isoc99_sscanf@plt>
  400f60:	83 f8 01             	cmp    $0x1,%eax
  400f63:	7f 05                	jg     400f6a <phase_3+0x27>
  400f65:	e8 d0 04 00 00       	call   40143a <explode_bomb>	# 如果读取数目少于2个则炸弹爆炸
  400f6a:	83 7c 24 08 07       	cmpl   $0x7,0x8(%rsp)			# 读取的第一个数与0x7比较 
  400f6f:	77 3c                	ja     400fad <phase_3+0x6a>	# 如果大于7则炸弹爆炸
  400f71:	8b 44 24 08          	mov    0x8(%rsp),%eax			# 第一个数放在%eax中
  400f75:	ff 24 c5 70 24 40 00 	jmp    *0x402470(,%rax,8)		# 是一个跳转指令，按照指令地址的最低一个字节分为
  																	# 7c、b9、83、8a、91、98、9f、a6
  400f7c:	b8 cf 00 00 00       	mov    $0xcf,%eax				# 除b9外，其他分支都是给%eax复制后与第二个读取数比较，相等则恢复
  400f81:	eb 3b                	jmp    400fbe <phase_3+0x7b>
  400f83:	b8 c3 02 00 00       	mov    $0x2c3,%eax
  400f88:	eb 34                	jmp    400fbe <phase_3+0x7b>
  400f8a:	b8 00 01 00 00       	mov    $0x100,%eax
  400f8f:	eb 2d                	jmp    400fbe <phase_3+0x7b>
  400f91:	b8 85 01 00 00       	mov    $0x185,%eax
  400f96:	eb 26                	jmp    400fbe <phase_3+0x7b>
  400f98:	b8 ce 00 00 00       	mov    $0xce,%eax
  400f9d:	eb 1f                	jmp    400fbe <phase_3+0x7b>
  400f9f:	b8 aa 02 00 00       	mov    $0x2aa,%eax
  400fa4:	eb 18                	jmp    400fbe <phase_3+0x7b>
  400fa6:	b8 47 01 00 00       	mov    $0x147,%eax
  400fab:	eb 11                	jmp    400fbe <phase_3+0x7b>
  400fad:	e8 88 04 00 00       	call   40143a <explode_bomb>
  400fb2:	b8 00 00 00 00       	mov    $0x0,%eax
  400fb7:	eb 05                	jmp    400fbe <phase_3+0x7b>
  400fb9:	b8 37 01 00 00       	mov    $0x137,%eax
  400fbe:	3b 44 24 0c          	cmp    0xc(%rsp),%eax
  400fc2:	74 05                	je     400fc9 <phase_3+0x86>
  400fc4:	e8 71 04 00 00       	call   40143a <explode_bomb>
  400fc9:	48 83 c4 18          	add    $0x18,%rsp
  400fcd:	c3                   	ret    
```

函数先将栈减少24字节，然后又是使用sscanf函数来进行格式化读取，读取到的数据存放在栈指针后的0x8和0xc位置。格式化字符串是“%d %d”，说明要读取两个十进制数。成功读取后对于第一个操作数将其与0x7做无符号数比较，只有当其在0x0-0x7范围内才能进行下一步。400f75指令使用一个绝对地址加偏移量的形式跳转，是一个条件分支的结构。在gdb中将个条件分支找到，对应地址高2字节一致，低字节为7c、b9、83、8a、91、98、9f、a6。各个分支跳转后给%eax赋一个固定的值，如果输入的第二个数与该数相同即可。因此该题有多种解法，根据汇编指令中给出的值匹配即可，如“0 207”。

## Phase 4

该函数时phase4中引用的函数，其返回的值必须要为0，否则炸弹爆炸。在调用前为其准备了参数，%edi = 第一个参数 %esi = 0x0 %edx = 0xe

```
0000000000400fce <func4>:
  400fce:	48 83 ec 08          	sub    $0x8,%rsp			# 栈上开辟8个字节
  400fd2:	89 d0                	mov    %edx,%eax			# %eax = 0xe
  400fd4:	29 f0                	sub    %esi,%eax			# %eax = %eax - %esi = 0xe-0x0 = 0xe
  400fd6:	89 c1                	mov    %eax,%ecx			# %ecx = %eax = %edx - %esi
  400fd8:	c1 e9 1f             	shr    $0x1f,%ecx			# %ecx>>31 逻辑右移
  400fdb:	01 c8                	add    %ecx,%eax			# %eax = %eax+%ecx
  400fdd:	d1 f8                	sar    %eax					# %eax算术右移一位
  400fdf:	8d 0c 30             	lea    (%rax,%rsi,1),%ecx	# %ecx = %rax + %rsi = %eax + %esi
  400fe2:	39 f9                	cmp    %edi,%ecx			# %ecx和%edi比较，
  400fe4:	7e 0c                	jle    400ff2 <func4+0x24>	# 若%ecx小于等于%edi，则跳转
  400fe6:	8d 51 ff             	lea    -0x1(%rcx),%edx		# 否则%edx自减1
  400fe9:	e8 e0 ff ff ff       	call   400fce <func4>		# 重新调用自身
  400fee:	01 c0                	add    %eax,%eax			
  400ff0:	eb 15                	jmp    401007 <func4+0x39>
  400ff2:	b8 00 00 00 00       	mov    $0x0,%eax
  400ff7:	39 f9                	cmp    %edi,%ecx			# 若%ecx大于等于%edi，则成功返回
  400ff9:	7d 0c                	jge    401007 <func4+0x39>
  400ffb:	8d 71 01             	lea    0x1(%rcx),%esi
  400ffe:	e8 cb ff ff ff       	call   400fce <func4>
  401003:	8d 44 00 01          	lea    0x1(%rax,%rax,1),%eax
  401007:	48 83 c4 08          	add    $0x8,%rsp
  40100b:	c3                   	ret  
```

该函数设定了起始的参数，a = input，b = 0x0，c = 0xe，其功能是计算（c-b）加上该差值的符号位后除以2，再加上b的值是否与input相等。由于起始的参数固定，因此不需要过多探究函数内部逻辑就可以得到目的输入为7.（400fee指令不会到达）


```
000000000040100c <phase_4>:
  40100c:	48 83 ec 18          	sub    $0x18,%rsp
  401010:	48 8d 4c 24 0c       	lea    0xc(%rsp),%rcx
  401015:	48 8d 54 24 08       	lea    0x8(%rsp),%rdx
  40101a:	be cf 25 40 00       	mov    $0x4025cf,%esi
  40101f:	b8 00 00 00 00       	mov    $0x0,%eax
  401024:	e8 c7 fb ff ff       	call   400bf0 <__isoc99_sscanf@plt> #与phase3情况相同，读取两个十进制数
  401029:	83 f8 02             	cmp    $0x2,%eax	# 读取的操作数与2比较，不等于2就爆炸
  40102c:	75 07                	jne    401035 <phase_4+0x29>		
  40102e:	83 7c 24 08 0e       	cmpl   $0xe,0x8(%rsp)		# 读取的第一个数与0xe比较
  401033:	76 05                	jbe    40103a <phase_4+0x2e># 如果小于等于0xe则跳转，否则爆炸
  401035:	e8 00 04 00 00       	call   40143a <explode_bomb>
  40103a:	ba 0e 00 00 00       	mov    $0xe,%edx			# %edx = 0xe
  40103f:	be 00 00 00 00       	mov    $0x0,%esi			# %esi = 0x0
  401044:	8b 7c 24 08          	mov    0x8(%rsp),%edi		# %edi = 第一个参数
  401048:	e8 81 ff ff ff       	call   400fce <func4>
  40104d:	85 c0                	test   %eax,%eax
  40104f:	75 07                	jne    401058 <phase_4+0x4c># 返回值不为0就爆炸
  401051:	83 7c 24 0c 00       	cmpl   $0x0,0xc(%rsp)		# 第二个参数与0比较
  401056:	74 05                	je     40105d <phase_4+0x51># 如果相等则成功返回，否则爆炸
  401058:	e8 dd 03 00 00       	call   40143a <explode_bomb>
  40105d:	48 83 c4 18          	add    $0x18,%rsp
  401061:	c3                   	ret    
```

可以看到Phase4前面部分与phase3相同，都是读取两个十进制整数，并且第一个函数作为参数进入func4并且需要返回值为0，第二个函数直接与0比较。通过前面的分析，可以得到这样的两个数为**7和0**.

## Phase 5

```
0000000000401062 <phase_5>:
  401062:	53                   	push   %rbx					
  401063:	48 83 ec 20          	sub    $0x20,%rsp				# 栈上开辟0x20=32个字节的空间
  401067:	48 89 fb             	mov    %rdi,%rbx				# 将%rdi保存到%rbx中
  40106a:	64 48 8b 04 25 28 00 	mov    %fs:0x28,%rax			# 
  401071:	00 00 
  401073:	48 89 44 24 18       	mov    %rax,0x18(%rsp)
  401078:	31 c0                	xor    %eax,%eax
  40107a:	e8 9c 02 00 00       	call   40131b <string_length>	# 判断字符串长度
  40107f:	83 f8 06             	cmp    $0x6,%eax				# 为6则跳转 
  401082:	74 4e                	je     4010d2 <phase_5+0x70>	
  401084:	e8 b1 03 00 00       	call   40143a <explode_bomb>	# 否则爆炸
  401089:	eb 47                	jmp    4010d2 <phase_5+0x70>
  40108b:	0f b6 0c 03          	movzbl (%rbx,%rax,1),%ecx		# 将%rbx+%rax处的一个字节提取出来放在%ecx中
  40108f:	88 0c 24             	mov    %cl,(%rsp)				# 将%ecx中1字节放在栈顶
  401092:	48 8b 14 24          	mov    (%rsp),%rdx				# 将该元素放在%rdx
  401096:	83 e2 0f             	and    $0xf,%edx				# %edx低4比特掩码求值，范围0-15
  401099:	0f b6 92 b0 24 40 00 	movzbl 0x4024b0(%rdx),%edx		# 将地址0x4024b0加上%rdx中的值，存到%edx中
  4010a0:	88 54 04 10          	mov    %dl,0x10(%rsp,%rax,1)	# %dl中移动至%rsp+%rax+0x10
  4010a4:	48 83 c0 01          	add    $0x1,%rax				# %rax+1
  4010a8:	48 83 f8 06          	cmp    $0x6,%rax				# rax与0x6比较
  4010ac:	75 dd                	jne    40108b <phase_5+0x29>	# 不相等就向上循环
  4010ae:	c6 44 24 16 00       	movb   $0x0,0x16(%rsp)			# 相等则将一个字节送至%rsp+0x16
  4010b3:	be 5e 24 40 00       	mov    $0x40245e,%esi			# 将一个地址放在%esi
  4010b8:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi			# %rsp+0x10作为第一个参数
  4010bd:	e8 76 02 00 00       	call   401338 <strings_not_equal>
  4010c2:	85 c0                	test   %eax,%eax				# 判断返回值
  4010c4:	74 13                	je     4010d9 <phase_5+0x77>	# 如果为0，说明字符串相等，则跳转
  4010c6:	e8 6f 03 00 00       	call   40143a <explode_bomb>	# 否则爆炸
  4010cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  4010d0:	eb 07                	jmp    4010d9 <phase_5+0x77>
  4010d2:	b8 00 00 00 00       	mov    $0x0,%eax				# %eax置零
  4010d7:	eb b2                	jmp    40108b <phase_5+0x29>	# 跳转
  4010d9:	48 8b 44 24 18       	mov    0x18(%rsp),%rax			# 
  4010de:	64 48 33 04 25 28 00 	xor    %fs:0x28,%rax
  4010e5:	00 00 
  4010e7:	74 05                	je     4010ee <phase_5+0x8c>
  4010e9:	e8 42 fa ff ff       	call   400b30 <__stack_chk_fail@plt>
  4010ee:	48 83 c4 20          	add    $0x20,%rsp
  4010f2:	5b                   	pop    %rbx
  4010f3:	c3                   	ret    
```

phase5中设计了栈保护者机制，但是不影响炸弹的拆除。phase5调用了string_length和strings_not_equal函数，说明该函数是要输入字符串来满足条件的。首先判断字符串长度，为6.其次将rdi指向的我们输入的字符串进行操作处理后再进行strings_not_equal的判断。操作如下：依次提取字符串中的字符，然后与0xf做与运算，结果再与一个绝对地址0x4024b0相加，将该地址的对应的各个字符依次放置在以%rsp+0x10为起点的位置。因此我们首先要找到正确的字符串，其位于0x40245e，使用gdb查看，结果为一个单词“flyers”。对应的ascii码为66、6c、79、65、72、73.因此我们每一步的索引地址要从0x4024b0为起始地点的字符串中找到16个字符距离内的字符值。通过查找，可以找到对应的偏移为9、15、14、5、6、7.因此我们的输入只需要满足低4位依次为以上值且是合法的ascii字符即可，答案不唯一。如将所有偏移加上0x30，即构成一组可视ascii字符串"9?>567"，可以满足条件。

## Phase 6

```
00000000004010f4 <phase_6>:
  4010f4:	41 56                	push   %r14
  4010f6:	41 55                	push   %r13
  4010f8:	41 54                	push   %r12
  4010fa:	55                   	push   %rbp
  4010fb:	53                   	push   %rbx
  4010fc:	48 83 ec 50          	sub    $0x50,%rsp				# 栈上开辟0x50 = 80字节的空间
  401100:	49 89 e5             	mov    %rsp,%r13				# %r13 = %rsp
  401103:	48 89 e6             	mov    %rsp,%rsi
  401106:	e8 51 03 00 00       	call   40145c <read_six_numbers># 从标准流中读入6个十进制整数，保存在当前栈顶
  40110b:	49 89 e6             	mov    %rsp,%r14				# %r14 = %rsp
  40110e:	41 bc 00 00 00 00    	mov    $0x0,%r12d				# %r12d = 0
  401114:	4c 89 ed             	mov    %r13,%rbp				# %rbp = % r13 
  401117:	41 8b 45 00          	mov    0x0(%r13),%eax			# %r13处读取的第一个参数放到%eax中
  40111b:	83 e8 01             	sub    $0x1,%eax				# %eax减去1
  40111e:	83 f8 05             	cmp    $0x5,%eax				# 与0x5进行无符号比较
  401121:	76 05                	jbe    401128 <phase_6+0x34>	# 如果小于等于5则跳转
  401123:	e8 12 03 00 00       	call   40143a <explode_bomb>	# 否则爆炸
  401128:	41 83 c4 01          	add    $0x1,%r12d				# %r12d+1
  40112c:	41 83 fc 06          	cmp    $0x6,%r12d				# %r12d与0x6比较
  401130:	74 21                	je     401153 <phase_6+0x5f>	# 如果相等则跳转
  401132:	44 89 e3             	mov    %r12d,%ebx				# 否则将%r12d的值放入%ebx
  401135:	48 63 c3             	movslq %ebx,%rax				# %ebx符号扩展到四字
  401138:	8b 04 84             	mov    (%rsp,%rax,4),%eax		# 提取栈上第i个整数
  40113b:	39 45 00             	cmp    %eax,0x0(%rbp)			# 将栈中第一个元素与该数比较
  40113e:	75 05                	jne    401145 <phase_6+0x51>	# 如果不相等则跳转
  401140:	e8 f5 02 00 00       	call   40143a <explode_bomb>	# 否则爆炸
  401145:	83 c3 01             	add    $0x1,%ebx				# %ebx+1
  401148:	83 fb 05             	cmp    $0x5,%ebx				# %ebx与0x5比较
  40114b:	7e e8                	jle    401135 <phase_6+0x41>	# 如果小于等于5，则跳回至符号扩展
  40114d:	49 83 c5 04          	add    $0x4,%r13				# 如果大于5，%r13d+4
  401151:	eb c1                	jmp    401114 <phase_6+0x20>	# 无条件跳转
  
  401153:	48 8d 74 24 18       	lea    0x18(%rsp),%rsi			# 读取栈顶+0x18的地址放在%rsi中
  401158:	4c 89 f0             	mov    %r14,%rax				# %rax = %r14 = %rsp（初始）
  40115b:	b9 07 00 00 00       	mov    $0x7,%ecx				# %ecx = 0x7
  401160:	89 ca                	mov    %ecx,%edx				# %edx = %ecx = 0x7
  401162:	2b 10                	sub    (%rax),%edx				# %edx-%rax处的数
  401164:	89 10                	mov    %edx,(%rax)				# 将运算结果放在栈上对应的位置
  401166:	48 83 c0 04          	add    $0x4,%rax				# %rax+0x4
  40116a:	48 39 f0             	cmp    %rsi,%rax				# 循环检查
  40116d:	75 f1                	jne    401160 <phase_6+0x6c>	# 如果%rax没有到%rsi，则向上循环（全部用7减）
  
  40116f:	be 00 00 00 00       	mov    $0x0,%esi				# 将%esi置0
  401174:	eb 21                	jmp    401197 <phase_6+0xa3>	# 无条件跳转
  
  401176:	48 8b 52 08          	mov    0x8(%rdx),%rdx			# %rdx+0x8
  40117a:	83 c0 01             	add    $0x1,%eax				# %eax+1
  40117d:	39 c8                	cmp    %ecx,%eax				# %eax与%ecx比较
  40117f:	75 f5                	jne    401176 <phase_6+0x82>	# 如果不相等则跳转
  401181:	eb 05                	jmp    401188 <phase_6+0x94>	# 如果相等再跳转
  
  401183:	ba d0 32 60 00       	mov    $0x6032d0,%edx			# 将%edx设置为一个值
  401188:	48 89 54 74 20       	mov    %rdx,0x20(%rsp,%rsi,2)	# 将%rdx值移动至%rsp+2*%rsi+0x20
  40118d:	48 83 c6 04          	add    $0x4,%rsi				# %rsi+0x04
  401191:	48 83 fe 18          	cmp    $0x18,%rsi				# %rsi与0x18比较
  401195:	74 14                	je     4011ab <phase_6+0xb7>	# 如果相等，则跳转
  
  401197:	8b 0c 34             	mov    (%rsp,%rsi,1),%ecx		# %ecx = 栈上的依次元素
  40119a:	83 f9 01             	cmp    $0x1,%ecx				# 若%ecx小于等于1
  40119d:	7e e4                	jle    401183 <phase_6+0x8f>	# 则跳转
  
  40119f:	b8 01 00 00 00       	mov    $0x1,%eax				# 否则将%eax置1
  4011a4:	ba d0 32 60 00       	mov    $0x6032d0,%edx			# %edx置为0x6032d0
  4011a9:	eb cb                	jmp    401176 <phase_6+0x82>	# 无条件跳转
  
  4011ab:	48 8b 5c 24 20       	mov    0x20(%rsp),%rbx			# 栈顶+0x20的值放入%rbx
  4011b0:	48 8d 44 24 28       	lea    0x28(%rsp),%rax			# 栈顶+0x28的地址放入%eax
  4011b5:	48 8d 74 24 50       	lea    0x50(%rsp),%rsi			# 栈顶+0x50的地址放入%rsi
  4011ba:	48 89 d9             	mov    %rbx,%rcx				# %rcx是遍历指针
  
  4011bd:	48 8b 10             	mov    (%rax),%rdx				# %rax地址对应的值放入%rdx
  4011c0:	48 89 51 08          	mov    %rdx,0x8(%rcx)			# %rdx值放入%rcx+0x08
  4011c4:	48 83 c0 08          	add    $0x8,%rax				# %rax+0x08
  4011c8:	48 39 f0             	cmp    %rsi,%rax				# 比较%rax和%rsi
  4011cb:	74 05                	je     4011d2 <phase_6+0xde>	# 如果相等则跳转
  4011cd:	48 89 d1             	mov    %rdx,%rcx				# 否则则将%rdx移动至%rcx
  4011d0:	eb eb                	jmp    4011bd <phase_6+0xc9>	# 跳转
  
  4011d2:	48 c7 42 08 00 00 00 	movq   $0x0,0x8(%rdx)			# 将%rdx+0x8的一个四字置为0
  4011d9:	00 
  4011da:	bd 05 00 00 00       	mov    $0x5,%ebp				# %ebp置为0x5
  4011df:	48 8b 43 08          	mov    0x8(%rbx),%rax			# %rax置为%rbx地址值
  4011e3:	8b 00                	mov    (%rax),%eax				# %rax提取该地址值
  4011e5:	39 03                	cmp    %eax,(%rbx)				# 比较
  4011e7:	7d 05                	jge    4011ee <phase_6+0xfa>	# 如果大于等于则跳转
  4011e9:	e8 4c 02 00 00       	call   40143a <explode_bomb>
  4011ee:	48 8b 5b 08          	mov    0x8(%rbx),%rbx			# %rbx+0x8
  4011f2:	83 ed 01             	sub    $0x1,%ebp				# %ebp-0x1
  4011f5:	75 e8                	jne    4011df <phase_6+0xeb>	# 如果结果不为0则向上跳转
  4011f7:	48 83 c4 50          	add    $0x50,%rsp				# 返回
  4011fb:	5b                   	pop    %rbx
  4011fc:	5d                   	pop    %rbp
  4011fd:	41 5c                	pop    %r12
  4011ff:	41 5d                	pop    %r13
  401201:	41 5e                	pop    %r14
  401203:	c3                   	ret  
```

Phase_6汇编代码过长，将其分为多个步骤进行分析：

1. 4010f4-401106：保存函数状态，并从输入流中读取六个整数，保存在栈顶六个整数的空间内。
2. 40110b-401151：对读取到的六个整数逐个判断，要求每个数都不能相同，且每个数都必须要在1-6范围内，否则炸弹爆炸。
3. 401153-40116d：将输入的六个整数每个重置为7减去对应的数。
4. 40116f-4011a9：关键步骤1，将保存的六个整数按照各自的数值进行偏移，置为六个不同的地址值。
5. 4011ab-4011d0：关键步骤2，链表重置阶段，将链表顺序按照输入地址顺序重新链接
6. 4011d2-401203：判断新链表从头开始，每个节点的前4个字节的数字是否为一个降序，如果是则拆除，否则炸弹爆炸。

对于1236阶段在实验过程中分析得到，但是45阶段在实验阶段中没有成功分析理顺，在参考他人的实验记录后明白了链表重排的过程。

因此整个实验是如下：在内存0x6032d0处存放了6个链表节点，每个链表节点占用16字节，包含一个int型的数，int型的编号，以及一个指向下一个链表的指针。我们的任务是通过索引将链表重排为一个将序列表。使用gdb来找到每个节点包含的值的大小，按照降序的顺序输入节点序号，既能得到正确结果。

