---
author: tom.vaughan
comments: true
date: 2010-07-26 20:13:49+00:00
layout: post
slug: heisenbergs-key-performance-indicators
title: Heisenberg's Key Performance Indicators
wordpress_id: 228
categories:
- Development
- Product
---

![A picture of Heisenberg.](/img/Heisenberg.jpg)

I was trolling trawling through reddit waiting for a JAR to compile and [found this blog post](http://nerds-central.blogspot.com/2010/07/development-management-act-of.html).  That blog made a couple claims that had crossed my mind a couple months ago when our engineering director solicited  feedback about using Key Performance Indicators for the dev team.  The blog post's point wasn't so much that the _act _of measuring a team changes its performance but rather that when the team is aware of what's being measured, it naturally "cheats" in ways to maximize the measured value.  The first comment on the blog post alerted me to a law I hadn't known about, but which sounds pretty intuitively correct:

[Goodhart's Law](http://en.wikipedia.org/wiki/Goodhart%27s_law): _Any observed statistical regularity will tend to collapse once pressure is placed upon it for control purposes_

Here at OPOWER, developers and product managers don't deal with KPIs on a day-to-day basis. I think it's mostly a management-level "let's starting capturing some numbers over several months and see if there's anything out-of-whack" kind of thing.

In terms of development KPIs, some of the things we thought it might be interesting to collect included:

  * story points delivered per iteration
  * % of story points (aggregate) done in an iteration that were planned at the beginning
  * % QA coverage of production (automated)
  * etc.

The "story points delivered per iteration" is, I think, precisely the kind of thing Goodhart was talking about when he made up his law.  _That said_, we are a business and we are expected to work and be productive, so it isn't exactly a satisfying for a VP or CEO to hear from their dev team "sorry, you can't measure us because we'll just skew the measurement number to please you."  So what's management to do with their IT cabal?

_Assuming_ you could normalize what story points mean across different teams, and _assuming_ you can account for "point inflation" and _assuming_ you accurately tracked vacations and network outages and late requirements and all the other stuff that goes along with uncertainty in exactly how much gets delivered in an iteration, must you also assume that the team gradually skews the number to meet the goal?  What if the goal was kept secret?  What if the team didn't know they were being measured?  That's hardly a way to foster a healthy relationship between management and product development.

![A picture of Walt from Breaking Bad](/img/heisenberg_bb.jpg)

One way around this dilemma is to find some totally objective metric in the software engineering process.  In other words, if you could apply KPIs to "number of sprockets coming off the assembly line such that each sprocket is within .1% tolerance," what is a similar kind of thing in our iteration process we could measure?  I.e., one that doesn't easily fall prey to inflation or manipulation?  If you can find something like that, lemme know.  Until then, I won't be holding my breath.

Another possible option would be to go ahead and publicly measure highly subjective KPIs anyway and ask the measurees (us) to be as objective as possible when measuring.  I.e., fly in the face of Goodhart's Law.  After all, it's just a Law.  Like De Morgan's Law, except maybe with a bit more wiggle room.
