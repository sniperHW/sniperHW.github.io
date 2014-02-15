---
author: tom.vaughan
comments: true
date: 2010-04-30 21:57:25+00:00
layout: post
slug: alfresco-3-3-lunch-learn
title: Alfresco 3.3 Lunch & Learn
wordpress_id: 201
categories:
- Code
- Tools
tags:
- Alfresco
- Content Management
---

I attended the Reston, VA "Alfresco 3.3 lunch & learn" seminar this week, hosted by the generous folks over at [SiteWorx](http://www.siteworx.com/).  I have a couple years as "CMS guru" at some previous jobs, so in addition to being interested in the field, I'm also the support guy in-house for our CMS needs.

We here at OPOWER use Alfresco Community 3.2 as a glorified "XML editing tool" that was easy to setup, configure and hand over to the business to allow them to contribute XML-based content that our applications can consume.  As a F/LOSS solution, it's fit our needs pretty well and is generally a low-maintenance piece of our infrastructure.

I attribute my "low maintenance" characterization of an Alfresco installation mostly to the patience of my small user base, who are very accommodating to the quirks and limitations of the installed (and neglected) instance.

The 3.3 lunch and learn was intro'd by Chris from SiteWorx who surveyed the CMS landscape and equated the emerging CMIS spec as "content's ODBC" which I thought to be a quite fitting analogy.

Richard Im from Alfresco then spoke for about 45 minutes about the new features Alfresco 3.3 contained:

### WCM Improvements

  * new web-based editor, reminiscent of Interwoven's in-context editor from the 6.5/7.0 era
  * new bi-directional deployment capabilities (including addition of "delivery server" infrastructure possibilities like several other CMS offerings)
  * "Straight through" publishing without workflows
  * google-like search on metadata attributes

### Share

  * Evolving share into more of a bit-for-bit replacement of the "traditional" UI (which Richard referred to as "DM"... "document manager?")
  * Permission control a la DM
  * Rules and Actions just like in DM
  * Data Lists (like Share Point's project lists)


I asked the question: "what's the medium-term road map for DM, if Alfresco seems intent on mirroring all(?) functionality in the traditional UI via the /share context?"  Richard wouldn't definitively say that the traditional app is going to be deprecated any time soon, but it certainly appears that way...

### "Integration" improvements

I think this suite of improvements is geared towards the enterprise crowd:

  * Full CMIS 1.0 spec implemented as of 3.3 (the only open source implementation known to do so)
  * ACLs
  * Change Logs
  * Additional SOA/REST services and support
  * Ability to save off google docs in alfresco for management (!)


My big take-aways from the lunch and Q&A session was that Alfresco's 3.3 feature list and 3.4 direction seem to put them on more of a competitive footing with monster ECM vendors like Interwoven.  It's maybe an odd direction for an open source project to steer because while Alfresco certainly employs their own development team, I'm not sure how much community interest there is in contributing to some of the more mundane enterprise ECM concerns that need to be built or integrated.  On the other hand, Alfresco, Inc. does survive with enterprise support contracts that smaller shops like mine are unlikely to ever pay top-dollar for, so maybe it's a long term survival strategy.

Long term, I'm interested in exploring architectures available to us with a SOA-enabled CMIS layer and eventually ditch the custom-DAO layer we're running right now against Alfresco-exported XML flat files.  Even if that never happens, it's exciting to see the kinds of complexity that open source projects are able to attack.
