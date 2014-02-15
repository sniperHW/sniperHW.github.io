---
author: tom.vaughan
comments: true
date: 2012-09-06 20:25:14+00:00
layout: post
slug: upgrading-from-spring-3-0-x-to-spring-3-1-x
title: Upgrading from Spring 3.0.x to Spring 3.1.x
wordpress_id: 600
categories:
- Code
- Spring
---

I recently had the pleasure of upgrading our Java code base from a Spring-3.0.6 base to the latest Spring-3.1.2 libraries.  There were a couple unexpected hiccups I encountered that didn't have a ton of solutions on StackOverflow or the Google, so I thought I'd capture some of them here.

Additionally, it's pretty useful to [look over the method deprecation and removal page](http://static.springsource.org/spring/docs/3.0.6.RELEASE_to_3.1.0.BUILD-SNAPSHOT/changes.html) that the Spring guys published for just this kind of operation.

### Changes to the org.springframework.jdbc.core.simple package

The '.simple' package is deprecated (including the `SimpleJdbcTemplate` class) and there are two new classes you need to know about as you make the transition:

  1. The `org.springframework.jdbc.JdbcTemplate` class is a drop-in replacement for the old `SimpleJdbcTemplate` class, _unless you're using named parameters in your queries._
  2. If you run SQL queries with named parameters through the `JdbcTemplate` your code will compile fine but you'll get odd `Serialization` exceptions or `ArrayIndexOutOfBoundsExceptions`.  For named parameter queries, you'll need to use the `org.springframework.jdbc.namedparam.NamedParameterJdbcTemplate`.


Luckily, the `NamedParameterJdbcTemplate` wraps the new `JdbcTemplate` (well, actually the new `JdbcOperations`) so if you're like Opower and you've got a top level `AbstractJdbcDAO` class that your JdbcDAOs extend from, you can just swap your Abstract class to extend the `NamedParameterJdbcTemplate` and you'll be off to a good start.

### Supporting named parameter queries in Spring-3.1.2

One thing to be aware of is a swap in the argument list to the `.query()` method on the `NamedParameterJdbcTemplate` that used to work with the `SimpleJdbcTemplate`.  Note this signature difference between the `JdbcTemplate` and `NamedParameter` version isn't "new" between Spring 3.0 and 3.1, it's just that you used be able to get away with passing named parameters through the `SimpleJdbcTemplate` and now you can't.  As you're converting to the 3.1 spec, you'll need to correct for that laziness.

Let's say you've got a SQL query containing named parameters and your code used to happily get by with this call to your `SimpleJdbcTemplate`'s `.query` method:

{% highlight java %}
// SQL query with named parameter ( the :zipCodes)
String sql = "SELECT blah FROM foo WHERE zip_code IN (:zipCodes)"

// Our row mapper
RowMapper rowMapper = new ...

// Our parameter Map for named parameter substitution
ImmutableMap paramMap = ImmutableMap.of("zipCodes", zipCodes);

List blah = getSimpleJdbcTemplate().query(sql, rowMapper, paramMap);
{% endhighlight %}

When using the `NamedParameterJdbcTemplate` in Spring-3.1.2 you'll need switch the argument order of your `rowMapper` and your `paramMap`, e.g:

{% highlight java %}
List blah = getNamedParameterJdbcTemplate().query(sql, paramMap, rowMapper);
{% endhighlight %}

If you don't make the switch, your call to a `JdbcTemplate.query(sql, rowMapper, paramMap)` will happily compile because it meets the `JdbcTemplate`'s method signature of

{% highlight java %}
public  List query(String sql, RowMapper rowMapper, Object... args)
    throws DataAccessException
{% endhighlight %}

with the problem being that your `rowMapper` object gets passed in as the one and only varargs substitution variable to whatever "?" or ":foo" named parameter you may have in your query.  Depending on the query you're trying to run you'll get Serialization exceptions or something like this:

{% highlight java %}
Invalid argument value: java.lang.ArrayIndexOutOfBoundsException;
    nested exception is java.sql.SQLException:
        Invalid argument value: java.lang.ArrayIndexOutOfBoundsException
{% endhighlight %}

### Spring-Batch 2.x needs Spring 3.0's deprecated JdbcOperations

