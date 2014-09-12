###扩展语法(Syntactic extensions)

扩展语法就是通过核心语法或已经定义的扩展语法创建一种新的语法模式.


#####Scheme核心语法模式包括:

* 顶层定义
* 常量
* 变量
* 过程应用
* '(quote)表达式
* lambda表达式
* if表达式
* set!表达式

#####Scheme语法:

	<program>    		  --> <form>*
    <form>       		  --> <definition> | <expression>
    <definition> 		  --> <variable definition> | (begin <definition>* )
    <variable definition>  --> (define <variable> <expression> )
    <expression> 		  --> <constant>
                     		| <variable>
    				 		| (quote <datum> )
    					     | (lambda <formals> <expression> <expression>* )
    				 		| (set! <variable> <expression> )
                     		| <application>
    <constant> 			--> <boolean> | <number> | <character> | <string>
    <formals>              --> <variable>
    				 		| ( <variable>* )
    				 		| ( <variable> <variable>* . <variable> )
	<application> 		 --> ( <expression> <expression>* )


扩展语法let的定义:

	(define-syntax let
  	 (syntax-rules ()
    	 [(_ ((x e) ...) b1 b2 ...)
     		 ((lambda (x ...) b1 b2 ...) e ...)]))

define-syntax之后出现的名字是新定义的扩展语法关键字，在这里是let.
之后通过syntax-rules定义转换规则:syntax-rules后紧跟的是额外关键字的list,在这里是个空的list.
后面是一系列的规则(通过[]定义一个规则),由模式/模板对组成.在let的定义中只使用了一个规则.其中模式部分定义了语法扩展的输入模式.
模板部分定义了如何将输入模式转换成输出模式.

规则中的模式部分必须是一个结构完整的表达式,通常第一个元素是`_`.如果一个扩展语法的定义中出现了多个规则
,解释器/编译器会按规则定义的顺序去匹配模式，如没有合适匹配将会导致一个语法错误.


###letrec

