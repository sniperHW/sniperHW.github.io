---
author: jeff.kolesky
comments: true
date: 2010-10-07 12:39:54+00:00
layout: post
slug: opower-engineering-principles
title: OPOWER Engineering Principles
wordpress_id: 368
categories:
- Culture
---

We are engineers.  Not programmers, developers, or coders; and certainly not hackers.  The distinction is important, because we are building a system for the long haul, not just a class or script or even an application.  It is our responsibility to keep the entire operating environment in mind as we think about what we build, because we must consider all components of the system in order to build it to sustain the life of the business.  Hackers do not do this type of work.  Engineers do.  We are engineers.

As engineers our core principles include

  * Thinking
  * Testing
  * Improving
  * Tooling

### Thinking

All projects need a certain amount of forethought put into them before code hits the screen.  In fact all need just the right amount.  As engineers, it is our responsibility to determine how much thought is needed and how to best communicate the output of that thought.  We rely on the maturity, discipline, and experience of our team to make the right decisions every day, balancing purity of design with what is most practical.  We should not expect to get a design wrong the first time, nor should we expect to get it right.  Rather we should expect to get it pointing in the right direction.  We do not create throw away designs that we expect to refactor later.  That is a flawed philosophy that allows people to design on the fly while coding.  We create designs that lay a a foundation for future functionality.  Our designs are informed by the past, focus on the present, and keep an eye on the future.

### Testing

Quality of our product is very important, because our products affect millions of people daily.  As such, testing is baked into our philosophy and methodology from the start.  We do not necessarily employ test-driven development, but we start writing test specs when we begin a story.  All team members are responsible for quality, and all are responsible for writing tests: unit, integration, and regression -- whatever is appropriate for the feature.  When a bug is discovered, a test is written to reproduce the bug before code is changed to fix it.  This is the best way to ensure the bug does not creep back in later.  As much as possible, tests are fully automated and run with each continuous integration build.

### Improving

Continuous integration is old hat now.  People are talking about continuous deployment more and more.  We believe in continuous improvement and are on a constant mission to better our process, designs, code and knowledge.  For process, we run post-mortem reviews after each iteration, cataloging what worked well and what did not, resulting in suggestions of ways to change.  Since we are wedded only to what works, we can adapt until we find the right thing.  For designs and code, we run group reviews on a weekly basis, allowing for anyone to present a design or code sample for review by his or her peers.  These meetings are when we solidify our standards and conventions as well as informally teach good design thinking and share knowledge of the frameworks and tools we use to make our team more efficient.  Increasing individuals' knowledge is a more self-directed activity; we rely on the team to investigate and research topics they are interested in and will support them through book purchases, course reimbursement and conference sponsorship.  To support our efforts at continuous improvement, we also follow a practice of continuous feedback.  In addition to formal performance evaluations, we collect short bits of feedback ("tweets" if you will) after each iteration to make sure all team members know where they are doing well and how they can improve.

### Tooling

We choose the right tools for the job.  This is as much an imperative to consider legacy and the team's skills as it is to push the boundaries with new tools at our disposal.  The important aspect of this tenet is that any tool must be the right tool, which means its appropriateness must be evaluated before it is used.  We do not start using the latest tool just because it is new -- we use it because it solves a problem we have in a way better than any current tool without creating new bigger problems.  This is not an "if you have a hammer" kind of philosophy, but more along the lines of choosing the right size hammer for the job.
