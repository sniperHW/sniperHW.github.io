---
author: dave.copeland
comments: true
date: 2009-11-16 18:07:25+00:00
layout: post
slug: when-adding-more-threads-makes-it-all-slower
title: When adding more threads makes it all slower
wordpress_id: 154
categories:
- Code
tags:
- scaling
- threads
---

I've been working on a new feature that requires analysis of each individual's entire energy-use history.  In other words, I have a process that will touch **every single bit of data** in our database. This should be a rare thing, so if it takes a while, it's not that big of a deal.  My initial implementation was on track to complete in...11 days.

My first thought was: there's lots of blocking reading and writing from the database, so adding some threads should speed things up.  While one thread was analyzing Bob's energy data, another could be fetching Mary's, while another could be updating Joe's meta-data with the results.  Or so I thought.

The more threads I added, the slower the entire thing became.  It turned out that **the fastest implementation was a single-threaded one**.  But why?  It all has to do with the diminishing returns one gets from scaling out.

If you think of a task as having a serial component, which cannot be broken up concurrently, and then multiple tasks which **can** be done concurrently, we can analyze the returns we get by increasing the number of available processors (threads, in my case).  This is [Amdahl's Law](http://en.wikipedia.org/wiki/Amdahl%27s_law) and is exemplified by the following equation (where "x" is the number of processors or threads, and "s" is the percentage of your overall task that must be serialized; "y" is the increase in speed you will see from scaling).
![Amdahl's Equation](/img/amdahl.png)

When you graph this, it's pretty obvious that there are diminishing returns to adding more threads/processors (the graph below assumes that 90% of the overall job can be done concurrently).  As we add threads, we get less and less of a gain in speed.
But there's still a gain to get, so what happened to me?

![Graph of Amdahl's Equation with 10% of our task serialized](/img/Picture-3-300x106.png)

Amdahl's law is actually pretty optimistic.  It doesn't account for the overhead required to synchronize the shared data.  If we account for this, with a new value "k" ( the percentage penalty for maintaining consistency), we see that increasing our processors/threads actually starts to hurt us (this equation is in red)!

![Taking shared state synchronization into account](/img/Coherence-300x105.png)

In my case, almost all of this synchronization is happening within the database; it turns out that almost all the time my process needs is accessing data from the database.  So, I dialed it down to only one thread, and we should be done early next week.
