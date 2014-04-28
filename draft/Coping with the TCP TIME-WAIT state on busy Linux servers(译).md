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

[RFC1337](http://tools.ietf.org/html/rfc1337)分析了如果`TIME-WAIT`状态的时间太短会导致什么问题.下面是一个示例，如果我们没有将`TIME-WAIT`状态的时间缩短，就可以避免此类问题的发生:

![alter TCP状态迁移图](../postimg/duplicate-segment.png)

因为`TIME-WAIT`状态的时间被缩短导致一个延时的TCP分组被一个不相关的连接接收.

2)确保被动关闭方正确的关闭连接.如果最后的ACK确认丢失,被动关闭方的连接将会停留在`LAST-ACK`状态.这个时候主动关闭方请求建立一个到被动关闭方的连接且这个连接重用了之前连接的四元组(源地址:源端口,目地地址:目地端口),如果没有`TIME-WAIT`状态,被动关闭方会认为之前的连接依旧有效,但被动关闭方收到新连接过来的SYN(序列号匹配),它将响应一个RST这将导致新建连接的失败:	
![alter TCP状态迁移图](../postimg/last-ack.png)

如果被动关闭方因为最后的ACK丢失而保持在`LAST-ACK`状态,使用这个老连接的四元组来建立新连接将会失败.

[RFC793](http://tools.ietf.org/html/rfc793)要求`TIME-WAIT`的持续时间必须是两倍的MSL.
在Linux上，这个时间是不能被改变的,它定义在`include/net/tcp.h`中，时间是1分钟:

	#define TCP_TIMEWAIT_LEN (60*HZ) /* how long to wait to destroy TIME-WAIT
                                  * state, about 60 seconds     */

曾经有[提议](http://comments.gmane.org/gmane.linux.network/244411)将这个值调整为可被改变的，但这个提议被否决了.

####问题

现在让我们看一下为什么`TIME-WAIT`状态在一个处理大量连接的服务器上是令人讨厌的.问题主要有三方面:
1)`TIME-WAIT`状态的`socket`在连接管理表中占用了一个位置，导致相同类型的新连接无法建立.

2)`TIME-WAIT`状态的`socket`将占用一定的内存.

3)`TIME-WAIT`状态的`socket`占用了额外的CPU.

The result of `ss -tan state time-wait | wc -l` is not a problem per se!

####占用连接管理表的位置
一个处于`TIME-WAIT`状态的连接将会在连接管理表中存放一分钟,这意味在这一分钟之内，我们无法建立一个有着同样4元组的新连接.

对一个web服务器而言，目地地址和目地端口通常是固定的.如果你的服务器部署在一个L7负载均衡器的后面，那么源地址也是固定的.在Linux上,客户端连接可以使用的端口范围大概只有30000个(可以通过`net.ipv4.ip_local_port_range调整`).这意味着每分钟只能在web服务器和负载均衡器之间建立30000个连接,平均每秒500个.

如果`TIME-WAIT`在客户端(负载均衡器),这个问题相对容易发现,`connect()`调用将返回错误`EADDRNOTAVAIL`应用程序会将这个错误记录到日志中.如果在服务器端这个问题就复杂多了,没有任何的日志会通知你问题的原因.你只能通过列出当前所有的4元组来发现这个问题:

	$ ss -tan 'sport = :80' | awk '{print $(NF)" "$(NF-1)}' | \
	>     sed 's/:[^ ]*//g' | sort | uniq -c
	    696 10.24.2.30 10.33.1.64
	   1881 10.24.2.30 10.33.1.65
	   5314 10.24.2.30 10.33.1.66
	   5293 10.24.2.30 10.33.1.67
	   3387 10.24.2.30 10.33.1.68
	   2663 10.24.2.30 10.33.1.69
	   1129 10.24.2.30 10.33.1.70
	  10536 10.24.2.30 10.33.1.73

解决方案是允许更多的4元组.这可以通过下面几个方法实现(实现难度递增):

1)调整`net.ipv4.ip_local_port_range`扩大客户端的端口范围.

2)让web服务器监听更多的端口.

3)在负载均衡器上配置更多的客户端IP,并且以轮询的方式使用这些IP去与web服务器建立连接.

4)让web服务器监听更多的IP地址.

当然还有最后一个方案，就是调整`net.ipv4.tcp_tw_reuse`和`net.ipv4.tcp_tw_recycle`,但是，先别忙着就这么做了，后面的内容会分析这两个设置.


####内存

####CPU
