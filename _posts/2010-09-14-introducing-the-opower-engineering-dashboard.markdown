---
author: joel.strait
comments: true
date: 2010-09-14 21:30:23+00:00
layout: post
slug: introducing-the-opower-engineering-dashboard
title: Introducing the OPOWER Engineering Dashboard
wordpress_id: 267
categories:
- Tools
---

As Tom [mentioned]({% post_url 2010-07-27-maven-izing-googles-data-client-java-library %}), we recently conducted our first company-wide Innovation Day. Everyone split into groups of 3-4 and worked on whatever they wanted (as long as it was related to the company).

Everyone did cool stuff. One group made a prototype of a website where you can enter your zip code, info about your home, and your last energy bill, and (via our Insight Engine) see how you compare to similar people across the country. Another group made an iPhone optimized version of our utility website. A third group went out and bought some plants to liven up the office.

Adam, Jeff #3, Matt and I decided to focus our attention towards the TV we have mounted on the wall. It's been dormant since the World Cup, and we wanted to put it to better use. [Inspired by Panic](http://www.panic.com/blog/2010/03/the-panic-status-board/), we decided to build a dashboard for the engineering team.

We brainstormed beforehand, and came up with a lot of ideas. However, to make sure we had something working to demo the next day, we decided to just focus on getting 1 or 2 small things done as a proof of concept. We first set up a simple [Sinatra](http://www.sinatrarb.com/) Ruby app to act as a shell. Next Matt, Jeff and I worked on pulling data from various APIs ([JIRA](http://docs.codehaus.org/display/JIRA4R/Examples), [Google Calendar](http://cookingandcoding.com/gcal4ruby/), Hudson, etc.) while Adam built a killer grid-based design.

This turned out to be setting the bar way too low - 10 hours of non-stop coding later, we managed to have a working dashboard that displays the following:

  * How much time is left in the current iteration.
  * The number of story points each team has completed for the current iteration, and how many more are left. ![Dashboard story points](/img/story_points-300x189.png)
  * The status of our Hudson continuous integration server. If someone breaks the build, the dashboard bursts into flames.
  * Any urgent production issues. (Once again, burning).
  * The X-Train Wall of Shame. It tracks how many times everyone has broken the build, as well as how many times they have atoned for it by buying everyone a drink. ![The X train cometh](/img/x_train-300x176.png)
  * Who is on vacation, and who will be on vacation soon. (Courtesy of Google Calendar). ![Slackers on vacation](/img/vacation-300x246.png)
  * When the next trains are coming to the Courthouse Metro station. ![Trains at Courthouse](/img/metro.png)
  * A Twitter feed of tweets mentioning OPOWER.
  * Random selections from the company quote wall.

We've been using the dashboard for about an iteration now, and it's been a big success. It gives everyone (including people outside of engineering) an easy way to see where we are. Since the TV is mounted along one of the main office thoroughfares, people are always stopping to check it out throughout the day.

![The OPOWER Engineering Dashboard](/img/engineering_dashboard-300x221.jpg)

This was one of the most fun things I've ever done at work. Looking forward to the next Innovation Day!
