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


