[原文链接](http://vincent.bernat.im/en/blog/2014-tcp-time-wait-state-linux.html)

Linux内核文档没有很好的解释`net.ipv4.tcp_tw_recycle`选项的作用.

下面的介绍引用自Linux内核文档:

允许内核快速回收处于`TIME-WAIT`状态的`socket`.默认值是0,
在没有技术专家的建议下最好别改变默认值.


他的兄弟`net.ipv4.tcp_tw_reuse`选项文档描述得稍微清楚一点，但依旧只有三言两语:

当一个新连接到来时允许重用处于`TIME-WAIT`状态的`socket`,只要在协议的角度上看是安全的.默认值是0,在没有技术专家的建议下最好别改变默认值.

文档的缺乏导致出现了很多文章建议我们将这两个值设置为1,以减少处于`TIME-WAIT`状态的`socket`的数量.但是,正如在`tcp(7)`manual page中阐述的,在面向公网的网络服务器上开启`net.ipv4.tcp_tw_recycle`选项将会导致一些问题.因为服务器无法处理隐藏在同一台NAT设备后的不同计算机的连接.

因此`net.ipv4.tcp_tw_recycle`选项不建议开启.

尽管这个选择的名字中带有`ipv4`,实际上它同样被应用于IPv6套接口.

###TIME-WAIT状态

首先回顾一下`TIME-WAIT`,下图展示了`socket`如何在各状态之间迁移.

![alter TCP状态迁移图](../postimg/tcp-state-diagram.png)

从上图可以看到，只有主动调用`close`的一方在回到`CLOSED`状态之前必须要先迁移到`TIME-WAIT`状态.

你可以通过`ss -tan`查看当前所有`socket`的状态:

	$ ss -tan | head -5
	LISTEN     0  511             *:80              *:*     
	SYN-RECV   0  0     192.0.2.145:80    203.0.113.5:35449
	SYN-RECV   0  0     192.0.2.145:80   203.0.113.27:53599
	ESTAB      0  0     192.0.2.145:80   203.0.113.27:33605
	TIME-WAIT  0  0     192.0.2.145:80   203.0.113.47:50685

####目的

`TIME-WAIT`状态存在的目的有两个:

1)防止之前连接的迷途分组被之后建立的与之前的连接有相同四元组(源地址:源端口,目地地址:目地端口)的接连作为合法分组接收.

[RFC1337](http://tools.ietf.org/html/rfc1337)分析了如果`TIME-WAIT`状态的时间太短会导致什么问题.下面是一个示例，它展示了足够长的`TIME-WAIT`状态时间可以避免什么问题:

![alter TCP状态迁移图](../postimg/duplicate-segment.png)


	