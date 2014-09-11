
<script type="text/javascript" src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=default"></script>

$$x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}$$
\\(x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}\\)

首先看下continuation在TPSL中的定义:

Scheme在对一个表达式求值的时候需要跟踪两样东西:

* 对什么求值
* 如何处理求出的值(需要等待目标值被求出)

考虑以下表达式中的求值语句`(null? x)`:

    (if (null? x) (quote ()) (cdr x))
    
首先必须先求出`(null? x)`的值,然后基于这个值来选择后续是对`(quote ()`还是'(cdr x)'求值.
对于上述表达式而言`(null? x)`对应'对什么求值',而与'如何处理求出的值'对应的就是选择对
`(quote ()`还是'(cdr x)'求值.我们将'如何处理求出的值'称为一个计算的`continuation`.

假设`x`的值是`(a b c)`我们可以把`(if (null? x) (quote ()) (cdr x))`分成6个独立的`continuation`它们分
别在等待下面的表达式被求值:

* (if (null? x) (quote ()) (cdr x))

* (null? x)

* null?

* x

* cdr

* x

等待`(cdr x)`被求值的`continuation`没有被列出来因为它和等待`(if (null? x) (quote ()) (cdr x))`被求值的`continuation`是同一个`continuation`.

取出`(null? x)`举例,将它替换成这样的形式`(null? _)`,我们需要在`_`位置提供一个值才能让这个表达式的求值进行下去.也就是说
`continuation`其实就是一个等待执行的计算过程,要让这个计算过程继续(continue)我们必须为它提供一个值.这也就是被称之为`continuation`
的原因.

可以用一个数学表达式做对比`3 + x`,要计算这个表达式的值首先要给x提供一个值.也就是计算过程`3 + x`在等待x的输入才能继续下去.


*continuation 的三个特性:*

+ continuation as first-class，简单地说就是 continuation 也可以视为一等公民，可以当做参数被传递和返回；

+ continuation is represented by procedure，也就是说可以视 continuation 为过程，可以调用它，本来也应该如此，因为 continuation 表示的正是“将来的计算过程；

+ 假设 call/cc 捕捉了当前的 continuation，并绑定到 lambda 的参数 cc，那么在 lambda 函数体内，一旦 cc 被直接或间接的作为过程调用，那么 call/cc 会立即返回，并且提供给 cc 的参数即为 call/cc 的返回值。
(调用这个cc相当于为_位置提供值,这个值就是传递给cc的参数)


下面先用一个no-local exit的使用作为例子:

	(define (search-element element lst)
	    (display (call/cc (lambda (break)
	        (for-each (lambda (item) (if (equal? item element) (break #t))) lst) 
	        #f)))    
	    (display " end of search-element\n")    
	)

上面代码的作用是从一个list中搜索给定的元素，如果找到返回#t,否则返回#f.
先让我们看下输出:

	> (search-element 0 '(1 2 3 4))
	#f end of search-element
	> (search-element 3 '(1 2 3 4))
	#t end of search-element


我们将

    	    (display (call/cc (lambda (break)
	        (for-each (lambda (item) (if (equal? item element) (break #t))) lst) 
	        #f))) 
	        
中的    

    (call/cc (lambda (break)
	        (for-each (lambda (item) (if (equal? item element) (break #t))) lst) 
	        #f))
	        
替换成`_`那么上述表达式就变成`(display _)`而在`call/cc`调用中我们将这个`continuation`绑定到了`break`,所以`(break #t)`相当于给`_`位置提供了一个值
`#t`使得计算过程继续下去,从形式上看就相当于从`for-each表达式中`直接返回到`call/cc`的外层,执行`(display #t)`.

下面再来看一个复杂点的例子,一个generate,当generate被调用时，每次从其输入的序列中输出下一个元素，当到达序列的尾部时输出'end.

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
	  
我们先来看一下上面代码的输出

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


上面代码捕获了两个`continuation`,我们先来看第一个`(define (generator) (call/cc control-state))`调用`(generator)`返回
`(call/cc control-state)`而这个`continuation`被绑定到`return`所以`(return element)`和`(return 'end)`就相当于`element`
和`'end`.


	  	

上面输出奇怪的一个地方在于除了0的上面没有come back，所有的其它输出都跟了come back.我们来看看这到底是什么原因.
当我们第一次调用generate-digit在for-each内部调用proc时，在此例中proc就是(call/cc (lambda (resume-here) ...),call/cc调用捕捉到了当前continuation,
并将其绑定到control-state,这样后面每次调用generate-digit就会使得从continuation中返回，在这里返回点在proc之后,也就是(display "come back\n"),
这就解释了为什么除了第一次generate-digit以外，其后的每次generate-digit都会输出一个come back。

最后，贴一段用continuation实现coroutine的代码结束本文.

	(begin
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
	    
	)	
	
