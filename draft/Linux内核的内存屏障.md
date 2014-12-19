[原文](https://www.kernel.org/doc/Documentation/memory-barriers.txt)

By: David Howells <dhowells@redhat.com>
Paul E. McKenney <paulmck@linux.vnet.ibm.com>

目录:

>1 内存访问抽象模型.
>
>- 外设操作.
>- 保证.

>2 什么是内存屏障?
>
>- Varieties of memory barrier.
>- What may not be assumed about memory barriers?
>- Data dependency barriers.
>- Control dependencies.
>- SMP barrier pairing.
>- Examples of memory barrier sequences.
>- Read memory barriers vs load speculation.
>- Transitivity

>3 显式内核屏障.
>- Compiler barrier.
>- CPU memory barriers.
>- MMIO write barrier.

>4 隐式内核内存屏障.
>- Locking functions.
>- Interrupt disabling functions.
>- Sleep and wake-up functions.
>- Miscellaneous functions.

>5 Inter-CPU locking barrier effects.
>- Locks vs memory accesses.
>- Locks vs I/O accesses.

>6 什么时候需要内存屏障?
>- Interprocessor interaction.
>- Atomic operations.
>- Accessing devices.
>- Interrupts.

>7 Kernel I/O barrier effects.

>8 Assumed minimum execution ordering model.

>9 The effects of the cpu cache.
>- Cache coherency.
>- Cache coherency vs DMA.
>- Cache coherency vs MMIO.

>10 The things CPUs get up to.
>- And then there's the Alpha.

>11 Example uses.
>- Circular buffers.

>12 References.



#1 内存访问抽象模型

 考虑如下的抽象系统模型：

    		            :                :
    		            :                :
    		            :                :
    		+-------+   :   +--------+   :   +-------+
    		|       |   :   |        |   :   |       |
    		|       |   :   |        |   :   |       |
    		| CPU 1 |<----->| Memory |<----->| CPU 2 |
    		|       |   :   |        |   :   |       |
    		|       |   :   |        |   :   |       |
    		+-------+   :   +--------+   :   +-------+
    		    ^       :       ^        :       ^
    		    |       :       |        :       |
    		    |       :       |        :       |
    		    |       :       v        :       |
    		    |       :   +--------+   :       |
    		    |       :   |        |   :       |
    		    |       :   |        |   :       |
    		    +---------->| Device |<----------+
    		            :   |        |   :
    		            :   |        |   :
    		            :   +--------+   :
    		            :                :
    		            
每个在单独CPU上运行的程序都会执行内存访问操作.对一个抽象CPU,内存操作次序是非常宽松的,在能保证程序上下文逻辑关系的前提下,CPU可以以任意次序执行这些操作.同样,对编译器来说,在不影响程序输出结果的前提下,编译器可以以任意次序对指令重新排序.

在上面的图示中,一个CPU执行内存操作所产生的影响,一直要到该操作穿越该CPU与系统中其他部分的界面(见图中的虚线)之后,才能被其他部分所察觉到.

例如考虑如下操作序列:

	CPU 1		CPU 2
	===============	===============
	{ A == 1; B == 2 }
	A = 3;		x = B;
	B = 4;		y = A;       
         	

对于抽象模型中间的内存系统来说,它看到的操作顺序可以被排列成24种不同的组合:

	STORE A=3,	STORE B=4,	y=LOAD A->3,	x=LOAD B->4
	STORE A=3,	STORE B=4,	x=LOAD B->4,	y=LOAD A->3
	STORE A=3,	y=LOAD A->3,	STORE B=4,	x=LOAD B->4
	STORE A=3,	y=LOAD A->3,	x=LOAD B->2,	STORE B=4
	STORE A=3,	x=LOAD B->2,	STORE B=4,	y=LOAD A->3
	STORE A=3,	x=LOAD B->2,	y=LOAD A->3,	STORE B=4
	STORE B=4,	STORE A=3,	y=LOAD A->3,	x=LOAD B->4
	STORE B=4, ...
	...

因此导致了4种可能的输出结果:

	x == 2, y == 1
	x == 2, y == 3
	x == 4, y == 1
	x == 4, y == 3

另外,一个CPU向内存系统提交stores操作产生的效果,不一定能被另一个提交loads操作的CPU察觉到(针对同一个内存地址).

作为这种情况的例子,让我们考虑如下操作序列:

	CPU 1		CPU 2
	===============	===============
	{ A == 1, B == 2, C = 3, P == &A, Q == &C }
	B = 4;		Q = P;
	P = &B		D = *Q;
	           
	           
这里存在一个很明显的数据依赖关系,载入到D中的数据依赖于CPU2执行`Q=P`时,P所指向的内存地址.	当这些操作执行完之后,下面的任何一组结果都是可能的:

	(Q == &A) and (D == 1)
	(Q == &B) and (D == 2)
	(Q == &B) and (D == 4)
	
注意,CPU2决不会将D载入到C中,因为CPU保证首先执行`Q=P`.

##外设操作

有些外设将它的控制接口以一组内存地址的方式展现(例如控制寄存器),但是访问控制寄存器的顺序却是至关紧要的.	例如,假设一个有一组内部寄存器的网卡,这些内部寄存器通过一个地址端口寄存器(A)和一个数据端口寄存器(D)来访问.可以通过执行如下代码访问内部寄存器5:

    *A = 5;
    x = *D;
	
但是上面的操作次序可以被重排成以下的任一序列:

    STORE *A = 5, x = LOAD *D
    x = LOAD *D, STORE *A = 5
	
显然,只有第一个次序是正确的.第2个将会产生错误,因为它在设置就寄存器的编号之前就尝试访问寄存器了.

##保证

以下是CPU可以提供的最低保证:

* 对任意一个CPU,它所发起的有依赖关系的访存操作会被按序发送到内存系统,这意味对于:
    
        ACCESS_ONCE(Q) = P;
        smp_read_barrier_depends();
        D = ACCESS_ONCE(*Q);

    一定会以如下序列执行:
    
        Q = LOAD P, D = LOAD *Q
    
    在多数系统上,`smp_read_barrier_depends()`什么也不做,但他在DEC Alpha上是必须的.ACCESS_ONCE()则用于防止编译器乱序.注意通常你应该使用类似`rcu_dereference()`的调用来替代`smp_read_barrier_depends()`.
    
* 对某个CPU自身而言,重叠的loads和stores是保证次序的,这意味对于:

     	a = ACCESS_ONCE(*X); ACCESS_ONCE(*X) = b;

    一定会以如下序列执行:
    
        a = LOAD *X, STORE *X = b
    
    而对于:
    
        ACCESS_ONCE(*X) = c; d = ACCESS_ONCE(*X);
	
    一定会以如下序列执行:
    
        STORE *X = c, d = LOAD *X
	
	(如果loads和stores的操作目标是同一个内存地址则它们被称为重叠的)
	
还有一些事情是必须被假定或者不能被假定的:

* 对于没有被`ACCESS_ONCE()`保护的内存引用,不能假定编译器编译出来的指令与代码顺序一致.

* 不能假定独立的loads和stores会被以代码顺序被执行,这意味着对于:

        X = *A; Y = *B; *D = Z;
	
	以下任意一组操作序列都是可能:
	
        X = LOAD *A,  Y = LOAD *B,  STORE *D = Z
        X = LOAD *A,  STORE *D = Z, Y = LOAD *B
        Y = LOAD *B,  X = LOAD *A,  STORE *D = Z
        Y = LOAD *B,  STORE *D = Z, X = LOAD *A
        STORE *D = Z, X = LOAD *A,  Y = LOAD *B
        STORE *D = Z, Y = LOAD *B,  X = LOAD *A
	
* 必须假定重叠的内存访问被合并或丢弃,这意味对于:

    	X = *A; Y = *(A + 4);

    以下任意一组操作序列都是可能的: 		

        X = LOAD *A; Y = LOAD *(A + 4);
        Y = LOAD *(A + 4); X = LOAD *A;
        {X, Y} = LOAD {*A, *(A + 4) };

    而对于:
	
        *A = X; *(A + 4) = Y;
	    
    以下任意一组操作序列都是可能出现: 
    
        STORE *A = X; STORE *(A + 4) = Y;
        STORE *(A + 4) = Y; STORE *A = X;
        STORE {*A, *(A + 4) } = {X, Y};
	
	
#2 什么是内存屏障?

内存屏障有4种基本类型:

* 1 写(store)内存屏障.

    写屏障保证,对系统中其余的部件来说,写屏障之前的写操作必定先于屏障之后的写操作发生.

    写屏障仅保证针对STORE操作的部分有序,并不要求对读操作产生任何影响.
 
    可以将CPU看成随着时间的推移向内存系统提交一系列的写操作.在这个序列中,所有写屏障之前的写操作都出现在屏障之后的写操作前面.

    [!]注意写屏障一般总是与读屏障或数据依赖屏障配对使用;请参考章节"SMP屏障配对".


* 2 数据依赖屏障.

     数据依赖屏障是一种弱化版本的读屏障.如果有两个读操作,第二个读操作依赖于第一个读操作的结果(例如:第一个读操作读取的内容是一个内存地址,第二个读操作读取这个内存地址中存放的数据),这种情况下,我们可能需要使用一个数据依赖屏障以确保第二个读操作的目标,也就是由第一个读操作读取到的地址是最新的.

     数据依赖屏障仅保证针对相互依赖的LOAD操作的部分有序,并不要求它对写操作,独立的读操作或重叠读操作产生影响.

     如在(1)中提到的,系统中的其它CPU可以被看作向内存系统提交一系列的写操作,而当前CPU之后会察觉到这些写操作产生的效果.如果当前CPU发出数据依赖屏障,那么可以保证,对于屏障之前的任何一个读操作(假设是A),如果与其它CPU操作序列中的任意一个写操作有联系,则当屏障完成时,则在A之前的所有写操作所产生的效果,都会被屏障之后发射的读操作所察觉.

     请参考“内存屏障序列的示例”章节中用图展示的排序约束.

     [!] 注意第一个读操作需要的确实是数据依赖屏障而不是控制屏障.如果第二个读操作的内存地址依赖于第一个读操作,但只用作条件判断,而不是直接访问那个地址本身,那么这就是一种控制依赖.此时需要的是完全读屏障,甚至更严的屏障.请参考"数据依赖屏障".

     [!] 注意数据依赖屏障通常与写屏障配对使用;请参考章节"SMP屏障配对".

* 3 读(load)内存屏障.
    
    读屏障是一个数据依赖屏障,同时保证,对系统中其余的部件来说,读屏障之前的读操作必定先于屏障之后的读操作发生.
    
    读屏障仅保证针对LOAD操作的部分有序,并不要求对写操作产生任何影响.
    
    读屏障隐含了数据依赖屏障,所以用来替代数据依赖屏障.
    
    [!]注意读屏障一般总是与写屏障配对使用;请参考章节"SMP屏障配对".

* 4 通用内存屏障.

    通用内存屏障保证,对于系统中的其余部件来说,屏障之前的读和写操作必定先与屏障之后的读和写操作发生.
    
    
