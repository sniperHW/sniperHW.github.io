---
author: tom.vaughan
comments: true
date: 2012-01-20 17:26:07+00:00
layout: post
slug: spring-configuration-and-library-decomposition
title: Spring Configuration and Library Decomposition
wordpress_id: 495
categories:
- Code
- Spring
---

Opower has evolved rapidly in the last 24 months and nowhere is that more true than in our code base.  Two years ago we had 2 flagship applications that shared model objects, DAOs and a handful of utility classes with one common JAR.  Since then we've expanded to the point where (not even counting all the Ruby or Scala stuff) we're managing:

  * 4 WAR applications
  * 33 JAR libraries (1 open sourced @ [https://github.com/opower/jpile](https://github.com/opower/jpile))
  * 14 "pom artifacts" that define groupings of projects and organize dependencies, versions, etc.

Not all of that growth was brand new, however.  As we expanded our product lines and thought more about the best way to scale our core features we invested heavily in the decomposition of existing WARs and improving the "librarification" of our code.  In addition to supporting scaling, improving the modularity of our code base also supports a move towards S.O.A. and improves the velocity of our scrum teams.  After all, it's a lot easier to focus on developing the stories in your iteration if you don't need to worry about stepping on another team's toes.  That's more easily achievable when your team aligns to one specific code artifact.

A problem we quickly ran in to as we started decomposing WARs and JARs was the creation of a lot of redundant spring configuration files -- especially in an integration test context.  Here's a crude picture of our initial state following some decomposition:

[![One WAR depending on two JARs with duplicated spring bean configuration](/img/pic11-300x161.png)](/img/pic11.png)

Note that the WAR includes the two JARs and wires together beans declared in the JARs with an `applicationContext.xml` defined in the WAR.  We thought it would be a good idea to adopt the policy of "keep the tests close to the code that they stress."  That's a sensible policy, but resulted in duplication of context configuration found in the WAR for the purposes of spinning up Spring contexts during integration tests.

Reducing that duplication was done by continuing the theme of decomposition and applying it to the Spring context as well.  For example, we adopted the policy that a JAR should export a sensible "default wiring" of the classes that it encapsulates.  We adopted naming conventions to facilitate the need to either explicitly or implicitly include a Spring context snippet.

  * If a JAR includes a context file ending in "-spring.xml" then it's automatically included by any WAR that declares a dependency on that JAR.
  * On the other hand, if a JAR includes a context file ending in "Context.xml" then it is only brought in to the WAR's context with an explicitly declared inclusion of that file.

Here's what the picture looked like when we migrated to that model:

[![One WAR with two JARs, but no duplicated bean configuration](/img/pic21-300x170.png)](/img/pic21.png)

Integration tests that lived in our various JARs liked living in this model because they could always import "*-spring.xml" and their integration test context would come up and run just fine.

This worked well until we encountered some situations where one JAR started depending on another JAR.  We wanted to ship sensible Spring context defaults from both JARs, but because of the "*-spring.xml" rule we ended up needing to duplicate all of the application properties that were needed to wire up the beans in the depended artifact from within the src/test/resources directory of the dependent JAR.  Here's a picture to explain what I mean:

[![Application properties starting to proliferate](/img/pic31-300x184.png)](/img/pic31.png)

This problem just got worse as you got more and more descended from a given library -- for example, if jar-A depends on jar-B depends on jar-C and they all ship with their own "*-spring.xml" files we needed to define properties to configure C within jar-B **and** we needed to define properties to configure jar-B and jar-C within jar-A.  It was getting hairy.

To solve this we adopted a new standard that basically amounts to "provide sensible defaults for our sensible defaults": any bean in a "*-spring.xml" snippet that can be configured with a PropertyPlaceholderConfigurer must provide a sensible default for that property.  So a bean definition might have looked like this before:

{% highlight xml %}
<bean name="foo" class="opower.Foo">
  <property name="locale" value="${locale}"/>
</bean>
{% endhighlight %}

After:

{% highlight xml %}
<bean name="foo" class="opower.Foo">
  <property name="locale" value="${locale:en_US}"/>
</bean>
{% endhighlight %}


The defaulting of application properties allowed us to eliminate 90% of the boilerplate test properties and code that we would have otherwise needed and allows for a greater abstraction of thought when a developer decides to pull in a library.  Thus, our current setup looks something like this:

[![Defaulted properties eliminates almost all configuration](/img/pic41-300x150.png)](/img/pic41.png)

A couple of tricks to note when using this model:

  * There's a big difference in classpath context scanning between "classpath:/*-spring.xml" and "classpath*:/*-spring.xml".  The first (with just one star) will pull in all the files that match "*-spring.xml" in the _first_ directory on your classpath that contains any file matching that expression and then stop.  The second version (with classpath\*) will do what you'd expect... it pulls in all files that match "*-spring.xml" from every directory in scans in your classpath.
  * Application property defaulting accepts literals after the colon, so it's safe to do something like `${path:file:///blah}` to default the property to the string `file:///blah`.  You can also change the default string separator in the `PropertyPlaceholderConfigurer` bean so your defaults look more like this: `${path?file:///blah}`  (using a "?" as a separator)
  * It's tempting to eliminate application.properties wherever there's a default, but we avoided that for documentation reasons -- we wanted to provide the implementers and users of our software with a one-stop location to discover and understand the configurability of our applications.  Thus, we adopted a standard that even if an application property is defaulted in a JAR's spring context snippet, we still explicitly declare that property in a WAR's top-level application.property and document how that property affects the system.
