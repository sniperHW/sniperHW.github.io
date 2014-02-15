---
author: ed.peters
comments: true
date: 2012-04-12 15:51:29+00:00
layout: post
slug: whos-inhabiting-your-code
title: Who's Inhabiting Your Code?
wordpress_id: 572
categories:
- Best Practice
---

Lately I've been thinking about the notion of "beautiful code", and finding it to be less and less satisfying as a goal.  First off, beauty is elusive: everyone seems to have a different concept of what it means (and except for mine, they're all wrong).  And second, even when you can label a piece of code as "beautiful", it's not at all clear how that translates into other desirable characteristics like performance, maintainability, and so forth.

In my reading, I came across a great article by Rebecca Wirfs-Brock[^1] in which she discusses the notion of "habitable code".  This idea isn't original to her (she credits Richard Gabriel in Patterns of Software[^2]), but she provides a great explanation of the concept, and goes on to talk about its role in complex systems.

Paraphrasing some key points ...




  * _Clarity for its own sake is an elusive goal_.  In my own experience, if I strive really hard to make some aspect of my code crystal clear (say, a challenging algorithm or data structure), it's at the expense of clarity in some other area. It's a bit like a game of [Whac-A-Mole](http://en.wikipedia.org/wiki/Whac-A-Mole).  Just as you can't write code that's infinitely flexible in the face of unknown future requirements, I don't think you can write code that's infinitely clear to an unknown future audience.


  * _Beauty becomes a constraint for future authors_.  It's hard to extend or update excessively beautiful code without spoiling some of its inherent loveliness.  An analogy to industrial design -- the MacBook Air achieves a certain level of elegance by ruthlessly eliminating functionality like replaceable batteries, integrated Ethernet or a DVD drive.  How difficult would it be to add that stuff in later without compromising the original aesthetic?  Probably very.


  * _Habitable code makes its structure and intentions easy to understand_.  Structure, sure, but as a professional developer, the "and intentions" part seems pretty important.  You can read code to understand what it's doing, but it's not always obvious what problem the original author thought it was solving.  This is a hard thing to do right -- the best I've been able to do is document the problem being solved, and make the structure of the code appropriate to the solution.  Code reviews are a huge help in identifying areas that need improvement in either direction.


  * _Habitable code makes developers feel at home_.  At [Opower](http://www.opower.com) we have a pretty good-sized body of coding conventions, some of which are automatically enforced using tools like Checkstyle and PMD.  To new hires, it sometimes seems totalitarian (it did to me). But once you've been around awhile, you notice a funny thing: you can go almost anywhere in our source base and see things done in a similar fashion.  This helps us transition from artifact to artifact more easily, and reduces the overhead in sharing code. Habitable, indeed.


Just like any other principles, these can be reduced to absurdity.  Giving up completely on clarity is obviously not the answer, nor is making your code horribly ugly so that future maintainers don't feel bad about rewriting it.  But it's interesting to think about where habitability differs from clarity and beauty, and what it demands of us as developers.

So ... who's inhabiting your code today?  Whose code are you inhabiting?  How is that going to change in a month?  Six months?  A year?  And what are you doing to make each other feel welcome and at home?


[^1]: [Does Beautiful Code Imply Beautiful Design](http://www.wirfs-brock.com/PDFs/DoesBeautifulCodeImply.pdf) by Rebecca Wirfs-Brock.
[^2]: [Patterns of Software: Tales from the Software Community](http://dreamsongs.net/Files/PatternsOfSoftware.pdf) by Richard P. Gabriel.
