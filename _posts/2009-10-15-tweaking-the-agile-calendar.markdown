---
author: tom.vaughan
comments: true
date: 2009-10-15 16:24:57+00:00
layout: post
slug: tweaking-the-agile-calendar
title: Tweaking the Agile Calendar
wordpress_id: 100
categories:
- Development
- Workflow
---

For the first five iterations, the dev team had been following this schedule:

  * Iteration N, Week 1 = Design for iteration N and 2nd week of QA for iteration N - 1
  * Iteration N, Week 2 = Development
  * Iteration N, Week 3 = Development
  * Iteration N, Week 4 = 1st week of QA for iteration N
  * Iteration N, Week 5 / Iteration N + 1, Week 1 = 2nd week of QA for iteration N, design for iteration N + 1

We started to notice a couple things that have caused us to try out a new schedule in our upcoming 6th iteration.

First, we realized that we left very little time for fit to hit the shan.  If we had a tough QA cycle, we didn't design enough.  If we didn't design enough, we underestimated how much development would be needed (i.e. too many story points).  If we had too many story points, we'd go in to QA late.  And the cycle repeats.

Note that many of you Agile purists out there will cringe at the above description, especially this sentence: "If we had too many story points, we'd go in to QA late."

I know.  We cringed too.

We're committing to a couple new explicit practices going in to our next iterations:

  1. More formal velocity check-ins.  If less than 50% of our story points are closed by COB of the first Friday, we should have a come-to-jeebus meeting on Monday morning.
  2. We absolutely need to respect the impact that dedicated design time has on the effectiveness of everything down-stream.  It's too easy to say "Agile" as a synonym for "code by the seat of your pants," but that's not what it's about and we know that.  We just need to get better at dedicating time to it.

So with those ideas in mind, we're moving to something like the following:

![iteration_detail_screenprint_cropped](/img/iteration_detail_screenprint_cropped.png)

It's a five-week iteration, with 2 solid weeks built in for QA and 1 dedicated week of design.

I think if we can get to a point where our regression and automation testing is good enough (and we develop enough confidence our automated tests), that we may be able to get back to a 4 week cycle.  In the mean time, we're going to see if we can actually go faster by slowing down.

Stay tuned!
