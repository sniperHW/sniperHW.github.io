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
>>*		连接管理表
>>*		内存
>>*		CPU

*	其它解决方案
>*		套接口的lingering选项
>*		net.ipv4.tcp_tw_reuse
>*		net.ipv4.tcp_tw_recycle

*	总结


##TIME-WAIT状态

进入正文，我们首先来看一下什么是`TIME-WAIT`状态，它存在的主要目的是什么,请看下面的TCP状态迁移图(2):

![alter 图2](../postimg/tcp-state-diagram.png)

从上图可以看到,一个处于`ESTABLISHED`状态的`socket`在主动调用`close`之后要想迁移到`CLOSED`状态(为什么回到`CLOSED`是重要的？从图中可以看到,`CLOSED`是所有新连接的起点，也就是说如果一个`socket`没有回到`CLOSED`状态，我们就无法再重新使用它).那么它必须经过`TIME-WAIT`状态.

你可以通过`ss -tan`查看当前所有`socket`的状态:

	$ ss -tan | head -5
	LISTEN     0  511             *:80              *:*     
	SYN-RECV   0  0     192.0.2.145:80    203.0.113.5:35449
	SYN-RECV   0  0     192.0.2.145:80   203.0.113.27:53599
	ESTAB      0  0     192.0.2.145:80   203.0.113.27:33605
	TIME-WAIT  0  0     192.0.2.145:80   203.0.113.47:50685

###目的

既然`TIME-WAIT`是一个必经路径，那么我们来看下它到底为什么有存在的价值.

`TIME-WAIT`状态存在的目的有两个:

1)假设连接C被服务器主动关闭,之后服务器与客户端之间又建立了一个新的连接CC,并CC的四元组与C一样.这个时候如果在网卡中接收到一个来自老连接C的迷途分节,如果没有`TIME-WAIT`状态,会导致这个迷途分组错误的被CC接收.[RFC1337](http://tools.ietf.org/html/rfc1337)分析了如果`TIME-WAIT`状态的时间被设置得太短会导致什么问题(3).下面是一个示例，如果我们没有将`TIME-WAIT`状态的时间缩短，就可以避免此类问题的发生:

![alter 图3](../postimg/duplicate-segment.png)

因为`TIME-WAIT`状态的时间被缩短导致一个延时的TCP分节被一个不相关的连接接收.

2)确保被动关闭方能正确的终止一个连接.连接的关闭会导致连接之间传送4个分节(参考Unix网络编程),假设最后的`ACK`分节丢失,那么被动关闭方将会一直停留在`LAST-ACK`状态(4).这里假设连接是C,如果没有`TIME-WAIT`状态,当服务器向客户端尝试使用C的4元组建立新的连接CC时,客户端会认为连接C还是有效的.当客户端收到`SYN`(序列号正好匹配，关于分节序列号请参考Unix网络编程),会收到一个分预期的`SYN`分节而响应一个`RST`分节.新建连接的请求会失败并返回错误:

![alter 图4](../postimg/last-ack.png)

如果被动关闭方因为最后的ACK丢失而保持在`LAST-ACK`状态,使用这个老连接的四元组来建立新连接将会失败.