通过let将一个名字与一个lambda表达绑定之后,是无法在lambda表达式内调用绑定的名字以实现递归调用的,例如:

    (let ([sum (lambda (ls)
                 (if (null? ls)
                     0
                     (+ (car ls) (sum (cdr ls)))))])
      (sum '(1 2 3 4 5)))

将会报错,提示sum没有定义,这是因为sum只是在let表达式的body部分可见而在lambda表达式内是不可见的.

要达到上述效果必须使用扩展语法letrec

    (letrec ([sum (lambda (ls)
                    (if (null? ls)
                        0
                        (+ (car ls) (sum (cdr ls)))))])
      (sum '(1 2 3 4 5)))

letrec的语法形式如下:

    (letrec ((var expr) ...) body 1  body 2  ...)

其中var不仅在body中可见,在expr中也是可见的.

使用letrec表达式的时候必须要注意一点:任意expr的求值都不应依赖任意var的求值,例如下面的表达式就违反了这一点.

    (letrec ([y (+ x 2)]
             [x 1])
      y)

(+ x 2)的求值依赖于x的值,运行时将会提示异常: x没定义.


###具名let表达式

具名let表达式语法形式如下:

	(let name ((var expr) ...)
  		body 1  body 2  ...)

它与let表达式的唯一区别在于,在body中,name被绑定成一个过程且可以递归调用.而传递给这个过程的参数会成为var的新值,下面是一个用具名let实现的`list?`函数:

    (define list?
      (lambda (x)
        (let race ([h x] [t x])
          (if (pair? h)
              (let ([h (cdr h)])
                (if (pair? h)
                    (and (not (eq? h t))
                         (race (cdr h) (cdr t)))
                    (null? h)))
              (null? h)))))

如同let表达式可被表示为直接将lambda表达式应用在参数上一样,具名let可被表示为将一个递归过程应用到参数上,例如
上面具名let的语法形式可以用letrec改写如下:

    ((letrec ((name (lambda (var ...) body 1  body 2  ...)))
       name)
     expr ...)

或

	(letrec ((name (lambda (var ...) body 1  body 2  ...)))
  		(name expr ...))

###延续(continuation)
[见 2014-09-04-延续(continuation)](https://github.com/sniperHW/sniperHW.github.io/blob/master/md/2014-09-04-%E5%BB%B6%E7%BB%AD(continuation)

###延续传递风格(Continuation Passing Style)

在执行过程调用的时候实际上产生了一个隐含的延续,这个延续是被调用过程返回后后续的执行流程.例如:

    (letrec ([f (lambda (x) (cons 'a x))]
             [g (lambda (x) (cons 'b (f x)))]
             [h (lambda (x) (g (cons 'c x)))])
      (cons 'd (h '())))

调用过程`(f x)`的延续是将`'b cons `到` (f x)`的返回值,然后返回给更上一层的调用者.  

可以通过将延续打包成一个过程,作为参数传递给被调函数，然后在被调函数中执行这个过程的形式来改写上述代码:

    (letrec ([f (lambda (x k3) (k3 (cons 'a x)))]
             [g (lambda (x k2)
                  (f x (lambda (v) (k2 (cons 'b v)))))]
             [h (lambda (x k1) (g (cons 'c x) k1))])
      (h '() (lambda (v) (cons 'd v))))

首先看`[f (lambda (x k3) (k3 (cons 'a x)))]`,其对应的延续是`(cons 'b (f x))`,此时k3是`(lambda (v) (k2 (cons 'b v)))`
所以`(k3 (cons 'a x))`等价于`(k2 (cons 'b (cons 'a x)))`,而k2是`(lambda (v) (cons 'd v))`所以`(k2 (cons 'b (cons 'a x)))`等价于`(cons 'd (cons 'b (cons 'a x)))`,所以在f的函数体中实际执行的是`(cons 'd (cons 'b (cons 'a x)))`.

这种将延续打包成过程作为参数传递给被调函数，并在被调函数中执行延续的风格就叫延续传递风格.


显然第一个版本的代码比延续传递风格的代码更简单易懂，那么延续传递风格有什么作用。
首先第一版的代码不是尾递归的，而延续传递风格的版本是尾递归的，也就是说可以通过延续传递风格把非尾递归的代码改成尾递归的.

其次,Scheme中函数调用只能有一个返回值,而将延续打包成过程之后,作为过程调用的延续是可以接受多个参数的.我们甚至传递几个延续作为参数，由被调过程根据不同的情况调用不同的延续,例如:

    (define integer-divide
      (lambda (x y success failure)
        (if (= y 0)
            (failure "divide by zero")
            (let ([q (quotient x y)])
              (success q (- x (* q y)))))))

    (integer-divide 10 3 list (lambda (x) x))   (3 1)
    (integer-divide 10 0 list (lambda (x) x))   "divide by zero"

###内部定义

可以在`lambda`,`let`,`letrec`表达式`body`的最前面通过`define`表达式定义变量,这样定义的变量只在外围表达式的`body`内有效,
也就是一个局部变量.


例如可以将:

    (letrec ([even?
              (lambda (x)
                (or (= x 0)
                    (odd? (- x 1))))]
             [odd?
              (lambda (x)
                (and (not (= x 0))
                     (even? (- x 1))))])
      (list (even? 20) (odd? 20))) ->  (#t #f)

替换成内部定义的形式:

    (let ()
      (define even?
        (lambda (x)
          (or (= x 0)
              (odd? (- x 1)))))
      (define odd?
        (lambda (x)
          (and (not (= x 0))
               (even? (- x 1)))))
    (even? 20)) -> #t

内部定义与`letrec`的主要区别在于,内部定义中变量的定义是严格遵循从左到右求值(注:Scheme解释器会忽略换行就好像所有的代码都在一行上一样,所以出现在前面的行相当于在左边),而`letrec`表达式中的绑定则可以以任意顺序求值.例如在上面的示例代码的内部定义版本中`even?`必定先于`odd?`求值,而在`letrec`的版本则不保证这一点.

为了保证从左到右的求值顺序可以使用`letrec*`

    (define var expr 0 )
     .
     .
     .
    expr 1
    expr 2
     .
     .
     .

等价于

	(letrec* ((var expr 0 ) ...) expr 1  expr 2  ...)

等价于

    (let ()
      (define var expr 0 )
        .
        .
        .
      expr 1
      expr 2
        .
        .
        .
    )

内部定义与`letrec*`的主要区别在于内部定义只能出现在表达式体的开始部分而`letrec*`可以出现在任何地方.另一个区别是扩展语法定义也可以是内部定义，区别于顶层扩展语法定义,内部扩展语法定义的有效性局部于定义的表达式体。

	(let ([x 3])
  		(define-syntax set-x!
    		(syntax-rules ()
      		[(_ e) (set! x e)]))
  			(set-x! (+ x x))
  	x)->6

以上扩展语法定义中,`set-x!`只在`let`表达式内部有效.

内部定义结合顶层定义和赋值一起使用提供了一种使得程序模块化的手段.例如：

    (define export-var #f)
        .
        .
        .
    (let ()
      (define var expr)
        .
        .
        .
      init-expr
        .
        .
        .
      (set! export-var export-val)
        .
        .
        .
    )
    
通过顶层定义,`export-var`在全局可见.而在`let`中内部的定义则只能在本模块可见.

###库

另一种提供模块化的手段是使用库:

    (library (grades)
      (export gpa->grade gpa)
      (import (rnrs))
      (define in-range?
        (lambda (x n y)
          (and (>= n x) (< n y))))
      (define-syntax range-case
        (syntax-rules (- else)
          [(_ expr ((x - y) e1 e2 ...) ... [else ee1 ee2 ...])
           (let ([tmp expr])
             (cond
               [(in-range? x tmp y) e1 e2 ...]
               ...
               [else ee1 ee2 ...]))]
          [(_ expr ((x - y) e1 e2 ...) ...)
           (let ([tmp expr])
             (cond
               [(in-range? x tmp y) e1 e2 ...]
               ...))]))
      (define letter->number
        (lambda (x)
          (case x
            [(a)  4.0]
            [(b)  3.0]
            [(c)  2.0]
            [(d)  1.0]
            [(f)  0.0]
            [else (assertion-violation 'grade "invalid letter grade" x)])))
        (define gpa->grade
            (lambda (x)
              (range-case x
                [(0.0 - 0.5) 'f]
                [(0.5 - 1.5) 'd]
                [(1.5 - 2.5) 'c]
                [(2.5 - 3.5) 'b]
                [else 'a])))
          (define-syntax gpa
            (syntax-rules ()
              [(_ g1 g2 ...)
               (let ([ls (map letter->number '(g1 g2 ...))])
                 (/ (apply + ls) (length ls)))])))
                 
通过关键字`library`定义了一个名为`grades`的库向外导出了两个标识符`gpa->grade`和`gpa`其中`gpa->grade`是一个过程`gpa`是一个扩展语法定义.

    (import (grades))
    (gpa c a c b b)  ->  2.8
    (gpa->grade 2.8) ->  b
    
通过`import`导入库之后就可以引用那个库中导出标识符了.    