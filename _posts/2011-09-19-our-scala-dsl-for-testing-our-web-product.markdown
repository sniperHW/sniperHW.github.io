---
author: dave.copeland
comments: true
date: 2011-09-19 17:34:57+00:00
layout: post
slug: our-scala-dsl-for-testing-our-web-product
title: Our Scala DSL for testing our web product
wordpress_id: 480
categories:
- Code
- Development
- O-Testing
- Tools
tags:
- dsl
- scala
---


This is actually a fairly old bit of tech for us, but I've been reading [Martin Fowler's DSL Book](http://www.amazon.com/Domain-Specific-Languages-Addison-Wesley-Signature-Fowler/dp/0321712943), and thought it might be good to talk about what we've done.

Our Domain-Specific Language is probably more domain-specific than you might be used to.  Frameworks like Ruby-on-Rails or ScalaTest are DSLs for very broad domains (web-app development and testing, respectively).  Our DSL's domain is _our web product_.  Not any web product, not any Spring app, _our_ web app.  This is important, as it allows us to creating something that is very focused and specific to what we're doing.  In general, the more specific the domain, the more concise and powerful you can make your DSL.

### The domain of application: its architecture

To understand how it works, you need to understand how the appilcation is architected.  While it's a Spring MVC web app, in the general sense, there's a lot more convention around how it's built.  If you've used a "web framework" like Spring MVC, you know that it's really a giant library for responding to HTTP requests at its core, and that it's not very opinionated; it's generally just as easy to do things one way as it is another (check out [this](http://static.springsource.org/spring/docs/3.0.x/javadoc-api/org/springframework/web/bind/annotation/RequestMapping.html) if you disgree).  As such, you need conventions around how to use it. Developers shouldn't spend time asking how to wire up URLs, or where code should go; they should be getting to work and building features.

Our app is built along two main concepts: _pages_, and _modules_.  A Page is made up of one or more modules.  Each module contains a basic bit of information needed to display a page.  Think about websites that say "Hi, Dave!" in the upper corner; that "Hi, Dave" would be controlled by a module.  Each page is backed by a controller whose job it is to expose **only** what's needed to configure the modules on the page. All stateful information (e.g. "who's logged in?") is in these controllers.  Modules, on the other hand, are stateless; they get all the information they need to render from the URL and query parameters.  Modules are made up of two parts: a resource, which identies the data to display, and a view, which renders that data.  A single resource can have many views, and together, they form a module.

This is all glued together via a souped-up version of a `<jsp:include>` tag.  A page jsp-includes a bunch of urls, that happen to be modules, and conform to these conventions.  We have scaffolding scripts to generate the massive boilerplate required to make this happen.

### Testing with Scala

Which brings us to our DSL for testing this stuff.  Essentially, a module's url can be requested and tested independently of any page; we don't need to navigate through the application to test modules, since they are almost entirely stateless (typically, they might require a login, but this a cross-cutting concern).  By requesting the module's URL, and forcing it to render a view, we also get test coverage of our JSP pages, and can push our app to QA with high confidence that all pages will at least render, and that the correct information will be somewhere on the page.

This can all be tested with HTMLUnit, but the tests began to look like bloated assembly-language.  Enter Scala.  I started by writing out the ideal pattern of a test for a module.  Let's consider a module that renders a person's most recent bill.  Suppose we have two views of this module; in the "large" view, we want to see the bill's cost, KWh used, and an account number.  In the "small" view (that we might use on a dashboard page), we want to see just the bill's cost.  How might we test this?

    resource for bill 34 from customer 123:
      requires login as customer 123
      contains "45.67" as the cost
      has a view "small"
      has a view "large"
        that contains "156" as the kwh
        that contains "655321" as the account number

I decided I wanted to write this in code, and have it work.  Not having time to write a parser (or invent a new language), I decided an internal DSL would be the way to go, and that Scala would let me get as close as possible to this:

{% highlight scala %}
resource("/customer/123/bill/34") { resource =>
  resource.requiresLoginAs(customer(123))
  resource.contains("45.67").inElement("div").withId("price")
  resource.hasView("small")
  resource.hasView("large") { view =>
    view.contains("156").inElement("div").withId("kwh")
    view.contains("655321").inElement("div").withId("accountNumber")
  }
}
{% endhighlight %}

This code creates several data structures that our test can now walk through.  Essentially, this will test:

  * That accessing the url without being logged in gets an error
  * That once logged in, requesting a view named "small" will not generate an error
  * That once logged in, requesting a view named "large" will not generate an error
  * That neither view has message properties that are missing their values (we aggresively use message properties to allow localization)
  * That both views contain a div with the id price that contains the text "45.67"
  * That the "large" view also contains a div with id kwh that contains "156" **and** a div with id "accountNumber" that contains "655321"

### Getting fancy

Since this is just Scala code, you can use this to do more sophisticated things:

{% highlight scala %}
case class Bill(cost: Option[String],
                kwh: String,
                accountNumber: String)

Map(
"123" -> (34,Some(Bill(cost = Some("45.67"),
                       kwh = "156",
                       accountNumber = "655321"))),
"876" -> (45,Some(Bill(cost = None,
                       kwh = "156",
                       accountNumber = "655321"))),
"4565" -> (86,None)
).foreach { case(customerId,testData) =>

  val billId,bill = testData

  resource("/customer/" + customerId + "/bill/" + billId) { resource =>
    resource.requiresLoginAs(customer(customerId))

    bill match {
      case Some(bill) => {
        bill.cost match {
          case Some(cost) => resource.contains(bill.cost).
                                      inElement("div").withId("price")
          case None       => resource.shouldNotContainElement("div").
                                      withId("price")
        }
        resource.hasView("small")
        resource.hasView("large") { view =>
          view.contains(bill.kwh).inElement("div").withId("kwh")
          view.contains(bill.accountNumber).inElement("div").
                                            withId("accountNumber")
        }
      }
      case None => {
        resource.containsElement("div").withId("noBill")
      }
    }
  }
}
{% endhighlight %}

I don't know if the developers are totally in love with this DSL, but there's so much you get for free, I'm certain they'd hate testing that by hand even more (or, worse, simply not test some of these things):

  * You never have to remember to check for authentication requirements
  * You never have to remember to check for missing message properties
  * You can dynamically generates tests via test-data (as demonstrated above)
  * Because making a new data structure in Scala is so easy, you can make very fluent tests and test data.

Of course, this DSL is entirely useless to anyone but our web team.  It's tailor-made to test our web product and our web product only.  The win, other than conciseness, readability, and brevity, was that this could be implemented and documented very quickly; I didn't have to make the ultimate web-based tesitng DSL; just one that worked for our product.

If you are considering creating a DSL, keep this in mind: make it exactly right for you, and fight the urge to make it more general.  Also, don't be afraid to use Scala for this; it's much easier than Java, and you can fully type-check and document it very easily.  I should note that I intentionally used very few of Scala's features to do this; developers only need to learn a few new concepts to understand what this code does.
