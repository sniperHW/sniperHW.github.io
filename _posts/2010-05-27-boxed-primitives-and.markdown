---
author: dave.copeland
comments: true
date: 2010-05-27 18:25:06+00:00
layout: post
slug: boxed-primitives-and
title: Boxed primitives and ==
wordpress_id: 215
categories:
- Best Practice
- Code
- Culture
---

One part of programming culture at OPOWER is to program defensively, providing useful information when contracts are violated.   What does this have to do with boxed primitives?  Getting an assertion message of "Person 1001's customer id 109032 didn't match the passed-in customer's id of 109032" seemed logically impossible, but was somehow true.

But first, let's talk about defensive coding and how we do it.  For example:

{% highlight java %}
/**
 * frobs the bar and baz.
 * @param bar the bar to frob; may not be null
 * @param baz the baz to from; must be positive
 */
public String frob(String bar, int baz) {
  if (bar.length() > baz) {
    return bar.substring(baz);
  }
  else {
    return bar;
  }
}
{% endhighlight %}


If the contract is violated by the caller, we will get a `NullPointerException` or some other `StringIndexOutOfBoundsException`.  Not too helpful.  Instead, we use an internal validator helper class to provide useful messages.  This is **crucial** for properly understanding bugs that occur in production; there's nothing worse than coming into work to find a `NullPointerException` in your inbox and no clue what went wrong.


{% highlight java %}
/**
 * frobs the bar and baz.
 * @param bar the bar to frob; may not be null
 * @param baz the baz to from; must be positive
 */
public String frob(String bar, int baz) {
  Validate.notNull(bar,"bar must not be null to frob");
  Validate.isTrue(baz > 0,"baz must be positive");
  if (bar.length() > baz) {
    return bar.substring(baz);
  }
  else {
    return bar;
  }
}
{% endhighlight %}


`Validate.*` methods essentially throw `IllegalArgumentException` if what they are checking for fails.
We use this pattern extensively, even in constructors of simple data-structure style objects.  This (plus keeping this things immutable) allows users of these objects to safely rely upon the `get` methods behaving properly. I had need of a class to hold both a `Person` (representing a website user) and a `Customer` (representing a utility-company customer).  This class (called, naturally, `PersonAndCustomer`), takes both objects in its constructor and requires that they are both non-null.  As a further sanity check, I wanted to make sure that the `Person`'s `customerId` matched the id of the `Customer` that was being passed in (i.e. that they represented the same actual human in the real world):


{% highlight java %}
public PersonAndCustomer(Person p, Customer c) {
  Validate.notNull(p,"Person may not be null");
  Validate.notNull(c,"Customer may not be null");
  Validate.isTrue(p.getCustomerId() == c.getId(),
    "Person %d's customer id %d didn't match passed-in customer's id %d",
    p.getId(),
    p.getCustomerId(),
    c.getId());
  ...
}
{% endhighlight %}


Looks pretty inocuous, right?  Well, because these objects are Hibernate-managed, all of our ids are `Long` and not `long`.  So, my `isTrue` validation is really checking that the person's `customerId` _object_ is the _same object_ as the customer's `id` object.  What's worse, in several months of development and production deployment, these two objects _happened to be the same_.

Until this week; we were testing our application for a new client and I got the error posted above ("Person 1001's customer id 109032 didn't match the passed-in customer's id of 109032").  It seems that much like how the JVM will re-use string objects, it also will sometimes re-use boxed objects as well.  But not always.  The fix for this is obvious, but I wanted to make sure I could actually recreate this situation.  So, I created a test that gave both the `Person` and `Customer` the same _value_ for the customer id, but as different objects. and verified that the class could still be constructed.  Sure enough, the test failed.  The fix:


{% highlight java %}
public PersonAndCustomer(Person p, Customer c) {
  Validate.notNull(p,"Person may not be null");
  Validate.notNull(c,"Customer may not be null");
  Validate.isTrue(p.getCustomerId().equals(c.getId()),
    "Person %d's customer id %d didn't match passed-in customer's id %d",
    p.getId(),
    p.getCustomerId(),
    c.getId());
  ...
}
{% endhighlight %}

What's interesting is that if one end of the `==` is a primitive, the JVM will unbox the other one and the test succeeds:


{% highlight java %}
Long l1 = new Long(45L);
Long l2 = new Long(45L);

System.out.println(l1 == l2);      // false
System.out.println(l1.equals(l2)); // true
System.out.println(l1 == 45L);     // true!
{% endhighlight %}

The moral of the story is to always know what you are comparing.  Might even be best to always use `.equals()` unless the compiler complains.

