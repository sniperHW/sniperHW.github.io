---
author: jeff.kolesky
comments: true
date: 2013-03-30 00:10:26+00:00
layout: post
slug: timeshifting-in-hbase
title: Timeshifting in HBase
wordpress_id: 641
categories:
- Code
---

For our HBase table layout, we are following an entity-centric model,
evangelized to us by our friends at [WibiData](http://www.wibidata.com).  The idea is to put all of the
data about a single entity into a single row in HBase.  When you need to run
a computation that involves that entity's data, you have quick access to it by
the row key, and all of the data is stored close together on disk.
Additionally, against many [suggestions](http://www.ngdata.com/site/blog/62-ng.html) from the HBase community,
and general confusion about [how timestamps work](https://issues.apache.org/jira/browse/HBASE-2406), we are using
timestamps with logical values.  Instead of just letting the region server
assign a timestamp version to each cell, we are explicitly setting those values
so that we can use timestamp as a true queryable dimension in our `get`s and
`scan`s.  In addition to the real timeseries data that is indexed using the cell
timestamp, we also have other columns that store metadata about the entity.
That data does not need to be logically timestamped, and we always just want the
most recent version of it.  Given this description, rows in the table look
something like this:





    timestamp    data     metadata
       2013      1.09
       2012      0.87
       2011      0.93     "house"
       2010      1.02
       2009      0.98





This shows a row that has five timeseries values in it and a piece of metadata
that we keep, a label describing where the data came from.  The metadata is
stored at the timestamp when we wrote it into the table, which in this example
is in 2011.  Since we imported historical data, and we use logical timestamps
for the data column, we have data going back to 2009.  One typical access
pattern is to query for all data from the beginning of "last year" up to now,
because we need that much data for many analyses.  If we ran a `get` for this
data, it would normally be set up like this (in pseudo-code, of course):

{% highlight java %}
Get get = new Get(rowkey);
get.addColumn("data");
get.addColumn("metadata");
get.setTimeRange(2012, 2013);
{% endhighlight %}

Unfortunately, that `get` would not return us any data for the metadata column,
because there is no valid cell in that timerange.  We have two options: make
a second `get` for the metadata or figure out some other solution.  That second
solution is timeshifting.





Instead of storing the metadata column with a true server timestamp of when it
was written, we shift the timestamp by 50,000 years which makes the row data now
look like this:





    timestamp    data     metadata
      52011               "house"
       2013      1.09
       2012      0.87
       2011      0.93
       2010      1.02
       2009      0.98





Since we imported the data in 2011 and timeshifted the metadata column
timestamp, its new timestamp is 52,011.  We now change our `get` slightly by
setting an ending timestamp to be the logical "end of time":





{% highlight java %}
Get get = new Get(rowkey);
get.addColumn("data");
get.addColumn("metadata");
get.setTimeRange(2012, Long.MAX_LONG);
{% endhighlight %}





Now, we will get data for the data column and for the metadata column
using only one RPC.  The benefit of HBase being a sparse datastore is that the
data for the metadata column is stored on disk right next to the data for the
data column even though they are logically separated by 50,000 years.
There is no added overhead to the storage to account for this, and thus no added
processing when fetching it.  Furthermore, fetching data for just the metadata column still works
with `Result#getColumnLatest()`.






Yes, there is a problem for the future us of the year 52011, but I'm betting we
will all be using relational databases again by that point.



