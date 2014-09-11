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

              