[RFC793](http://tools.ietf.org/html/rfc793)要求`TIME-WAIT`的持续时间必须是两倍的MSL.
在Linux上，这个时间是不能被改变的,它定义在`include/net/tcp.h`中，时间是1分钟:

	#define TCP_TIMEWAIT_LEN (60*HZ) /* how long to wait to destroy TIME-WAIT
                                  * state, about 60 seconds     */

曾经有[提议](http://comments.gmane.org/gmane.linux.network/244411)将这个值调整为可被改变的，但这个提议被否决了.

(关于`TIME-WAIT`还可以进一步参考Unix网络编程2.7)

###问题

现在让我们看一下为什么`TIME-WAIT`状态在一个处理大量连接的服务器上是令人烦恼的.问题主要有三方面:

+ `TIME-WAIT`状态的`socket`在连接管理表中占用了一个项，导致相同类型(相同4元组)的新连接无法建立.

+ `TIME-WAIT`状态的`socket`占用额外的内存.

+ `TIME-WAIT`状态的`socket`占用了额外的CPU.

The result of `ss -tan state time-wait | wc -l` is not a problem per se!

####连接管理表

一个处于`TIME-WAIT`状态的连接将会在连接管理表中存放一分钟,这意味在这一分钟之内，我们无法建立一个有相同同4元组的新连接.

对一个web服务器而言它的监听地址和端口通常是固定的,也就是在一个连接4元组中,目地ip:目地端口通常是固定的.
如果你的web服务器被部署在一个L7负载均衡器的后面,那么源地址也将被固定(现在负载均衡器是客户端连接web服务器,而真正的客户端连接到负载均衡器).在Linux上,客户端连接可以使用的端口范围大概只有30000个(可以通过`net.ipv4.ip_local_port_range调整`).这意味着每分钟只能在web服务器和负载均衡器之间建立30000个连接,平均每秒500个.

如果`TIME-WAIT`在客户端(负载均衡器),这个问题相对容易发现,`connect()`调用将返回错误`EADDRNOTAVAIL`应用程序会将这个错误记录到日志中.如果在服务器端这个问题就复杂多了,没有任何的日志会提示你问题的原因.你只能通过列出当前所有的4元组来发现这个问题:

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

解决方案是允许更多的4元组(5).这可以通过下面几个方法实现(实现难度递增):

+ 调整`net.ipv4.ip_local_port_range`扩大客户端的端口范围.

+ 让web服务器监听更多的端口.

+ 在负载均衡器上配置更多的客户端IP,并且以轮询的方式使用这些IP去与web服务器建立连接.

+ 让web服务器监听更多的IP地址(6).

当然还有最后一个方案，就是调整`net.ipv4.tcp_tw_reuse`和`net.ipv4.tcp_tw_recycle`,但是，先别忙着就这么做了，后面的内容会分析这两个设置.

####内存

`TIME-WAIT`状态的连接将会占用服务器的内存.例如,如果你每秒钟要处理10,000个新连接，那么将会有600,000个`socket`处于`TIME-WAIT`状态.这会占用多大的内存?

首先在应用程序看来`TIME-WAIT`的`socket`并没有消耗内存，因为那个`socket`已经关闭了.而对于内核来说,`TIME-WAIT`的`socket`被存放在3个不同的容器中(为了3种不同的目的):

1.连接哈希表,用于快速定位一个连接,例如当收到一个分组时定位这个分组属于哪个连接.这个哈希表的每个bucket中存放了两个链表，一个用于存放`TIME-WAIT`状态的连接一个用于存放所有其它状态的连接.哈希表的大小依赖于系统内存的大小，我们可以通过以下命令查看:

	$ dmesg | grep "TCP established hash table"
	[    0.169348] TCP established hash table entries: 65536 (order: 8, 1048576 bytes)

我们可以通过内核命令行加`thash_entries`参数来调整entries的数量.

`TIME-WAIT`列表中的每个元素是一个`struct tcp_timewait_sock`结构体，而其它状态列表中的元素是`struct tcp_sock`结构(7):


	struct tcp_timewait_sock {
	    struct inet_timewait_sock tw_sk;
	    u32    tw_rcv_nxt;
	    u32    tw_snd_nxt;
	    u32    tw_rcv_wnd;
	    u32    tw_ts_offset;
	    u32    tw_ts_recent;
	    long   tw_ts_recent_stamp;
	};
	
	struct inet_timewait_sock {
	    struct sock_common  __tw_common;
	
	    int                     tw_timeout;
	    volatile unsigned char  tw_substate;
	    unsigned char           tw_rcv_wscale;
	    __be16 tw_sport;
	    unsigned int tw_ipv6only     : 1,
	                 tw_transparent  : 1,
	                 tw_pad          : 6,
	                 tw_tos          : 8,
	                 tw_ipv6_offset  : 16;
	    unsigned long            tw_ttd;
	    struct inet_bind_bucket *tw_tb;
	    struct hlist_node        tw_death_node;
	};

2.一组连接链表，每个链表中的连接在相同的时间`TIME-WAIT`到期.这组链表按到期的剩余时间从小到大排序.这个链表中的元素不占用额外的内存，因为它使用的是`struct inet_timewait_sock`中的`struct hlist_node tw_death_node`成员.

3.已绑定端口哈希表，保存本地已绑定端口和它的相关参数.它的作用是检测是否可以安全的监听一个给定的端口，或者查找一个可用的端口用于动态绑定.这个哈希表的大小与连接哈希表保持一致:

	$ dmesg | grep "TCP bind hash table"
	[    0.169962] TCP bind hash table entries: 65536 (order: 8, 1048576 bytes)

哈希表中的元素是一个`struct inet_bind_socket`结构。每个本地绑定的端口在哈希表中占用一项.
web服务器的`TIME-WAIT`连接通常被绑定在80端口,而所有绑定在80端口的`TIME-WAIT`连接共享一个entry.而其它外出连接通常使用随机的绑定端口，所以它们之间不共享entry.

所以，我们可以将注意力集中在`struct tcp_timewait_sock`和`struct inet_bind_socket`占用的内存上.
无论是连进来还是外出的连接,只要处于`TIME-WAIT`状态都有一个对应的`struct tcp_timewait_sock`.而对于每个外出连接都会产生一个专用的`struct inet_bind_socket`,连进来的连接则没有(listen的时候已经产生了).

`struct tcp_timewait_sock`占用168个字节`struct inet_bind_socket`占用48个字节:

	$ sudo apt-get install linux-image-$(uname -r)-dbg
	[...]
	$ gdb /usr/lib/debug/boot/vmlinux-$(uname -r)
	(gdb) print sizeof(struct tcp_timewait_sock)
 	$1 = 168
	(gdb) print sizeof(struct tcp_sock)
 	$2 = 1776
	(gdb) print sizeof(struct inet_bind_bucket)
 	$3 = 48

所以如果我们的服务器上有40,000个连进来的连接处于`TIME-WAIT`状态,只需要额外消耗最多10MB的内存.而如果是40,000个外出的连接则只需要额外消耗最多2.5MB内存.我们来看下`slabtop`的输出。下面的输出来自在一个有50,000个连接处于`TIME-WAIT`状态,其中45,000是外出连接的服务器：

	$ sudo slabtop -o | grep -E '(^  OBJS|tw_sock_TCP|tcp_bind_bucket)'
	  OBJS ACTIVE  USE OBJ SIZE  SLABS OBJ/SLAB CACHE SIZE NAME                   
	 50955  49725  97%    0.25K   3397       15     13588K tw_sock_TCP            
	 44840  36556  81%    0.06K    760       59      3040K tcp_bind_bucket

从以上分析来看，`TIME-WAIT`状态导致的内存开销几乎可以忽略不计.

####CPU

查找本地空闲端口可能会增加一点点额外的开销.这个查找工作由[`inet_csk_get_port()`函数](http://lxr.free-electrons.com/source/net/ipv4/inet_connection_sock.c?v=3.12#L104)完成,它的内部实现中使用了一个锁,然后遍历所有的本地已绑定端口，直到找到一个空闲的端口.除非你的服务器上主要是外出连接(例如到memcached服务器的连接),否则`TIME-WAIT`状态不会有太大的影响:这些连接通常共享同样的配置(例如都是80端口),所以`inet_csk_get_port()`可以很快的找到一个空闲的端口号.

###其它解决方案

在看完以上内容之后，如果你依旧为`TIME-WAIT`感到苦恼，可以看下下面3个额外的解决方案:

* 禁止lingering选项

* `net.ipv4.tcp_tw_reuse`

* `net.ipv4.tcp_tw_recycle`

####lingering选项

lingering选项将改变close的行为，我们首先看下正常情况下close的行为.

当`close()`被调用,还存在于套接口内核发送缓冲区中的数据会在后台发送，这个连接最终会迁移到`TIME-WAIT`状态.应用程序可以假设这些数据最终会被安全的发送出去然后继续干自己的活去了.

但是应用程序也可以通过lingering选项禁止这个默认的行为:

1) 丢弃内核缓冲中的数据,不走正常终止连接的4个分节而是直接往对端发送一个RST(对端连接会检测到一个错误)然后立即销毁对应的`socket`，这种方式下连接将不会进入`TIME-WAIT`状态.

2) 如果连接的发送缓冲中还有数据,阻塞在`close()`上直到数据发送完成并且被对端确认或者linger超时.如果我们将套接口设置为非阻塞的,则立即从`close()`返回,前面描述的过程将在后台异步执行,如果在设定的超时到期之前数据成功发送将执行正常的关闭连接的4个分组并且将连接迁移到`TIME-WAIT`状态.否则数据将被丢弃并向对端发送一个RST来终止连接.

无论哪种情况，禁用lingering选项都不是一个万全的解决方案。对于应用协议能正确处理这些问题的应用程序例如HAProxy或Nginx可以禁用lingering选项。但是除非有充分的理由，否则最好不要禁止lingering选项.

####`net.ipv4.tcp_tw_reuse`

`TIME-WAIT`状态防止一个延时分节被不相关的连接接收.但是，在某些情况下可以假设来自新连接的分节不会被误解成是来自老连接的.

[RFC 1323](http://tools.ietf.org/html/rfc1323)介绍了一组TCP扩展用于提高高带宽线路的性能.除此之外，还定义了一个携带了两个四字节时间戳的TCP选项.第一个时间戳是发送这个TCP选项时时间戳时钟的当前值.第二个是从远程主机接收到的最新时间戳.

开启`net.ipv4.tcp_tw_reuse`选项,Linux可以将一个处于`TIME-WAIT`状态的连接重用于新的外出连接.只要新的时间戳严格大于最近一次从老连接上接收到的时间戳，也就是说:如果一个外出连接处于`TIME-WAIT`状态,那么在1秒钟之后这个连接就可以被重用(时间戳的单位是秒).

开启`net.ipv4.tcp_tw_reuse`选项,Linux可以将一个处于`TIME-WAIT`状态的连接作为新的外出连接重用.只要建立新连接的时间严格大于最近一次从老连接上接收到的时间戳，也就是说:一个外出的连接处于`TIME-WAIT`状态,那么在1秒钟之后这个连接就可以被重用(时间戳的单位是秒).


这么做安全吗?答案是肯定的.`TIME-WAIT`状态的一个目的就是为了防止一个重复的分节被不相关的连接接收.而在有了额外的时间戳之后,重复的分节因为携带了过期的时间戳而被丢弃.

第二个目的是为了确保被动关闭方可以在丢失最后一个ACK的情况下正确的结束一个连接.被动关闭方会重发FIN分节直到:

* 主动放弃(结束连接)

* 接收到它正在等待的ACK(结束连接)

* 接收到RST(结束连接)

如果重发的FIN分节被主动关闭方及时收到，此时主动关闭方仍然处于`TIME-WAIT`状态，它响应对方一个ACK分组.

一旦主动关闭方重用老的连接向被动关闭方请求建立新的连接.发往被动关闭方的SYN分节将会被忽略(再次感谢时间戳),被动关闭方对这个SYN分组的响应不是RST,而是重发FIN.主动关闭方收到这个FIN分节将响应一个RST(因为新建连接目前处于`SYN-SENT`状态,FIN分节不是它所期待的分节),这就让被动关闭方的连接离开`LAST-ACK`状态正常的终结了那个连接.新建连接的SYN分节将会在1秒钟之后重发,连接最终成功建立，只是会有一点延时：

![alter 图5](../postimg/last-ack-reuse.png)

如果远端因为最后的ACK丢失而停留在`LAST-ACK`状态,这个连接将会在本地端迁移到`SYN-SENT`状态的时候被重置.

需要注意的是，当一个连接被重用,`TWRecycled`计算器的值将会加1.

####`net.ipv4.tcp_tw_recycle`

这个选项的工作机制同样依赖于上面提到的TCP选项，与`net.ipv4.tcp_tw_reuse`不同的是它同时影响外出和连进来的连接.因为服务器通常主动关闭连接(8)，所以此机制为服务器提供了便利.

这个机制同样依赖于上面提到的时间戳选项，不同的是它同时影响外出和连进来的连接.因为服务器通常主动关闭连接(8)，所以此机制为服务器提供了便利.

这个机制会让`TIME-WAIT`状态的过期时间变短:它会在重传超时间隔(通过RTT计算出来)之后就将`TIME-WAIT`状态的连接从`TIME-WAIT`表中移除.
可以通过`ss`命令查看一个存活连接的`RTO`和`RTT`:

	$ ss --info  sport = :2112 dport = :4057
	State      Recv-Q Send-Q    Local Address:Port        Peer Address:Port   
	ESTAB      0      1831936   10.47.0.113:2112          10.65.1.42:4057    
	         cubic wscale:7,7 rto:564 rtt:352.5/4 ato:40 cwnd:386 ssthresh:200 send 4.5Mbps

为了确保`TIME-WAIT`状态所提供的保障,当过期定时器的值被缩小.如果有连接进入`TIME-WAIT`状态,这个最近的时间戳将会记录到一个专门用于记录目的地址相关信息的专用结构中.这样，在`TIME-WAIT`过期之前Linux将会丢弃来自这个连接的，时间戳小于最后记录时间戳的任何分组:

	if (tmp_opt.saw_tstamp &&
	    tcp_death_row.sysctl_tw_recycle &&
	    (dst = inet_csk_route_req(sk, &fl4, req, want_cookie)) != NULL &&
	    fl4.daddr == saddr &&
	    (peer = rt_get_peer((struct rtable *)dst, fl4.daddr)) != NULL) {
	        inet_peer_refcheck(peer);
	        if ((u32)get_seconds() - peer->tcp_ts_stamp < TCP_PAWS_MSL &&
	            (s32)(peer->tcp_ts - req->ts_recent) >
	                                        TCP_PAWS_WINDOW) {
	                NET_INC_STATS_BH(sock_net(sk), LINUX_MIB_PAWSPASSIVEREJECTED);
	                goto drop_and_release;
	        }
	}

如果远端主机实际上是一个NAT设备,为了满足时间戳条件,NAT设备后面的主机在一分钟之内只允许建立一条到服务器的连接，因为它们没有共享时间戳时钟.所以最好还是不要开启这个选项，因为它会导致一些难以察觉和诊断的问题.

`LAST-ACK`状态的处理与`TIME-WAIT`的处理一样.

###总结

终极解决方案应该是扩大端口的数量,这样就不用担心过多的连接进入`TIME-WAIT`状态.

对服务器来说，千万别开启`net.ipv4.tcp_tw_recycle`除非你非常确定你的系统不会工作在一个混杂了NAT设备的环境下.开启`net.ipv4.tcp_tw_reuse`对外来接连没有什么用处.

而对客户端而言,开启`net.ipv4.tcp_tw_reuse`是一个几乎完美的解决方案.而开启`net.ipv4.tcp_tw_recycle`的作用则比开启`net.ipv4.tcp_tw_reuse`要小得多.

下面引用W. Richard Stevens在Unix Network Programming中的一段话:

`TIME-WAIT`状态是我们的朋友(它让重复的分组在网络中过期).与其想办法避免这个状态，我们更应该更深入的去理解它.

注释:

	1.注意,调整`net.netfilter.nf_conntrack_tcp_timeout_time_wait`不会影响TCP协议栈处理
	  `TIME-WAIT`状态的方式.
	
	2.此图版权基于LaTeX Project Public License 1.3.原始文件在本页面中可以找到.
	
	3.第一次在RFC 1337中的解决方案提议在`TIME-WAIT`状态下忽略RST分节.这个行为由net.ipv4.rfc1337
	  控制,在Linux上默认是禁止.因为这不是在RFC中定义完全的解决方案.
	
	4.处于`LAST-ACK`状态下,连接会重传最后的FIN分节,直到收到它期待的ACK分节.所以连接不会在这个状态
	  下持续太长的时间
	
	5.在客户端，一些使用了旧内核的机器上需要为每个外出连接寻找一个(源ip,源端口号)元组.在这种情况下增加
	  服务器的监听端口数量或ip数量不会有任何帮助.Linux 3.2内核已经可以使用相同的(源ip,源端口号)元组
	  来建立到不同目地地的连接.
	
	6.最后一个解决方案稍显愚蠢,因为你只要监听更多的端口就可以达到效果了，并且很多服务器不允许配置多个
	  IP。而倒数第二个方案也可能相当繁琐，这依赖于负载均衡软件，但它比最后一个解决方案少用了一些IP。
	
	7.专门的结构用于处理`TIME-WAIT`源于Linux 2.6.14.而`struct sock_common`有点冗长，在这里我就不帖出来了.
	
	8.服务器主动关闭连接，进入`TIME-WAIT`状态.而客户端则认为对应的四元组已经可以被重用于新连接.

