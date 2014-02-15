---
author: charles.koppelman
comments: true
date: 2009-11-24 17:56:56+00:00
layout: post
slug: locking-screens-on-macs-with-the-keyboard
title: Locking screens on Macs with the keyboard
wordpress_id: 176
categories:
- 'Null'
tags:
- mac quicksilver security
---

Desktop security is a big issue when you have access to massive amounts of data.  As far as plain old terminal security, locking your computer while you're away is a pretty basic rule.

We have lots of OSes around the office here - Ubuntu, Windows, and OSX.  Of those, Ubuntu and Windows natively provide a way to lock your desktop with a keystroke (Win+L or Ctrl+Alt+Del, Enter on Windows and Ctrl+Alt+L on Ubuntu).  Strangely, Mac gives no easy way to lock your desktop.

We've been using HotCorners for the screen saver, but who wants to touch the mouse if you don't have to (especially when you're racing to grab a free lunch)?

Enter [Quicksilver](http://www.macupdate.com/info.php/id/14831), everyone's favorite application interface.  (There are all sorts of things you can do with Quicksilver and its various plug-ins, but you can look that up yourself.) To set up a keyboard shortcut with Quicksilver to lock your screen (hat tip to [Bryan Helmkamp](http://www.brynary.com/2007/4/11/mac-tip-keyboard-shortcut-for-screen-saver)):

  1. Create a symbolic link to your screen saver application:

         $ sudo ln -s /System/Library/Frameworks/ScreenSaver.framework/Versions/\
              Current/Resources/ScreenSaverEngine.app/ \
              /Applications/Screen\ Saver.app

  2. Quicksilver -> Triggers -> Custom Triggers
  3. Add a Hotkey
  4. Find the ScreenSaverEngine by typing and press enter
  5. Double-click the cell in the Trigger column
  6. Choose your hotkey (I like Ctrl+Cmd+\ since it's almost Ctrl+Alt+Del
  7. Close the window (you may also need to restart Quicksilver)

Now set up your System Prefs in Security -> General to require a password immediately after screen saver begins and you're set.

Sadly, you need to do this or your screen saver will awake as soon as you release your Quicksilver shortcut.  This even happens if you set Quicksilver to launch screen saver "On Release".

Anyway, after that, lock screen is just a keystroke away.
