
##定义变量

	var variable type

例如:
	
	var name string
	
	var firstname,secondname string

定义变量并初始化:

	var name string = "kenny"

	var firstname,second string = "wong","kendny"

还可以忽略类型定，由编译器根据初始值推导类型:

	var name = "kenny" //string
	var age  = 32      //int
	//or
	var name,age = "kenny",32

简短声明:

	name := "kenny"
	age  := 32
	//or
	name,age := "kenny",32

简短声明有一个限制，只能用在函数内部。

##常量定义
go程序中常量可定义为数值，布尔值或字符串类型

	const const_name1 int = 100
	const const_name2 = "hello"
	//or
	const{
		const_name int = 100
		const_name2 = "hello"
	}


##字符串

字符串是用一对双引号("")或反引号(``)扩起来的定义，类型是string.
在go中字符串是不可变的,下面代码会编译出错:

	var s = "hello"
	s[0] = 'c'

如果要修改可以将string先转成[]byte类型,例如:

	s:="hello"
	c:=[]byte(s)
	c[0] = 'c'
	s2 = string(c)

如果要声明一个多行的字符串可通过反引号(``)来定义:

	m : = `hello
		  ,haha`	


##iota枚举

go里面有一个关键字iota,用来声明enum的时候采用,默认值是0,每次调用一次加1,而每次遇到const关键字,iota就会重置回0:

	const(
		a = iota //0
		b = iota //1
		c = iota //2
	)
	const d = iota//iota重置，d == 0

##数组

数组的定义方式如下:

	var arr[n]type

其中n表示数组长度,type表示存储类型,数组的下标从0开始:

	var arr[10]int
	arr[0] = 1
	arr[1] = 2
	//or
	arr := [10]int = {1,2,3}//只初始化前3个元素
	//or
	arr :=[...]int = {1,2,3}//自动根据元素个数计算长度

##slice

slice是一个引用类型，指向一个底层的数组,slice的声明可以像数组一样只是不需要长度:
	
	var fslice[]int
	//or	
	fslice := []byte{'a','b','c'}//声明并初始化

slice可以从一个数组或一个已经存在的slice中再次声明.slice通过array[i:j]来获取,i是起始下标,j是结束下标,长度是j-i,也就是说array[j]不包括在内.

因为slice是引用类型,所以当一个引用改变其中的值时，其它所有的引用都会被改变:

		var array = [4]int32{1,2,3,4}
		var slice = array[1:3]
		var slice1 = slice[0:2]
		array[1] = 10
		//slice[0] == 10
		slice[1] = 100
		//array[2] == 100
		//slice1[1] = 100	

对于slice类型有几个内置函数:

1. len获取slice长度
2. cap获取slice的最大容量
3. append向slice追加一个或多个元素，返回一个和slice类型一样的slice
4. copy从源src中复制元素的dst,并返回复制元素的个数

注意:append函数会改变slice所引用的数组的内容，但当slice中的空间不足时，将动态分配一个新的可以容纳所有元素的数组。返回的slice指向这个数组原数组内容不变:

	var array = [4]int32{1,2,3,4}
	var slice = array[1:2]
	array[1] = 10
	var slice1 = append(slice,100)
	var slice2 = append(slice1,101)
	_ = append(slice2,102)
	fmt.Printf("array,%d\n",array[0])
	fmt.Printf("array,%d\n",array[1])
	fmt.Printf("array,%d\n",array[2])
	fmt.Printf("array,%d\n",array[3])
	//输出,注意array的内容被改变了
	//array,1
	//array,10
	//array,100
	//array,101
	var slice3[]int32
	var slice4 = append(slice3,10)
	fmt.Printf("slice3 len:%d\n",len(slice3))
	fmt.Printf("slice4:%d\n",slice4[0])
	//输出,注意slice3的len依旧是0
	//slice3 len:0
	//slice4:10
	
##字典(map)

map类似于C++中的std::map,格式为`map[keyType]valType`跟C++中不同的是map是引用类型，并且是无序的.

##make和new
make用于内建类型(字典,slice和channel)的内存分配,new用于各种类型的内存分配.new的返回值时指针.

##函数
函数的基本格式如下:

	func funcname(input1 type1,...)(output1 type1,...){
		return value1,...
	}

- func用来声明函数
- 函数可以有0-n个参数,用,分隔
- 函数可以有多个返回值
- 函数返回值可以声明变量，不声明也可以直接写类型
- 如果只有一个返回值且不声明返回值变量可以省略包括返回值的括号
- 如果没有返回值直接省略最后的返回信息
- 如果没有返回值必须在函数的外层添加return语句

####可变参数

	func function(arg ...type){}

其中arg是type的slice.

####defer

defer在函数返回之前执行,你可以为函数添加多个defer语句，在函数返回前defer语句会按照逆序执行.

####main和init函数

这两个函数定义时不能有任何参数或返回值.init函数在package中是可选的，如果要定义那么建议只定义一个.package main必须包含一个main函数.

##struct类型

struct定义如下例:

	type person struct{
		name string
		age int
	}

struct的初始化:

	P := person{"kenny",32}
	P := person{age:32,name:"kenny"}

访问struct中的字段:

	var P person
	P.name = "kenny"
	P.age = 32

####struct中的匿名字段

struct中可以有匿名字段,当匿名字段是struct时这个struct拥有的所有字段都被隐式的引入到当前定义的这个struct.

	type Human struct{
		name string
		age int
		weight int
	}
	
	type Student struct{
		Human //匿名字段
		speciality string
	}

	//匿名字段的访问
	
	var kenny := Student{Human{"kenny",32,120},"cs"}
	fmt.Println("name:",kenny.name)//Human中的字段
	
所有内置类型和自定义类型都可以作为匿名字段.

