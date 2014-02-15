---
layout: post
title: How we fork at Opower
author: jeff.kolesky
---

We do not fork open source projects a lot, but when we need to, we do so
with a standard process that ensures we have clean and reproducible builds.
This post describes the process we use and how it has been useful to us.

We only decide to fork a project when we need to stay on the cutting edge.  In
this case,  we still have to protect ourselves from the development cycles of
the open source community.  We have been early adopters of [the Kiji
Project][kiji], and as early adopters, we found bugs that we needed fixed or
features we wanted before the community was ready to promote them.  In these
cases, we forked the projects with the intention to kill off our forks as soon
as all of our changes made their way into the mainline.  Refer to [our
fork][kiji-fork] to see the full example of what is described.

### Fork from a known good build

A key to providing a stable software platform is being able to reproduce an
exact artifact.  To ensure the code we build upon does not change, we start our
build off of a known good build, which in the case of Kiji is a tagged version.
Our version, named [`opower-1.0.2`][kiji-fork] is based on Kiji's mainline tag
[`1.0.2`][kiji-tag].  We do this by creating a branch from the tagged commit.

With the `upstream` remote pointing to the Kiji Project main Git repository, we
fetch the latest code and then create a branch based on the tagged commit as the
start point:

    $ git fetch --tags upstream
    $ git checkout -b opower-1.0.2 kiji-schema-root-1.0.2

### Add fixes as patches

We then create an [`opower`][opower-sub] directory in the root of the project.
Inside is a [directory of patches][patches] and a [script][] used to apply the
patches.  The patches define the changes we want to apply to our fork of the
project.  Each new feature or fix is contained in its own patch so that we can
easily determine what changes we have that are different from the mainline.
While this mimics some of the functionality of a version control system, it is
more straightforward than managing individual commits.  When it comes to
migrating our features to the next tagged version of the project, we simply
create a new branch from the latest tag and copy over the patches that have not
already made it in.  That is much simpler than tracking down commit SHAs and
cherry picking.

### Apply patches during the build

The second item in the [`opower`][opower-sub] directory is a [script][] that applies
the patches.  This script is invoked by our build system, after the code
checkout and before the build begins.  With this script, we ensure the patches
are applied before the code is built and the final artifact is pushed to our
repository.

### Making it real

Once the patches and script are in place, the developer pushes the new branch
and requests a pull request to make it all official.  This process has kept our
forks orderly and allowed us to confidently stay on the cutting edge of a new
project.  All of our patches have been submitted back to the original projects,
but while waiting for the committers to accept them, we have been able to go
about our regularly scheduled releases, confident in the code we are running.


[kiji]: http://kiji.org
[kiji-fork]: https://github.com/opower/kiji-schema/tree/opower-1.0.2
[kiji-tag]: https://github.com/kijiproject/kiji-schema/tree/kiji-schema-root-1.0.2
[opower-sub]: https://github.com/opower/kiji-schema/tree/opower-1.0.2/opower
[patches]: https://github.com/opower/kiji-schema/tree/opower-1.0.2/opower/patches
[script]: https://github.com/opower/kiji-schema/blob/opower-1.0.2/opower/apply-patches.sh
