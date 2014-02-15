---
author: dave.copeland
comments: true
date: 2009-08-19 15:00:47+00:00
layout: post
slug: measuring-our-awesomeness-iteration-by-iteration
title: Measuring our awesomeness iteration by iteration
wordpress_id: 4
categories:
- Code
- Development
tags:
- process improvment
- qa
- ruby
- sinatra
- testing
---


Like a lot of startups (and big companies!) we use iterative development: we break up our work into "stories" describing features and implement as many as we can in one month.  We then repeat that until we conquer the world.  But, if we can do more, or work more efficiently with each iteration, our goal of world domination will approach that much quicker. :)






The easiest way to do that is to look at the bugs our QA staff find in the product updates.  Although we have a lot of automated tests, we still need some eyes on the applications to check for things like text overruns of our printed reports, or JavaScript weirdness in some [less-than-well-behaved](http://blog.digg.com/?p=878)) browsers.






After a few iterations, Anh (our beloved program manager) ran some queries on our bug-tracking database and, using some Excel magic, showed us numbers like "number of defects in the web application" and "average number of days a critical bug sat unassigned".  This is good stuff; seeing hard data about what we're doing lets us focus on inefficiency.  Since we release software every month (and launch new clients almost as frequently), this is a **huge** help in making each iteration better than the previous.






While Anh's hand-jammed report was awesome, manually connecting SQLite and Excel is no fun for anyone.  I whipped up a basic Ruby application using [Sinatra](http://www.sinatrarb.com/) to automate most of what we'd like to see.  We can now see how long critical defects site open and unfixed, as well as how many overall defects we're fixing and even the _root source_ of our defects (i.e. did we get the wrong requirements, or just mess up implementing them?)






We still need to show trends, however.  "Classic" thinking in software process improvement says to do that by dividing everything by lines of code; if we had 10 defects per 1,000 lines of code this month, but only 8 the following, we're doing better.  This is not a great measure for us, since we are changing and enhancing our product (as opposed to writing fresh code each time), so we decided to normalize our measurements by the story points we assigned to the iteration.  This way, we can see charts like the one below (which says we are doing better each time):



![Metrics Chart](/img/MetricsChart.png)



This information is dead simple to collect; the burden on developers and testers when writing defects is almost nothing.  With only a priority, severity, and "source of defect", we can collect a lot of advanced information about our development process -- and make it better iteration by iteration.




