首先看下延续的定义:

* [续延是在运行中被暂停了的程序：即含有计算状态的单个函数型对象。当这个对象被求值时，就会在它上次停下来的地方重新启动之前保存下来的计算](http://www.ituring.com.cn/article/53793)

* [在计算机科学和程序设计领域,延续是计算机程序控制状态的一种抽象表现形式.一个延续具现化了程序控制状态,它保存了程序执行过程中某一个特定点的计算过程](http://en.wikipedia.org/wiki/Continuation)

拿科幻片中的场景做比喻的话,延续有点像时空门,这扇门在某个时间上的某个地点被设立,当我们打开这扇门走进去,出来的时候就会从锁定的那个时间和那个地点重新开始。

利用延续，我们可以方便的实现一些更复杂的程序控制状态,例如:非局部退出，异常处理， generators和协程等.

下面从一段实现非局部跳转的Scheme程序片段来深入理解延续.
    
    (define (search-element element lst)
    	(display (call/cc (lambda (break)
    		(for-each (lambda (item) (if (equal? item element) (break #t))) lst) 
    		#f)))
    )

这个函数的功能是从给定的一组数字中搜索某一特定的数字，如果找到输出#t,否则输出#f.

    > (search-element 3 '(1 2 3 4))
    #t
    > (search-element 0 '(1 2 3 4))
    #t

首先必须先介绍`call/cc`,它的作用是捕获当前的延续.下面是TSPL中对`call/cc`的介绍:

* call/cc用于捕获当前的 continuation，需要给它提供一个单参函数作为参数调用.在这个单参函数的
函数体内被捕获的continuation绑定到了传入的参数上.如果在函数体内没用直接或间接的调用continuation
那么函数的返回值就是call/cc的返回值.如果在函数体内调用了continuation,那么传递给它的参数就是call/cc的返回值.

从上述的描述中可以知道,延续的表现形式很像一个函数，调用这个延续就可以进入那扇时空门,回到我们设立时空门的那个时间和那个地点.

在回到上面的例子,在这个例子中我们捕获到的延续可以如下表示:

    (define (search-element element lst)
    	   (display _)
    )
    
因为延续被绑定到了`break`,`(break #t)`相当于回到`display`这个执行点上,把`_`替换成`#t`然后继续执行.    

现在对这个程序段稍加修改来更好的研究延续:

    (define c1 10)
    (define val1 100)
    
    (define (search-element element lst)
    	(display "begin search-element\n")  
    	(display (call/cc (lambda (break)
    		(display "here\n")
    		(set! c1 break)	
    		(for-each (lambda (item) (if (equal? item element) (break #t))) lst) 
    		#f)))		    
    	(display " end of search-element\n")
    	(display "val1:")(display val1)     
    )
    
我们把捕捉到的延续绑定到了一个全局变量c1上，以使得作为`call/cc`参数的函数体内也可以调用延续.

    > (search-element 3 '(1 2 3 4))
    begin search-element
    here
    #t end of search-element
    val1:100
   
    > (c1 `k)
    k end of search-element
    val1:100
    
    > (set! val1 1000)
    > (c1 `c)
    c end of search-element
    val1:1000

我们来看下输出,第一次调用的输出比后面的输出多了两行
    
    begin search-element
    here

这说明了我们调用延续的时候,的确是从第二个display那里继续执行的.而后面我们改变了全局变量val1的值，在后续调用延续的时候
这种改变也被查觉到了, 这说明延续保存的只是调用链和局部变量.

20岁的那年你设立了时空门,40岁的时候你从时空门回到过去，但你依旧还是40岁.

下面再看一个复杂点的例子一个generator.

	(define (for-each proc items)
	  (define (iter things)
	    (cond ((null? things))
	        (else
	            (proc (car things))
	            (iter (cdr things)))))
	 (iter items))
	
	
	(define (generate-one-element-at-a-time lst)
	  ;; Hand the next item from a-list to "return" or an end-of-list marker
	  (define (control-state return)
	    (for-each 
	     (lambda (element)
	       (call/cc
	        (lambda (resume-here)
	          ;; Grab the current continuation
	          (set! control-state resume-here) ;; !!!
	          (return element))))
	     lst)
	    (return 'end))
	
	  (define (generator)
	    (call/cc control-state)) 
	  ;; Return the generator 
	  generator)   

看下输出:

	> (define generate-digit (generate-one-element-at-a-time '(0 1 2)))
	> (generate-digit)
	0
	> (generate-digit)
	1
	> (generate-digit)
	2
	> (generate-digit)
	end
	> (generate-digit)
	end
	
每次调用(generate-digit)都会按序从创建时传入的数字序列中返回一个数字，如果到达序列的最后
则返回end.

分析下执行流程,首先将`generate-digit`定义成`(generate-one-element-at-a-time '(0 1 2))`的返回值
,也就是过程`generator`,所以`(generate-digit)`实际调用的就是`(generator)`.

第一次调用`(generate-digit)`的时候,call/cc捕获到的延续在`control-state`中被绑定到名字`return`.
所以每当调用`return`就会回到`generator (call/cc)`的地方,继续执行后面的流程.

在`control-state`中,将lambda函数

	  (lambda (element)
       (call/cc
        (lambda (resume-here)
         (set! control-state resume-here)
          (return element))))

作为参数调用`for-each`,在`for-each`中这个lambda函数被绑定到名字`proc`,`proc`被调用的时候捕获延续并绑定到名字`resume-here`.
当这个延续被调用的时候，执行流程就回到`(proc (car things))`然后继续执行后面的`(iter (cdr things)))))`

需要注意的是,在这个lambda函数中`control-state`被替换成了`resume-here`所以除了第一次以外,其余对`generator`
的调用实际上调用的都是延续`resume-here`.

下面把程序做个小的调整：

	(define c 0)


	(define (for-each proc items)
	  (define (iter things)
		(cond ((null? things))
			(else
				(proc (car things))
				(iter (cdr things)))))
	 (iter items))


	(define (generate-one-element-at-a-time lst)
	  (define (control-state return)
		(for-each 
		 (lambda (element)
		   (call/cc
			(lambda (resume-here)
			  (cond ((> c 0))          
				(else
					(set! c 1)
					(set! control-state resume-here)
				 ))
			  (return element))))
		 lst)
		(return 'end))

	  (define (generator)
		(call/cc control-state)) 
	  generator)

再看下输出:

	> (define generate-digit (generate-one-element-at-a-time '(0 1 2)))
	> (generate-digit)
	0
	> (generate-digit)
	1
	> (generate-digit)
	1
	> (generate-digit)
	1
	> (generate-digit)
	1

这次只在第一次调用`proc`的时候才将`control-state`设置为`resume-here`,也就是说以后的每次调用，实际上都是第一次调用`proc`时的延续,
而在这个延续中,相关的变量`things`始终是`(1,2)`,所以无论调用多少次`(generate-digit)`始终都是返回1.	
	
最后贴一段用延续实现的协程来结束这篇博文.

	    ;一个简单的,用continuation实现的协程接口
	    (define current-coro '());当前获得运行权的coro
	    
	    ;创建coro并返回,fun不会立即执行，由start-run执行
	    (define (make-coro fun)
	        (define coro (list #f #f))
	        (let ((ret (call/cc (lambda (k) (begin
	            (set-context! coro k)
	            (list 'magic-kenny coro))))))
	            (if (and (pair? ret) (eq? 'magic-kenny (car ret)))
	                (cadr ret)
	                ;如果下面代码被执行,则是从switch-to调用过来的
	                (begin (let ((result (fun ret)))
	                       (set-context! coro #f)
	                       (set! current-coro (get-from coro))            
	                       ((get-context (get-from coro)) result)));fun执行完成后要回到调用者处
	            )
	        )
	    )
	            
	    (define (get-context coro) (car coro))
	    (define (set-context! coro context) (set-car! coro context))        
	    (define (get-from coro) (cadr coro))
	    (define (set-from! coro from) (set-car! (cdr coro) from))
	    
	    (define (switch-to from to arg)
	        (let ((ret
	              (call/cc (lambda (k)
	                    (set-from! to from)
	                    (set! current-coro to)
	                    (set-context! from k)
	                    ((get-context to) arg)
	                    arg))))
	         ret)
	    )
	    
	    ;启动一个coro的运行，那个coro将会从它在创建时传入的函数开始运行
	    (define (start-run coro . arg)
	        (let ((param (if (null? arg) arg (car arg))))
	            (if (null? current-coro) (set! current-coro (make-coro #f)))
	            (switch-to current-coro coro param))
	    )
	    
	    ;将运行权交给另一个coro
	    (define (yield coro . arg)
	        (let ((param (if (null? arg) arg (car arg))))
	            (switch-to current-coro coro param)))
	    
	    ;将运行权还给原来把运行权让给自己的那个coro
	    (define (resume . arg)
	        (let ((param (if (null? arg) arg (car arg))))
	            (switch-to current-coro (get-from current-coro) param)))
	    
	    
	    
	    ;;;;;;;test procedure below;;;;;;;;;;;;
	    (define (fun-coro-a arg)
	        (display "fun-coro-a\n")
	        (yield (make-coro fun-coro-b))
	        (display "coro-a end\n")
	        "end"
	    )
	    
	    (define (fun-coro-b arg)
	        (display "fun-coro-b\n")
	        (display "fun-coro-b end\n")
	        "end"
	    )
	    
	    (define (test-coro1)
	        (start-run (make-coro fun-coro-a))
	    )
	    
	    (define (fun-coro-a-2 arg)
	        (define coro-new (make-coro fun-coro-b-2))
	        (define (iter)
	            (display "fun-coro-a\n")
	            (display (yield coro-new 1))(newline)
	            (iter)
	        )
	        (iter)
	    )
	    
	    (define (fun-coro-b-2 arg)
	        (define (iter)
	            (display "fun-coro-b\n")
	            (display(resume 2))(newline)
	            (iter)
	        )
	        (iter)
	    )
	    
	    (define (test-coro2)
	        (start-run (make-coro fun-coro-a-2))
	    )

参考:

* [The Scheme Programming Language Fourth Edition (R. Kent Dybvig)](http://www.scheme.com/tspl4/)

* [On Lisp中文版(田春翻译)](http://www.ituring.com.cn/minibook/862)

* [Wiki Continuation](http://en.wikipedia.org/wiki/Continuation)

* [Continuation 和高级流程控制(Jonathan Bartlett)](http://www.ibm.com/developerworks/cn/linux/l-advflow.html)

* [Scheme Continuation 三部曲（一）——深入理解 Continuation](http://blog.sina.com.cn/s/blog_4dff871201018wtz.html)