If you use Spring Batch's `org.springframework.batch.core.repository.dao.JdbcJobInstanceDao` you'll need to continue to support the deprecated spring-3.0.x `SimpleJdbcTemplate` because that's the only class allowed to be set on the `JdbcJobInstaceDAO` to help it query the DB to look up all the data out of your `BATCH_xxx` tables.  Track [https://jira.springsource.org/browse/BATCH-1685](https://jira.springsource.org/browse/BATCH-1685) for details about when that deprecated requirement goes away.

### Spring Security's AccessDecisionVoter became parameterized

We use Spring Security's `AccessDecisionVoter` to help us authorize (or not) SSO authenticated users.  We used to get away with this Spring-3.0 style implementation:

{% highlight java %}
public class SSOVoter implements AccessDecisionVoter {
...
@Override
public int vote(Authentication authentication, Object object, Collection attributes) {
    // make a decision on authentication based on attributes
...
}
{% endhighlight %}

With the parameterization of the `AccessDecisionVoter`, the new implementation looks like:

{% highlight java %}
public class SSOVoter implements AccessDecisionVoter<Object> {
...
@Override
public int vote(Authentication authentication, Object object, Collection attributes) {
    // make a decision on authentication based on attributes
...
}
{% endhighlight %}

### New abstract method on org.springframework.http.client.ClientHttpResponse

If you use or mock Spring's `ClientHttpResponse` object, there's a new `public int getRawStatusCode() throws IOException` signature you've got to implement.  With access to an `HttpStatus` object, that's pretty straightforward:

{% highlight java %}
@Override
public int getRawStatusCode() throws IOException {
    return this.httpStatus.value();
}
{% endhighlight %}

### Pay attention to your spring context XSD versions

At Opower, we explicitly spell out what XSD versions we pull in to our Spring contexts (instead of just leaving the version off which defaults to the latest published version).  This makes upgrades like this more tedious, and in one case caused some digging to figure out that the Spring tag library we were using for spring-security wasn't compatible with a transitive spring-security dependency being pulled in from spring-security-oauth.  If you get errors like "spring security tag 3.0 library incompatible with class ... blah" make sure:

  1. your Spring context's XSD is pointing to `http://www.springframework.org/schema/security/spring-security-3.1.xsd`
  2. your mvn dependency:tree is pulling in spring-security-3.1

### Spring 3.1 Security's Taglib has a package change.

On first load of one of WARs, our login page greeted me with a fat stack trace starting at "TemplateModelException: Could not load taglib information" and ending at "Caused by: java.lang.ClassNotFoundException: org.springframework.security.taglibs.authz.AuthorizeTag".  The AuthorizeTag class has been renamed to "JspAuthorizeTag", but there are a few minor formatting and documentation differences between the old and new (3.1) taglibs, so I just copied the whole security.tld taglib over top of the one I had in our WEB-INF from spring's fisheye site (google search for "spring security.tld 3.1").

### Spring 3.1 may mean an update to your OAuth dependency

Several of Opower's web apps leverage OAuth for aspects of our security.  When upgrading to spring-security 3.1, some problems will crop up if you're using ant-style filter chain maps in your `FilterChainProxy`.  For example, one of our `securityContext.xml` files contained this snippet:

{% highlight xml %}
xsi:schemaLocation="http://www.springframework.org/schema/beans
http://www.springframework.org/schema/beans/spring-beans-3.1.xsd
http://www.springframework.org/schema/security
http://www.springframework.org/schema/security/spring-security-3.1.xsd
http://www.springframework.org/schema/security/oauth
http://www.springframework.org/schema/security/spring-security-oauth.xsd"
default-autowire="byName">
...snip...
  <bean id="filterChainProxy" class="org.springframework.security.web.FilterChainProxy">
  <sec:filter-chain-map path-type="ant">
...snip...
{% endhighlight %}

When spinning up that context, I'd get an error: "java.lang.ClassNotFoundException: org.springframework.security.web.util.AntUrlPathMatcher."  Sure enough, there was no `AntUrlPathMatcher` in my spring-security-web-3.1.2 JAR on the classpath.  Fixing this necessitated an upgrade of our spring-security-oauth JAR from 1.0.0.M2 to 1.0.0.M6

Upgrading to the 1.0.0.M6 version of the spring-security-oauth JAR caused some of its own problems which ended up just being another package change (the `ProtectedResourceProcessingFilter` class ended up moving from `org.springframework.security.oauth.provider` to `org.springframework.security.oauth.provider.filter`).
