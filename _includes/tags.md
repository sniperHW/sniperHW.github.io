<div id="tags">
<h2>标签</h2>
<ul class="linkBgChange">
{% for tag in site.tags %}
<a href="/page.html"><li id="{{ tag[0] }}-ref">{{ tag[0] }}</li></a>
{% endfor %}
{% for cat in site.categories %}
<a href="/production.html"><li id="{{ cat[0] }}-ref">{{ cat[0] }}</li></a>
{% endfor %}
</ul>
</div>