

#边界触发模式的网络编程模型


本文并不打算介绍边界触发模式，需要了解的朋友自己到网上搜索.

本文只是打算介绍近期总结的三种边界触发模式的实现方式，后面会实现每一种然后做一个性能比较.

1）模仿windows完成端口的模式.
这是最早的时候想到的一种方法，并且已经用C++实现过.大概结构这样的，
定义了一个IO请求结构，类似于IOCP的OVERLAP结构：

	struct OVERLAP
	{
	    void *buf;
	    int bytetransfer;
	    int errcode;
	};
	
然后是一个对应用不透明的socket结构:

	struct socket_t
	{
	    volatile int readable;
	    volatile int writeable;
	    list     *   pending_read;
	    list     *   pending_write;
	};	
	
向上层提供了两个发送/接受接口

	int WSASend(socket_t*,OVERLAP*);
	int WSARecv(socket_t*,OVERLAP*);
	
如果网络操作无法立即完成(readable/writeable == 0 或 read/write的错误码是EWOULDBLOCK)
则将请求保存在pending_read/pending_write中.

在epoll线程中，如果发现一个套接口被激活,则将其readable/writeable设置为1,并查看pending
list 中是否有未完成的请求，如果有，则弹一个出来执行，然后往完成队列中添加一个完成事件.

下面是WSARecv的伪代码:	

	int WSARecv(s,overlap)
	{
	    if !s.readable then
	        s.pending_read.push_back(overlap)
	        return IO_PENDING
	    end
	    
	    int bytetransfer = read(overlap.buf,overlap.bytetransfer)
	    if bytetransfer < 0 then
	        if errno == EWOULDBLOCK then
	　　　　　　 s.readable = 0　　
	            s.pending_read.push_back(overlap)
	            return IO_PENDING
	        end
	    end
	    
	    return bytetransfer
	}

epoll中套接口被激活的伪代码:

	void OnReadActive(s)
	{
	    s.readable = 1
	    ioreq = s.pending_read.pop_front()
	    if ioreq ~= nil then
	        //弹出一个请求，执行，然后投递一个完成通告
			int bytetransfer = read(ioreq.buf,ioreq.bytetransfer)
	        ioreq.bytetransfer = bytetransfer
	        IOCompleteEventQueue.push_back(ioreq)
	    end
	}
	
完成例程的伪码如下:

	void complete_routine()
	{
	    complete_status = GetCompleteStatus()
	    s = GetSocket(complete_status)
	    do
	        ret = WSARecv(s,complete_status)
	    while( ret!= IO_PENDING) 
	}		

注：这个模式在最开始的时候实际的IO操作是交由另外的IO工作线程完成的，IO完成后投递完成通告
这样，即使IO立即可以完成也会投递完成通告，在IO繁忙时对完成队列的操作消耗也是不小的。改进
之后，只有当套接字从未激活态变为激活态，且有IO请求时才会投递一次完成通告(IOCP已经增加了类似
的选项FILE_SKIP_COMPLETION_PORT_ON_SUCCESS)

 
2)跟模式1类似，区别如下:

	void OnReadActive(s)
	{
	    s.readable = 1
	    ioreq = s.pending_read.pop_front()
	    if ioreq ~= nil then
	        IOCompleteEventQueue.push_back(ioreq)
	    end
	}	

也就是epoll线程完全不执行实际的IO请求，所有的请求都由用户提供的完成线程执行.此时完成队列
实际上并不存放完成事件，存放的只是pending的IO操作.此时Read操作也分成两个

	int WSARead(s,overlap)
	{
	    s.pending_read.push_back(overlap)
	    req = pending_read.pop_front()
	    IOCompleteEventQueue.push_back(req)//仅仅投递一个请求，不尝试完成操作
	}
	
	//此函数在完成例程中调用
	int raw_read(s,overlap)
	{
	    if !s.readable then
	        s.pending_read.push_back(overlap)
	        return IO_PENDING
	    end
	    
	    int bytetransfer = read(overlap.buf,overlap.bytetransfer)
	    if bytetransfer < 0 then
	        if errno == EWOULDBLOCK then
	            s.readable = 0
	            s.pending_read.push_back(overlap)
	            return IO_PENDING
	        end
	    end
	    
	    return bytetransfer
	}	

3)IO操作全部都在epoll线程中执行, 要充分利用多核CPU多启动几个epoll线程即可.
每个epoll对上层提供一个队列IO_queue，用以保存IO请求.上层请求IO时仅仅是往这
个队列中放入一个元素即可.

epoll线程主循环伪代码如下:

	void main_loop()
	{
	    while(true)
	    {
	        local_queue = IO_queue //将IO_queue中的所有请求同步到local_queue中
			while(req = local_queue.pop_front)
	        {
	            //保证请求按提交的顺序被执行
				req.s.pending_read.push_back(req)
	            req = s.pending_read.pop_front()
	            //执行请求，如果请求无法完成，重新插入到pending队列的头部    
			}
	        //epoll_wait............
			for all active s do
	            OnReadActive(s)
	        end    
	    }
	}
	
	void OnReadActive(s)
	{
	    s.readable = 1
	    while(ioreq = s.pending_read.pop_front())
	    {
	        read(ioreq.buf,ioreq.bytetransfer)
	        //操作完成，回调用一个用户提供的函数
		}
	}	


对于(1)(2)两个模式的实现可以参看:[epoll_mutilthread](https://github.com/sniperHW/epoll_mutilthread)

对于(3)可以参看[luanet](https://github.com/sniperHW/luanet)或陈硕的[muduo](https://github.com/chenshuo/muduo)
	
