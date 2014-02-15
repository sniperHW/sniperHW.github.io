---
author: tom.vaughan
comments: true
date: 2009-08-26 14:06:25+00:00
layout: post
slug: new-developer-law
title: New Developer Law
wordpress_id: 34
categories:
- Best Practice
- Code
- Development
---

NEW LAW FOR DEVELOPERS:

_If you throw an exception about some connection being refused, you'd better damn well put what connection you were attempting to make in the exception message._

What inspired this law?  Thanks for asking.

Check out this snippet in the middle of an 80 line stack dump:

 
    2009-08-25 17:23:42.373::WARN:  Nested in org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'coreAutopatcher' defined in class path resource [config/migrationContext.xml]: Invocation of init method failed; nested exception is com.tacitknowledge.util.migration.MigrationException: Error applying patches:
    com.mchange.v2.resourcepool.CannotAcquireResourceException: A ResourcePool could not acquire a resource from its primary factory or source.
    at com.mchange.v2.resourcepool.BasicResourcePool.awaitAvailable(BasicResourcePool.java:1319)
    at com.mchange.v2.resourcepool.BasicResourcePool.prelimCheckoutResource(BasicResourcePool.java:557)
    at com.mchange.v2.resourcepool.BasicResourcePool.checkoutResource(BasicResourcePool.java:477)
    at com.mchange.v2.c3p0.impl.C3P0PooledConnectionPool.checkoutPooledConnection(C3P0PooledConnectionPool.java:525)


"A ResourcePool could not acquire a resource from its primary factory or source".  Awesome.  Sooo helpful.  /wristsemoragegrowl

Also, a WARN?  Seriously?  You're a connection pool.  Do you think not connecting to your underlying datasource warrants maybe something as stern as an ERROR?  Or, heaven forbid, a FATAL?

I'm sure I could have turned up logging somewhere, but I noticed Spring's DelegatingDataSource bean standing out from among the stack lines and set a break point on its called method to figure out exactly which of my many connections was unable to be resolved:

![what_am_i_connecting_to](/img/what_am_i_connecting_to.png)

There's the culprit!  `localhost:5455`.  You know, whoever the idiot is who runs that localhost server needs to get his act together.  I should call the guys from YouTube and have them do a Maury Povich-style video expose on why he can't keep any of his connections stable.
