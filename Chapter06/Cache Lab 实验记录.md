# Cache Lab 实验记录

第六章书中内容偏理论性，较容易理解，cache lab难度较大，本次实验尽量详实记录，结果可能略显冗长。

## Part A

Part A 的内容是在一个空白的c文件中完成对于一个cache simulation的编写，要求与给出的示例程序在相同的输入下输出相同，包括-h参数下的说明。由于所涉及的内容方面较多，分部分依次分析。

### 实验概述

在CMU公开的ppt中，有关于cache lab implement的部分讲解，其中包括对实验的一些前置重要说明。

ppt地址：[rec07.pdf (cmu.edu)](http://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/recitations/rec07.pdf)

首先，实验中是完成一个cache模拟器而非完整的cache，ppt中明确说明不需要对于具体的数不需要保存，cache中模拟的部分只包括有效位valid、标记域tag、以及实现cache替换策略所用的时间戳stamp，ppt中说明替换策略使用LRU。

我们的模拟器模拟cache根据输入的地址进行查找、写入、替换等操作，每一步中来实时的记录整个过程中的命中、不命中、替换次数。

### 参数设置

我们编写的csim.c文件经过编译后生成可执行文件接收参数，参数形式与给出的csim-ref文件相同，包括设置组索引位-S、字偏移-b、行数-E、trace文件-t。根据前三者将cache完成初始化，然后从文件中不断地读取访存指令直到读取完毕后返回命中数、不命中数、覆盖次数。读取指令格式为：Operation address size，Operation代表该条指令对应的内存操作，I表示取指令，L表示读数据，S表示存数据，M表示数据修改。其中M数据修改要包含两次cache的访问。实验指导书中给出，对于I指令忽略即可。

### 接收参数

我们的可执行文件要能成功的接收参数并设置，需要使用getopt函数来帮助完成。ppt中讲授了getopt函数的使用方式，我们直接对其进行简单修改即可。关于getopt函数的具体实现参考：[(29条消息) getopt()函数详解_奋斗的小面包的博客-CSDN博客_getopt](https://blog.csdn.net/c1523456/article/details/79173776)

因此我们来完成接收参数的部分，接收参数将cache型号接收，明确trace文件然后交给对应的初始化文件去完成初始化。

```c
//仅作初步的测试参数输入是否正常
int b,E,s,opt,help_mode,verbose_mode;
char filename[100];
int main(int argc,char** argv)
{
    while(-1!=(opt = (getopt(argc,argv,"hvb:E:s:t:"))))
    {
        switch (opt)
        {
        case 'h':
            help_mode = 1;
            break;
        case 'v':
            verbose_mode = 1;
            break;
        case 'b':
            b = atoi(optarg);
            break;
        case 'E':
            E = atoi(optarg);
            break;
        case 's':
            s = atoi(optarg);
            break;
        case 't':
            strcpy(filename,optarg);
            break;
        default:
            printf("Wrong argument!\n");
            break;
        }
    }
    if(help_mode==1)
    {
        system("cat help_info");
        exit(0);
    }
    printf("The number of cache sets:%d\n",s);
    printf("The number of cache lines per set:%d\n",E);
    printf("The number of word offset:%d\n",b);
    printf("The trace file:%s\n",filename);
    return 0;
}
```

### cache初始化

接收了cache规模参数之后，初始化cache的参数。

```c
//使用malloc将二维数组不断分配空间。
cache cache_init(int s,int E,int b)
{
    //s is the number of the sets
    cache ans = (cache)malloc(sizeof(cache_set) * s);
    for(int i =0;i<s;i++)
    {
        ans[i] = (cache_set)malloc(sizeof(cache_line)*E);
        for(int j =0;j<E;j++)
        {
            ans[i][j].valid=0;
            ans[i][j].tag=-1;
            ans[i][j].stamp=-1;
        }
    }
    return ans;
}
```

###	时钟更新

每经过一条指令的读取后，所有cache块对应的时钟都要自增来实现LRU机制。

```c
void time_update()
{
    for(int i =0;i<S;i++)
    {
        for(int j = 0;j<E;j++)
        {
            CacheSimulation[i][j].stamp++;
        }
    }
}
```

### cache更新

模拟实现的重点部分，cache接收一个地址，根据指令的要求进行寻找块，并且更新命中数和不命中数。

```c
void cache_update(unsigned int address)
{
    int s_index = (address>>b) & (-1U >>(64 - s));
    int tag = address>>(b+s);
    int MAX_STAMP = 0;
    int MAX_LINE =0;int total = 0;
    for(int i =0;i<E;i++)
    {
        if(CacheSimulation[s_index][i].valid==1)
        {
            total++;//count the valid lines
            if(CacheSimulation[s_index][i].tag==tag )
            {
                //match
                hit_count++;
                CacheSimulation[s_index][i].stamp=0;//reset the stamp
                return ;
            }
            if(&& CacheSimulation[s_index][i].stamp > MAX_STAMP)
            {
                //find the oldest line
                MAX_STAMP = CacheSimulation[s_index][i].stamp;
                MAX_LINE = i;
            }
        }
    }
    //miss
    //if the set not full then choose the empty line place the line
    miss_count++;
    if(total < E)
    {
        CacheSimulation[s_index][total-1].stamp = 0;
        CacheSimulation[s_index][total-1].tag = tag;
        CacheSimulation[s_index][total-1].valid = 1;
        return ;
    }
    //if the set is full,then replace the oldest one
    else if(total==E)
    {
        eviction++;
        CacheSimulation[s_index][MAX_LINE].stamp = 0;
        CacheSimulation[s_index][MAX_LINE].tag = tag;
        return ;
    }
    return ;
}
```

### 接收指令

从trace文件中不断接收指令并将其转换为int类型。其中使用到ppt中给出的fscanf函数。其用法与scanf函数类似。因此我们从文件中将指令类型和地址读出，由于前置的说明我们可以忽略对于size的操作。每读取完一行指令就对应的进行cache更新，然后再更新时间戳。注意修改指令M有两次访问cache，所以不需要添加break。

```c
void get_trace(char* f)
{
    FILE *fp = fopen(f,"r");
    if (fp == NULL)
    {
        printf("File Open Error!\n");
        return ;
    }
    char operation;//L,S,M
    unsigned int address;
    int size;
    while(fscanf(fp," %c %xu,%d\n", &operation, &address, &size) > 0)
    {
        switch(operation)
        {
            case 'L':
                cache_update(address);
                break;
            case 'M':
                cache_update(address);
            case 'S':
                cache_update(address);
                break;
        }
        time_update();
    }
    fclose(fp);
    for(int i =0;i<S;i++)
      free(CacheSimulation[i]);
    free(CacheSimulation);
    return ;
}
```

### 总函数体

整合完毕的csim.c文件全部如下：

``` c
#include "cachelab.h"
#include<unistd.h>
#include<getopt.h>
#include<stdlib.h>
#include<stdio.h>
#include<string.h>
#define INT_MAX 0xffffffff

typedef struct
{
    int valid;//valid bit
    int tag;//the tag field 
    int stamp;//the time stamp used in LRU
}cache_line,*cache_set,**cache;

int b,E,s,S,opt,help_mode,verbose_mode;
int hit_count=0,miss_count=0,eviction=0;
char filename[100];

cache CacheSimulation = NULL;//the simulation we make

cache cache_init(int s,int E,int b)
{
    //s is the number of the sets
    cache ans = (cache)malloc(sizeof(cache_set) * s);
    for(int i =0;i<s;i++)
    {
        ans[i] = (cache_set)malloc(sizeof(cache_line)*E);
        for(int j =0;j<E;j++)
        {
            ans[i][j].valid=0;
            ans[i][j].tag=0;
            ans[i][j].stamp=0;
        }
    }
    return ans;
}
void time_update()
{
    for(int i =0;i<S;i++)
    {
        for(int j = 0;j<E;j++)
        {
            CacheSimulation[i][j].stamp++;
        }
    }
}
void cache_update(unsigned int address)
{
    int s_index = (address>>b) & (-1U >>(64 - s));
    int tag = address>>(b+s);
    int MAX_STAMP = 0;
    int MAX_LINE =0;int total = 0;
    for(int i =0;i<E;i++)
    {
        if(CacheSimulation[s_index][i].valid==1)
        {
            total++;//count the valid lines
            if(CacheSimulation[s_index][i].tag==tag )
            {
                //match
                hit_count++;
                CacheSimulation[s_index][i].stamp=0;//reset the stamp
                return ;
            }
            if(CacheSimulation[s_index][i].stamp > MAX_STAMP)
            {
                //find the oldest line
                MAX_STAMP = CacheSimulation[s_index][i].stamp;
                MAX_LINE = i;
            }
        }
    }
    //miss
    //if the set not full then choose the empty line place the line
    miss_count++;
    if(total < E)
    {
        CacheSimulation[s_index][total].stamp = 0;
        CacheSimulation[s_index][total].tag = tag;
        CacheSimulation[s_index][total].valid = 1;
        return ;
    }
    //if the set is full,then replace the oldest one
    else if(total==E)
    {
        eviction++;
        CacheSimulation[s_index][MAX_LINE].stamp = 0;
        CacheSimulation[s_index][MAX_LINE].tag = tag;
        return ;
    }
    return ;
}
void get_trace(char* f)
{
    FILE *fp = fopen(f,"r");
    if (fp == NULL)
    {
        printf("File Open Error!\n");
        return ;
    }
    char operation;//L,S,M
    unsigned int address;
    int size;
    while(fscanf(fp," %c %xu,%d\n", &operation, &address, &size) > 0)
    {
        switch(operation)
        {
            case 'L':
                cache_update(address);
                break;
            case 'M':
                cache_update(address);
            case 'S':
                cache_update(address);
                break;
        }
        time_update();
    }
    fclose(fp);
    for(int i =0;i<S;i++)
      free(CacheSimulation[i]);
    free(CacheSimulation);
    return ;
}

int main(int argc,char** argv)
{
    while(-1!=(opt = (getopt(argc,argv,"hvb:E:s:t:"))))
    {
        switch (opt)
        {
        case 'h':
            help_mode = 1;
            break;
        case 'v':
            verbose_mode = 1;
            break;
        case 'b':
            b = atoi(optarg);
            break;
        case 'E':
            E = atoi(optarg);
            break;
        case 's':
            s = atoi(optarg);
            break;
        case 't':
            strcpy(filename,optarg);
            break;
        default:
            printf("Wrong argument!\n");
            break;
        }
    }
    if(help_mode==1)
    {
        system("cat help_info");
        exit(0);
    }
    S = 1 << s;
    CacheSimulation = cache_init(S,E,b);
    get_trace(filename);
    printSummary(hit_count, miss_count, eviction);
    return 0;
}
```

使用make clean 和make指令编译，运行test-csim程序来进行检测，最终结果显示全部符合，获得满分27分。

```
                        Your simulator     Reference simulator
Points (s,E,b)    Hits  Misses  Evicts    Hits  Misses  Evicts
     3 (1,1,1)       9       8       6       9       8       6  traces/yi2.trace
     3 (4,2,4)       4       5       2       4       5       2  traces/yi.trace
     3 (2,1,4)       2       3       1       2       3       1  traces/dave.trace
     3 (2,1,3)     167      71      67     167      71      67  traces/trans.trace
     3 (2,2,3)     201      37      29     201      37      29  traces/trans.trace
     3 (2,4,3)     212      26      10     212      26      10  traces/trans.trace
     3 (5,1,5)     231       7       0     231       7       0  traces/trans.trace
     6 (5,1,5)  265189   21775   21743  265189   21775   21743  traces/long.trace
    27
TEST_CSIM_RESULTS=27
```

## Part B

Part B的内容是完成对矩阵转置函数的修改，使其在不同的cache参数条件下的cache性能达到一个较好的水平。

### 实验概述

实验指导中规定了该部分的cache参数固定为（s，E，b）= （5，1，5），即一个直接映射的32路高速缓存，每一行的大小为32个字节。转置的矩阵大小共有三个：32×32、64×64、61×67.

我们可以根据不同的矩阵大小分别设计不同的内部逻辑，并且遵循一些规则：不能使用超过12个局部变量（包括循环的初始条件）。

PS：（在实验过程中于网络上他人的试验记录对比过后，发现本虚拟机实验的miss次数似乎会无条件多1，并未找到问题所在）。

### 32×32

首先对文件中原有的转置函数执行测试，查看其性能表现：

```
Function 1 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 1 (Simple row-wise scan transpose): hits:869, misses:1184, evictions:1152
```

可以看到有1184次miss，超过了hit的次数，说明性能表现远不够好。

我们对cache和矩阵进行分析：

首先cache的参数确定，（s，E，b）=（5，1，5），共有32组直接映射高速缓存，每组（行）大小为32个字节，则总共大小为32×32 = 1024B=1KB，而一个32×32大小的int类型矩阵，大小总共为4096字节，因此整个cache最多只能同时存储矩阵的1/4.

而我们具体的对矩阵进行分析：假设矩阵A的起始地址为0，矩阵B与矩阵A连续排列，则如果按照行优先的顺序依次的读取这些数，则每行只能承载32÷4 = 8个整数，因此a【0】【0】至a【0】【7】被放置在第0行，a【0】【8】至a【0】【15】被放置在第1行，依次类推。当读取至a【3】【31】时，也就是总共读取了256个整数时，cache被装满，从a【4】【0】开始的8个整数再次读取会取代第0行中的内容，以此类推。

朴素的转置函数如下：

```c
void trans(int M, int N, int A[N][M], int B[M][N])
{
    int i, j, tmp;

    for (i = 0; i < N; i++) {
        for (j = 0; j < M; j++) {
            tmp = A[i][j];
            B[j][i] = tmp;
        }
    }    
}
```

可以看到，i和j各自从0增大到M或N，在访问A【i】【j】时很容易出现miss。ppt中给出了一种实现的思路，被称为分块blocking

我将其总体思路概括为：将大的矩阵分为若干个小的分块，从初始的在整个矩阵的范围内进行元素与元素的置换，转换为在整个矩阵的范围内进行块与块之间的置换，再在块内部进行元素与元素之间的置换。这样做的好处是在对应的块之间，跨越的元素减少，如果两个块对应的元素能够全部存放在缓存中，则能显著提高缓存的命中率。

回到32×32矩阵问题中，我们如何确定分块的大小？一个直观的想法是按照2的幂次进行划分，将整个矩阵划分为若干个长和宽都为2的幂次的矩阵，并且划分完后两个矩阵块都能同时存在于缓存中。因此当我们选择16个整数来进行划分时，每一个块的大小为16×16×4 = 1024，且块内部产生了conflict miss，因此不推荐。而当选择8个整数作为划分时，8个整数恰好填充cache的一行，且a【0】【0】至a【0】【7】和a【1】【0】至a【1】【7】两路不会映射至相同的组，块内部不会产生conflict miss。我们不妨设置分块为8×8大小。

确定了分块大小后，我们设计普通的转置函数如下（对应的块中进行对应的元素操作）：

```c
if(M==32)
{
    for(int i =0;i<4;i++)
    {
		for(int j = 0;j<4;j++)
        {
            for(int row = i*8;row < i*8+8;row++)
            {
				for(int col = j*8;col<j*8+8;col++)
                {
					B[col][row] = A[row][col];
                }
            }
        }
    }
}
```

这是一个简单的分块方式，将32×32的矩阵以8×8的块作为单位进行划分，将初始矩阵划分为一个4×4的矩阵，对于这个4×4的矩阵，在转置对应关系中其各个矩阵在cache中不会发生conflict miss，我们查看这样的作法cache性能：

```
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:1709, misses:344, evictions:312
```

miss数减少至344，说明我们的分块是有成效的。

但是本实验需要miss次数在300次以下才可以达到满分，因此需要在此基础上进一步优化。

实验指导中指出，要特别注意矩阵中的对角元素。可以推导出来，在对角方块中的元素，各行之间会映射至不同的行，但是A和B矩阵中位置相同的元素会映射至cache中相同的位置，产生conflict miss。我们可以对第一个8×8的分块元素进行分析：我们依次对a【0】【0】至a【7】【7】进行读操作，然后对b【0】【0】至b【7】【7】进行写操作，假设初始cache为空或全为其他无关数据：

1. 读a【0】【0】miss，将a【0】【0】至a【0】【7】写入cache中；写b【0】【0】miss，将b【0】【0】至b【0】【7】写入cache中，替换掉了需要被读取的a【0】【0】至a【0】【7】
2. 读a【0】【1】miss，将a【0】【0】至a【0】【7】写入cache中；写b【1】【0】miss，将b【1】【0】至b【1】【7】写入cache中，不会替换。
3. 以此类推，a【0】【7】读取完后都不会产生conflict miss，只会产生cold miss
4. 当进入下一行时，读取a【1】【0】miss，将a【1】【0】至a【1】【7】写入cache中，替换掉了b【1】【0】至b【1】【7】。
5. 写b【0】【1】时，miss，再去读
6. 读a【1】【1】时，命中，写时又出现miss，将该行替换掉，然后写又要写入该行，再次miss。
7. 以此类推，出现多次miss

综上所述可以分析：由于非对角线上的两个互换块的各个行在映射时并不会产生两个行的元素各自进行读写操作时映射至cache中同一行的情况，因此其他情况不会出现多余的miss而对角线块可以出现。而产生多余miss的原因是读取是依次读取的，而依次读取过程中可能会出现在该行读A又在该行写B的冲突操作。想要改变这种情况，可以将一行元素全部读出来，放在局部变量（寄存器）中，这样在每个8×8的块的第一行读会出现1次cold miss，全部读取后写对应的8个位置会出现8次cold miss（其中有一个是conflict miss，我姑且将其认为是cold miss）。这样所有需要写的数据都存放在了cache中，而接下来的每一轮转置操作只需要一次miss将要读的行写入，再一次miss将要写的行换回即可。

预计产生的miss数：对于对角线上的元素块，读每一行会产生1次miss，写一列会产生8个miss，然后的7行每行1个读miss一列1个写miss，共计23次miss；而对于非对角线上的元素块，读会产生8个miss，写会产生8个miss，不存在互相覆盖的情况，共计16次miss，因此共计的miss次数约为23×4+16×12 = 284次miss。

改进后的代码如下：

```c
if(M==32)
    {
        // divide the matrix to 4*4 ,per block is 8*8 words
        for(int i =0;i < 4;i++)
        {
            for(int j = 0;j<4;j++)
            {
                for(int line = 0;line<8;line++)
                {
                    int base = i*8+line;
                    int val1 = A[base][j*8+0];
                    int val2 = A[base][j*8+1];
                    int val3 = A[base][j*8+2];
                    int val4 = A[base][j*8+3];
                    int val5 = A[base][j*8+4];
                    int val6 = A[base][j*8+5];
                    int val7 = A[base][j*8+6];
                    int val8 = A[base][j*8+7];
                    B[j*8+0][base] = val1;
                    B[j*8+1][base] = val2;
                    B[j*8+2][base] = val3;
                    B[j*8+3][base] = val4;
                    B[j*8+4][base] = val5;
                    B[j*8+5][base] = val6;
                    B[j*8+6][base] = val7;
                    B[j*8+7][base] = val8;
                }
            }
        }   
    }
```

实验检测的数据如下：

```
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:1765, misses:288, evictions:256
```

成功降低到了300以下，且与我们预计的miss次数十分接近。

### 32×32 feedback

在实验过程中尝试了将矩阵按照2×2、4×4、16×16的大小进行分块，结果都不甚理想：

```
// 2*2 block
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:1325, misses:728, evictions:696

// 4*4 block
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:1565, misses:488, evictions:456

// 16*16 block
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:869, misses:1184, evictions:1152
```

可以看到性能差异较大。逐个来分析为什么不同的分块策略产生不同性能的原因：

1. 对于2×2和4×4的分块，由于块的边长小于cache的行大小，导致读2个元素或者4个元素需要将8个元素存入cache。同时其按照分块的顺序进行，也就是每一次会读取超过块行大小的元素却只能填充一部分，写操作会引发很多次conflict miss
2. 16×16的分块，分块太大了，在内部进行元素置换时就已经产生了conflict miss了，与直接映射方法miss次数完全相同。因此可以猜测矩阵分块大小是有一个上限的，超出这个上限时性能表现与不分块一致。

### 64×64

当矩阵大小为64×64时，分析方式有一些区别：cache的大小没有变化，矩阵的元素映射方式没有变化，但是不同位置之间的元素是否仍然能够映射至相同或者不同的行这一事实发生了变化。

矩阵的一行共有64×4 = 256字节，因此整个cache只能顺序存储矩阵的4行，只有整个矩阵的1/16。换言之，每相隔4行的块会映射至cache中相同的行，A矩阵和B矩阵的相同位置仍然映射至相同的行。因此我们不能再使用8×8的分块方式，在读阶段就会产生conflict miss。

该任务的满分要求为将miss次数缩减至1300次以下。

简单的将代码修改为4×4分块，查看性能变化：

```
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:6305, misses:1892, evictions:1860

Function 1 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 1 (Simple row-wise scan transpose): hits:3473, misses:4724, evictions:4692
```

初始情况下的miss次数为4724，简单的进行分块后减少为1892次。（8×8矩阵的性能提升为0）。

进一步使用上一任务的提取局部变量的方式优化：

```
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:6497, misses:1700, evictions:1668
```

仅仅从1892优化至了1700而已。

至此我们考虑：每次读一行8个字，按列只能写其中四个字，如果不读另外四个字会造成浪费，而直接将另外四个字写入对应位置会造成大量miss。指导书中提示我们可以将B中元素随意修改，我们可以想到将读出来的元素在B中其他位置暂存，再使用某种特定方法调换位置。经过多次尝试，得到了以下方法：

1. 将大的矩阵按照8×8的方式分块，对大的块之间再划分为四个4×4的小块，分别标记位左上、右上、左下、右下四部分。

2. 在两个大块之间，先将A的左上右上四行元素全部提取出来，将左上的元素转置后放置在B中块的左上部分，然后**将右上的元素转置后放入B中右上的部分（正确位置应当为左下）**。这样在读和写的过程中只会出现cold miss而不会产生conflict miss

3. 对于A中左下部分，**按照列顺序**逐列的提取四个元素，放入局部变量中，然后将B中右上部分**按照行顺序**提取四个元素，放入局部变量中，然后将前面四个变量对应的放入B中右上该行中，再将后四个变量对应放入左下角的对应行中。

   这样操作的目的是：读取A元素的过程中16次读取只会产生4次cold miss，然而A中元素和B中元素不会产生任何的冲突。而对于B的读和写，每次都是针对行来进行的，先对B的右上第一行进行读，产生一次miss进行4次读操作，再将局部变量中的值放入，4次写操作都不会产生miss；B的右上读行和左下写行映射至相同的cache行，所以4次写操作会产生1次miss。这样一来将miss数尽可能的降低。

4. 对于AB的右下部分，只需要对应的置换即可，再前面的读中这两行的内容全部放置在cache中，因此不会出现miss。

综上构建的代码如下：

```c
else if(M==64)
    {
        for(int i =0;i<8;i++)
        {
            for(int j = 0;j<8;j++)
            {
                int line,val1,val2,val3,val4,val5,val6,val7,val8;
                for(line = 0;line < 4; line++)
                {
                    val1 = A[i*8 + line][j*8+0];
                    val2 = A[i*8 + line][j*8+1];
                    val3 = A[i*8 + line][j*8+2];
                    val4 = A[i*8 + line][j*8+3];
                    val5 = A[i*8 + line][j*8+4];
                    val6 = A[i*8 + line][j*8+5];
                    val7 = A[i*8 + line][j*8+6];
                    val8 = A[i*8 + line][j*8+7];

                    B[j*8+0][i*8 + line] = val1;
                    B[j*8+1][i*8 + line] = val2;
                    B[j*8+2][i*8 + line] = val3;
                    B[j*8+3][i*8 + line] = val4;

                    B[j*8+0][i*8 + line + 4] = val5;
                    B[j*8+1][i*8 + line + 4] = val6;
                    B[j*8+2][i*8 + line + 4] = val7;
                    B[j*8+3][i*8 + line + 4] = val8;
                }
                //read by col instead of row in mA.
                //first take the left bottom
                for(line = 0;line<4;line++)
                {
                    val1 = A[i*8+4][j*8+line];
                    val2 = A[i*8+5][j*8+line];
                    val3 = A[i*8+6][j*8+line];
                    val4 = A[i*8+7][j*8+line];

                    val5 = B[j*8+line][i*8+4];
                    val6 = B[j*8+line][i*8+5];
                    val7 = B[j*8+line][i*8+6];
                    val8 = B[j*8+line][i*8+7];

                    B[j*8+line][i*8+4] = val1;
                    B[j*8+line][i*8+5] = val2;
                    B[j*8+line][i*8+6] = val3;
                    B[j*8+line][i*8+7] = val4;

                    B[j*8+line+4][i*8+0] = val5;
                    B[j*8+line+4][i*8+1] = val6;
                    B[j*8+line+4][i*8+2] = val7;
                    B[j*8+line+4][i*8+3] = val8;
                }
                //then take the right bottom
                for(line = 4;line<8;line++)
                {
                    val1 = A[i*8 + line][j*8+4];
                    val2 = A[i*8 + line][j*8+5];
                    val3 = A[i*8 + line][j*8+6];
                    val4 = A[i*8 + line][j*8+7];

                    B[j*8+4][i*8 + line] = val1;
                    B[j*8+5][i*8 + line] = val2;
                    B[j*8+6][i*8 + line] = val3;
                    B[j*8+7][i*8 + line] = val4;
                }
            }
        }
```

cache性能如下：

```
Function 0 (2 total)
Step 1: Validating and generating memory traces
Step 2: Evaluating performance (s=5, E=1, b=5)
func 0 (Transpose submission): hits:9065, misses:1180, evictions:1148
```

达到了满分的标准。

### 61×67

该矩阵并不是一个对称的矩阵，因此直接使用16* 16的分块，结果也是成功低于2000次。
