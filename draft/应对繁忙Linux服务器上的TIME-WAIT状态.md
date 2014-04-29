在一个繁忙的Linux网络服务器上，将会遇到大量套接口进入`TIME-WAIT`状态,导致新连接无法迅速建立的问题,本文详细分析了`TIME-WAIT`状态的作用并提供了一些处理这个问题的解决方案.

####术语

* TCP连接4元组:一个TCP连接由一个四元组(源ip:源端口，目地ip:目地端口)唯一定义.

* 主动关闭方:主动对一个存活连接调用`close`的一方.

* 被动关闭方:因为对端调用`close`使得连接终止而被动终止连接的一方. 

[原文链接](http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html)

Linux中提供了两个选项以改变`TIME-WAIT`状态的处理，分别是:

* `net.ipv4.tcp_tw_recycle`

* `net.ipv4.tcp_tw_reuse`

Linux内核文档没有清楚的解释`net.ipv4.tcp_tw_recycle`选项的作用.

下面的介绍引用自Linux内核文档:

	允许内核快速回收处于TIME-WAIT状态的socket.默认值是0(关闭),
	在没有技术专家的建议下最好别改变默认值.

而对于它的兄弟选项`net.ipv4.tcp_tw_reuse`,文档描述得稍微清楚一点，但依旧只是三言两语:

	当建立新连接时允许重用处于TIME-WAIT状态的socket,只要在协议的角度上看是安全的.
	默认值是0(关闭),在没有技术专家的建议下最好别改变默认值.(注：新连接使用了跟老连接一样的4元组)

文档的缺乏使得网上出现了很多文章，建议我们开启上述两选项,以减少处于`TIME-WAIT`状态的`socket`数量.但是,正如在`tcp(7) manual page`中阐述的,在面向公网的服务器上开启`net.ipv4.tcp_tw_recycle`选项将会产生一些问题.因为服务器无法区分一台NAT设备后面分别属于
两台机器的连接(NAT设备后的机器都通过NAT设备来连接服务器，所以服务器无法区分这两个连接是否来自于不同的机器).

	因此不建议开启快速回收处于TIME-WAIT状态socket的选项(net.ipv4.tcp_tw_recycle),
	因为在一个混杂了NAT设备的网络环境下，它的开启可能会产生一些问题.


这就是我写这篇文章的目的，让更多的程序员减少犯类似错误的可能性:
![alter 图1](../postimg/duty_calls.png)

注意，尽管这两个选择的名字中带有`ipv4`,而实际上它同样被应用于IPv6套接口.其次，我们关注的只是Linux上的TCP协议栈,这与Netfilter连接的跟踪没有任何关系,后者需要通过其它方式调整(1).


###目录

*	TIME-WAIT状态详解
>*	目的
>*	问题
>>*		Connection table slot
>>*		Memory
>>*		CPU

*	其它解决方案
>*		套接口的lingering选项
>*		net.ipv4.tcp_tw_reuse
>*		net.ipv4.tcp_tw_recycle

*	总结

