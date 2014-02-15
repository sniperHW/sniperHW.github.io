---
author:
- alexandre.normand
- jeff.kolesky
layout: post
title: The Big Data Elders, Archeology Hour
---
After all that's been written about the [ancient Big Data elders]({% post_url 2013-07-07-the-story-of-the-big-data-elders %})
and their artful discoveries, it seems appropriate to now lift the curtain and
reveal the modern, specific, and, sometimes dirty, details.

Before we do, let's get something out in the open right now: working at
[Opower](http://opower.com) is pretty great. We get to make an impact on this
 world, using fancy and effective behavioral science while working with cool
 and exciting tech. Awesome, right?

### A brief history of data storage at Opower
We have been using MySQL as our main database since day one.  It has been good
to us, and we have figured out how to scale it well enough.  But as our
business has grown, so have our data storage needs.  Each of our utility
company clients gives us historical energy data for their customers, and we
store it indefinitely.  For utility companies that have smart meters
installed, we store energy reads that occur every 15 minutes, hour, or day.
For a meter with 15 minute resolution, we store 3000 times as much data as a
standard meter that is read once a month.

As more and more utility companies install smart meters, we ingest more and
more of this higher resolution data, which comes in more frequently than
standard monthly data.  Those last two characteristics hit on two of the
"[three V’s](http://whatis.techtarget.com/definition/3Vs)" that define "Big
Data": volume and velocity.  As we have collected the smart meter data over
the last several years, we have figured out innovative ways to use it, and we
want to accelerate our learning using the data.  To achieve that, we needed a
system better suited to processing large amounts of data, and that is where
Hadoop and HBase fit in.

We have a business case that fits HBase perfectly, because we need to perform
large batch calculations (running a disaggregation of A/C usage from your
energy data, for instance), and we need to serve up the results of those
calculations with low latency.  HBase gives us the perfect mix of those two
access patterns, and we have spent the last year working on our new storage
system to do exactly this.

### Using it is one thing, showing it is another
All of this fancy Big Data is pretty amazing, but it's also not very sexy to
the untrained eye. After several low-level demos making use of the terminal,
logs and job tracker UI, we decided it was time to try a little harder. Let's
ponder: what can we show to illustrate the fact that we process and store all
of this energy data without breaking a sweat?

#### Table size
Showing table size is an obvious one. People understand what a terabyte
represents (at the very least, they know it's bigger than their inbox).

For the demo, we gathered the table size data while our big test was running.
We built a simple command-line tool that polls hdfs for the size of each
table's directory. It keeps track of the sizes and outputs a json time series
when the tool shuts down. It's designed to run from a gateway node that can
run the hadoop command and run `hadoop fs du` on hdfs.

Source: [giant-squash](https://github.com/opower/giant-squash)

#### Job progress
Showing the tables growing is interesting but it doesn't show all the work
that's done in Hadoop to get this data in HBase. Let's add the job progress
and input/output sizes.

This is very similar to [giant-squash](https://github.com/opower/giant-squash)
except that it collects data from the job tracker on the jobs that are running
on the cluster. It also collects the data in-memory and dumps a json time
series of the input/output sizes as well as map/reduce progress on exit.

Source: [little-rabbit](https://github.com/opower/little-rabbit)

#### Putting it together
Now that we've got the data collected and our test is complete, let's animate
it in fast-motion.

Based on this nice d3.js [Motion Chart](http://bost.ocks.org/mike/nations/)
demo, we created our version to animate the time series data. It reads the two
json dumps and merges this in one visualization. Granted, it violates some of
the [principles of data information visualization](http://moz.com/blog/data-visualization-principles-lessons-from-tufte)
but it does make for a cool presentation and it gets people interested enough to
ask questions about it.

Source: [bloom-harvester](https://github.com/opower/bloom-harvester)

#### Hollywood production
Finally we wrapped it in with a nice summary of the digestible numbers and a
nice soundtrack and voilà.

Where are the explosions I hear you say? Well, maybe next time. After all,
this is going to production in just a few weeks.
