---
title: 为博客添加 DisQus 评论
description: DisQus是很好的第三方留言、评论功能系统，使用它轻松完成github博客评论
layout: post
keywords: disqus 博客评论
tags: [教程]
---

DisQus 是一款很好的社交评论插件，只要在你的页面加上一段 js ，在你的DisQus 账户中就可以很方便地查看别人的评论。
####一、注册账户####
登陆<a href="http://www.disqus.com/">DisQus官网</a>，需要填写的地方分别是：Site URL，Site Name，Site Shortname。 注意：这3个都是必须要填写的，而且，短域名将会在最后的 install 中使用到。
####二、获取代码####
在_layouts的相应区域加入如下代码：
<pre class="code">
  &lt;div id="disqus_thread"&gt;&lt;/div&gt;
&lt;script type="text/javascript"&gt;
var disqus_shortname = 'example'; // 注意，这里的 example 要替换为你自己的短域名
/* * * 下面这些不需要改动 * * */
(function() {
  var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
  dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
})();
&lt;/script&gt;
&lt;noscript&gt;Please enable JavaScript to view the &lt;a href="http://disqus.com/?ref_noscript"&gt;comments powered by Disqus.&lt;/a&gt;&lt;/noscript&gt;
&lt;a href="http://disqus.com" class="dsq-brlink"&gt;blog comments powered by &lt;span class="logo-disqus"&gt;Disqus&lt;/span&gt;&lt;/a&gt;
   </pre>
####三、修改_config####
在_config里面添加信息：<br/>
disqus:
  short_name: "youngpine"。
####四、提交####
这样就简简单单的完成了github博客的评论功能了，由于其虽然插入了个iframe框架但框架恒定，所以读者也可以根据css、JS等对代码控制实现自己的风格。最后剩下的就是提交了！！！
