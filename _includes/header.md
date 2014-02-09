<!-- header -->
<div id="header">
      <a href="/" target="_self"><h1 id="name">松的博客</h1></a>
      <ul id="nav" class="nav">
          <a href="/" target="_self"><li>首页</li></a>
          <a href="/page.html" target="_self"><li>博文</li></a>
          <a href="/production.html" target="_self"><li>作品</li></a>
          <a href="/message.html" target="_self"><li>留言</li></a>
          <a href="/about.html" target="_self"><li>关于</li></a>
      </ul>
      <div id="search">
       <script type="text/javascript">
			function searchSubmit(){
				var s_keyword = document.getElementById("search_name").value; 
				if(s_keyword == '' || s_keyword == '搜索'){
				    alert("请输入您想搜索的关键词");
				    return false;
			    }
			}
			</script>
      <form method="get" action="http://www.google.com/search" name="c_search">
      <input type="text" id="search_text" name="q" />
	  <input type="hidden" name="oe" value="GB2312"/>
	  <input type="hidden" name="hl" value="zh-CN"/>
	  <input type="hidden" name="as_sitesearch" value="youngpine.github.io">
	  <input type="submit" id="search_button" name="search_button" value="搜索" />
      </form>
      </div>
    </div>
<!-- /header -->
