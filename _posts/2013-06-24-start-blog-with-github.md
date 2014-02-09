---
title: Github博客文件结构简析
description: 初次接触Github，谈谈其文档结构
keywords: github
layout: post
tags: [教程]
---

####一、综述####
  抛去所有形式之后，终究还是html+css的事。了解文档结构能帮助我们回到本源。
####二、文档结构简析####
  github博客有其管理文件规范，主要有：_include、_layout、posts、_config.yml、index.html、page.html、Github.sln，其余文件都可以按照自己的进行操作。

  _includes：这里面放的是一个网页的可重复部分，相当于把一个正常的网页拆分，使得可重复的部分可以被重复的利用。

  _layout：这里面放的是模板，一般有两个，一个是首页和所有文章等一级页面使用，另一个是自己写的文章的模板。

  posts：这里放的是自己的文章，有固定格式：年-月-日-标题。

   _config.yml和Github.sln：这是一个识别标志，只需要改动里面的属于个人信息成分。

  page.html：这是一个神奇的页面，可以自动的吧你所有的文章按照一定标签（这个标签就是posts里面每篇文章的最前面tags后面的名称）分类，便于查阅。

  其余的设计：images、javascript、stylesheets，相信意思是很容易明白的，因为这是做网页的必须文件。
####三、博客制作####
  关于制作博客，网上已经有了很多教程，我这里主要说的是依靠已有模板制作：首先登陆：http://github.com/youngpine/study下载整个文档，这样就实现了文档的构建。
  
  1、这里面有许多的个人信息包含在了_config、Github.sln等文件中，需要自己做修改。
  
  
  2、建立repo；名称最好是：username.github.io,这样可以让域名简单。
  
  3、利用Github的page功能自动生成页面：repo---settings---Automatic Page Generator---Continue to Layouts---Publish。
  
  4、复制到自己的电脑，并用已有文档进行替换。
  
  5、接下来基本就是网页的基本制作了。
####四、内容格式####
  1、post里面的文章的规格：首先要有模板引用和tag以及categories说明。其格式是：
   <pre class="code">
   title：Hello,world!
   layout:post
   tags:[教程]
   categories: [作品]
   </pre>
   
  2、每个文件中{***}中的内容属于引用模块，如果掌握了将网页划分为不同的区域，你就可以实现很多文件的重复利用。
####五、参考教程####
　<a href="http://ce.sysu.edu.cn/hope/Item/103719.aspx">http://ce.sysu.edu.cn/hope/Item/103719.aspx</a>
  
  <a href="http://www.freehao123.com/github-pages/">http://www.freehao123.com/github-pages/</a>
  
  <a href="http://www.ruanyifeng.com/blog/2012/08/blogging_with_jekyll.html">http://www.ruanyifeng.com/blog/2012/08/blogging_with_jekyll.html</a>
