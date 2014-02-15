---
author: jeff.kolesky
comments: true
date: 2009-08-24 00:56:52+00:00
layout: post
slug: subversion-branching-good-practice
title: Subversion Branching "Good" Practice
wordpress_id: 18
categories:
- Best Practice
- Code
- Development
tags:
- bash
- branching
- subversion
---

I am relatively new to Subversion -- well, two years into using it now, but this is the first project I have used it on.  Subversion, like any tool, has its quirks and works best when you really know how to use it.  When I started, I treated the "trunk/branches/tags" directory structure exactly like a directory structure.  It took me a little playing around until I stumbled on what I would call a best practice.  When I checkout a new project, I do it like so:

    svn co http://domain.com/svnroot/project/trunk project

That way, when I go to the `project` directory, I do not have to then go into the `trunk` directory to get to my files.  Saving an extra directory level is not the best benefit though.  When I set up my IDE (yes, I use an IDE), I put the IDE files in that one directory and do not have to recreate them for each branch or tag that I might check out.  I essentially treat the "trunk/branches/tags" part of the directory as pure metadata, which makes perfect sense to me.

When I switched over to this system, there was one big drawback.  I could not easily tell where I am just by looking at my prompt.  I had to run `svn info | grep URL` to see if I was on a branch.  So instead of letting my prompt handicap me, I decided to get smart about my prompt.  Using bash, my prompt used to look like this:

    jeff:/opt/pose/main/report/src/main/java

but now it looks like this (supercharged with Subversion metadata):

    jeff:/opt/pose/main/report/src/main/java [SVN: /main/report/trunk]

I'm no bash expert, so I dug around on the web and learned a bit about how `PROMPT_COMMAND` works.  Here is what I have in my `.bash_profile` now:

{% highlight bash %}
function spwd () 
{ 
    stat .svn > /dev/null 2>&1;
    if [ "$?" == "0" ]; then
        SURL=`svn info | grep URL | perl -pe 's/URL: (.*)/\1/'`;
        if [ `echo ${SURL} | grep -E "branches|tags"` ]; then
            SVER=`echo ${SURL} | perl -pe 's{.*/(branches|tags)/(.*)}{\1/\2}' | cut -d/ -f1-2`;
            SPTH=`echo ${SURL} | perl -pe 's{.*svnroot/(.*)/(branches|tags)/.*}{/\1}'`;
            SPWD="${SPTH}/${SVER}";
        else
            SPWD=`echo ${SURL} | perl -pe 's{.*svnroot/(.*)/trunk(.*)}{/\1/trunk}'`;
        fi;
        export PS1="\u:\w [SVN: $SPWD]\n$ ";
    else
        export PS1="\u:\w $ ";
    fi
}
export PROMPT_COMMAND=spwd
{% endhighlight %}

It may not be the most efficient way to do it, but it sure works well and lets me know in an instant what trunk, branch or tag I happen to be working on at that very moment.
