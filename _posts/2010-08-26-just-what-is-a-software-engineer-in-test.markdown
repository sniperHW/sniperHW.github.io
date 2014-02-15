---
author: rob.fagen
comments: true
date: 2010-08-26 23:07:17+00:00
layout: post
slug: just-what-is-a-software-engineer-in-test
title: Just What is A Software Engineer in Test?
wordpress_id: 251
categories:
- Culture
- O-Testing
- Tools
---

OPOWER recently updated the job titles for our QA engineers to more properly reflect the work that we do. We still love owning the responsibility for pointing out when our product hasn't turned out the best it can, and we have all held and loved "QA" titles at many points in our careers. So why the change? Just what exactly is a Software Engineer in Test at OPOWER?

It's pretty clear to just about anyone what the goals of a software engineer are when taken in a development context. Build software that does useful work correctly and efficiently. It's a little more fuzzy when you assess that title from a testing perspective.

  * Is it a tool-smith? Building test frameworks and automation tools for other testers to use? Not exclusively, but tools and frameworks that more junior test engineers can use and learn from are  great side effects of the work.
  * Is it someone who uses GUI testing frameworks to follow along behind the developers and make sure they got the user experience right? Again, a part of the job sometimes, but not the primary mission.
  * Now put on your tinfoil hat. Is it just a conceit meant to soothe the sting of being a second class creator of software artifacts? Someone who can code but not well enough to be a developer? Probably not anyone's explicit intent, but some folks do feel that SEiT is a farm league for the Big Show: being a developer. We are not among those people.

A Software Engineer in Test is someone that builds software that does useful work correctly and efficiently. Wait. That's exactly the same definition as was given for a developer. What gives?

The useful work a developer creates is to render a web page, or process messages, or update a database, all with an end goal of satisfying the end consumer of the application being worked on. When developing test systems, all those same elements are required, but the end goal is providing actionable insight about the quality of the customer facing system. This actionable insight is consumed by the developer and the engineering and product managers. They use this insight to answer questions. Those questions include: is it done, does it work, will it scale, and many others.

The SEiT needs to know how to build robust software, and on top of that, they need to be able to understand the business purpose of the  customer facing system. The SEiT needs to judge what to test, how to test it and when to test it. They also need to have great judgment about what _**not**_ to test.

A fantastic test framework with sub-par tests is of little use. In the same way, an excellent set of tests that cannot be run reliably does not provide the needed insight either. The SEiT needs to be able to go toe-to-toe with any of their developers and question choices on data structures, algorithms and design. They also have to have great judgement about when it best serves the business to take a shortcut in exchange for an acceptable risk.

A great example of dev and test collaborating to make both teams more productive coalesced around how we deal with the concept of "today". When we exercise our software, the result you get depends on what day it is. Different months and days have differing levels of energy usage for both the customer and their neighbors. Without something built into the application, the only way to change "today" is to change the system time, which is not too practical in a shared environment. The ad-hoc and pre-collaboration solution was to add some kind of 'asOf' property to particular logic when we happened to think of it. We tightened up the collaboration level by having test explicitly involved in the estimation, planning and design meetings. Through these discussions earlier in the iteration, we discovered that it is far better to have any code that changes behavior based on the current date to always have the date as a parameter, and any user facing behavior should allow for a seekrit URL parameter (or other test system accessible method) to set the "asOf" date for any particular test. Dev is more productive because they now have a default way of designing the code to make it more testable. Their unit and integration tests are more effective and easier to write. Test is more productive because the app is more testable at the integrated and system level, and their tests are also more effective and easier to write.

It's hard enough to get a software system right. It's even harder to get a system right whose job is making sure another system is correct.  OPOWER certainly doesn't want to hire anyone but the best for that job. For us, the best tester is someone who's a good developer too.
