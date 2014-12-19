[原文](https://www.kernel.org/doc/Documentation/memory-barriers.txt)

By: David Howells <dhowells@redhat.com>
Paul E. McKenney <paulmck@linux.vnet.ibm.com>

目录:

>1 抽象内存访问模型.
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



# 抽象内存访问模型

先考虑如下的抽象内存访问模型：

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
    		            
每个在单独CPU上运行的程序都会产生一些内存访问操作.对一个抽象CPU而言,内存操作的次序是非常松散的,在能保证程序上下文关系的前提下,CPU可以以任意次序执行这些操作.同样,对编译器来说,在不影响程序输出结果的前提下,编译器可以以任意次序对指令重新排序.

所以对于上图而言,一个CPU对内存操作所产生的效果,在系统中的其余部件看来,就好像这个操作穿越了CPU与其余部件之间的接口(上图中的虚线).

例如考虑如下顺序的事件:

          	CPU 1		                CPU 2
    	===============	===============
    	     { A == 1; B == 2 }(A,B的初始值)
    	         A = 3;		                 x = B;
         	B = 4;		                 y = A;        
         	

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

另外,一个CPU向内存系统提交的stores操作所产生的效果,不一定能被另一个提交loads操作的CPU察觉到(针对同一个内存地址).

作为这种情况的例子,让我们考虑如下顺序事件:

	           CPU 1		             CPU 2
	===============	===============
	{ A == 1, B == 2, C = 3, P == &A, Q == &C }
	           B = 4;		                 Q = P;
	           P = &B		             D = *Q;
	           
	           
这里存在一个很明显的数据依赖关系,载入到D中的数据依赖于CPU2执行`Q=P`时,P所指向的内存地址.	当这些事件都执行完之后,下面的任何一组结果都是可能的:

	(Q == &A) and (D == 1)
	(Q == &B) and (D == 2)
	(Q == &B) and (D == 4)
	
注意,CPU2决不会将D载入到C中,因为CPU保证首先执行`Q=P`.

##外设操作

有些外设将它的控制接口以一组内存地址的方式展现(例如控制寄存器),但是访问控制寄存器的顺序却是至关紧要的.	例如,假设一个有一组内部寄存器的网卡,这些内部寄存器通过一个地址端口寄存器(A)和一个数据端口寄存器(D)来访问.可以通过执行如下代码访问内部寄存器5:

    *A = 5;
    x = *D;
	
但是上面的操作次序可以被重排成以下的任意一个次序:

    STORE *A = 5, x = LOAD *D
    x = LOAD *D, STORE *A = 5
	
显然,只有第一个次序是正确的.第2个将会产生错误,因为它在设置地址之前就尝试访问寄存器了.

##保证

以下是CPU可以提供的最小保证:

* 对任意一个CPU,它所发起的有依赖关系的访存操作会被按序发射到内存系统,这意味对于:
    
        ACCESS_ONCE(Q) = P; smp_read_barrier_depends(); D = ACCESS_ONCE(*Q);

    一定会以如下顺序发射内存操作:
    
        Q = LOAD P, D = LOAD *Q
    
    在多数系统上,`smp_read_barrier_depends()`什么也不做,但他在DEC Alpha上是必须的.ACCESS_ONCE()则用于防止编译器乱序.注意通常你应该使用类似`rcu_dereference()`的调用来替代`smp_read_barrier_depends()`.
    
* 对某个CPU自身而言,对重叠的loads和stores是保证次序的,这意味对于:

        a = ACCESS_ONCE(*X); ACCESS_ONCE(*X) = b;

    一定会以如下顺序发射内存操作:
    
        a = LOAD *X, STORE *X = b
    
    而对于:
    
        ACCESS_ONCE(*X) = c; d = ACCESS_ONCE(*X);
	
    一定会以如下顺序发射内存操作:
    
        STORE *X = c, d = LOAD *X
	
	(如果loads和stores的操作目标是同一个内存地址则它们被称为重叠的)
	
以下是一些可以/不能被保证的事:

* 对于没有被`ACCESS_ONCE()`保护的内存引用,不能保证编译器编译出来的指令与代码顺序一致.

* 不能保证独立的loads和stores会被以代码顺序发射到内存系统,这意味着对于:

        X = *A; Y = *B; *D = Z;
	
	以下任一发射顺序都是可能的:
	
        X = LOAD *A,  Y = LOAD *B,  STORE *D = Z
        X = LOAD *A,  STORE *D = Z, Y = LOAD *B
        Y = LOAD *B,  X = LOAD *A,  STORE *D = Z
        Y = LOAD *B,  STORE *D = Z, X = LOAD *A
        STORE *D = Z, X = LOAD *A,  Y = LOAD *B
        STORE *D = Z, Y = LOAD *B,  X = LOAD *A
	
* 		

	    	                    		    	