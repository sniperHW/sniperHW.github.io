---
author: rob.fagen
comments: true
date: 2010-09-07 17:57:24+00:00
layout: post
slug: picking-up-your-mac-os-environment-in-rubymine
title: Picking up your Mac OS environment in RubyMine
wordpress_id: 294
categories:
- O-Testing
- Tools
---

Many of us are using [RubyMine](http://www.jetbrains.com/ruby/) on MacOS to build our [Cucumber based tests](http://cukes.info/), and have had issues with picking up environment variables needed for working with some of our other internal utilities. Turns out that this is because applications launched from anywhere other than the command line don't run through the same environment initialization as when you launch a shell. There are two possible solutions that I know of:

1. First launch a shell that you know has the environment variables you want already set, then:

        cd /Applications/RubyMine 2.0.2.app/Contents/MacOS
        ./rubymine

2. Follow [these (untested) directions](http://www.digitaledgesw.com/node/31). In summary, you would add commands like `setenv VARIABLE_NAME variable_value` in `/etc/launchd.conf` -- the downside is that you have to reboot after making changes, so this doesn't help if the environment variables you need are somewhat dynamic.
