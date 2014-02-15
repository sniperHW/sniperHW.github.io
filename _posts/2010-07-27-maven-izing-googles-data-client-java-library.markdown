---
author: tom.vaughan
comments: true
date: 2010-07-27 20:09:14+00:00
layout: post
slug: maven-izing-googles-data-client-java-library
title: Maven-izing Google's Data Client Java Library
wordpress_id: 238
categories:
- Development
- Maven
---

OPOWER's first Innovation Day was a lot of fun.  I was waiting about 30 minutes for my primary project (building an AWS machine image for our Hudson slave) to complete and I got sucked in to a different project involving automatically downloading Google Analytics for all the traffic on all the websites we host for our clients.

Clicking around Google's well-documented "get started" guides, it looked like they haven't made their client JARs available in any mvn repos anywhere.  There is a (not-google-sponsored) SourceForge project that points to a Sonatype repo, but instead of adding another 3rd party repo to our small but growing list, I figured it'd be easier for small proof of concept purposes to just manually install the google JARs in OPOWER's repo (thereby making them accessible to all our developer's boxes).

It quickly became clear that the number of JARs Google ships with makes it faster and less error prone to script the mvn repo installation than doing manual command line copy & pasting.  Lo and behold, my gift to the world:

  1. Grab latest JARs from the "gdata-java" link here: [http://code.google.com/p/gdata-java-client/downloads/list](http://code.google.com/p/gdata-java-client/downloads/list)
  1. Unzip on the server hosting your company's mvn repo
  1. cd down in to ./gdata/java/lib
  1. Make a file 'installall.pl' in that lib directory:

          #!/usr/bin/perl -w

          my @jars = `ls *.jar`;
          chomp(@jars);
          foreach my $jar (@jars) {
            if($jar =~ /(.*)-(\d\.\d)\.jar/) {
              my $cmd = "./install.pl --artifactId $1 --version $2 --jar $jar";
              open(CMD, "$cmd|") or die "Could not execute $cmd $!";
              while(<CMD>) {
                 print $_;
              }
             close(CMD);
            }
          }

  1. Still in that directory, make another file `install.pl`:

          #!/usr/bin/perl -w

          use strict;
          use warnings;
          use Getopt::Long;

          sub usage();

          my $artifactId;
          my $version;
          my $jar;
          GetOptions('artifactId=s' => \$artifactId ,
                     'version=s' => \$version,
                     'jar' => \$jar);
          die usage() unless ($artifactId && $version && $jar);

          my $cmd = "mvn deploy:deploy-file " .
                "-DgroupId=com.google.gdata " .
                "-DartifactId=$artifactId " .
                "-Dversion=$version " .
                "-Dfile=$jar " .
                "-Dpackaging=jar " .
                "-DgeneratePom=true " .
                "-Durl=file:///opt/mvn_repo " .  <---  change this for your env
                "-Drepository=opower_local";  <--- change this for your env
          print "executing command = $cmd\n";
          $cmd = "date";
          open(CMD, "$cmd|") or die "Could not exec $cmd $!";
          while(<CMD>) {
              print $_;
          }
          close(CMD);

          sub usage() {
              print "Usage: ./install.pl [--artifactId artifactId] [--version version] [--jar jarfile]\n";
              print "Example: ./install.pl --artifactId gdata-webmastertools --version 1.0 --jar gdata-webmastertools-1.0.jar\n";
              exit 1;
          }

  1. Don't forget to `chmod 755 *.pl`
  1. Then just run `./installall.pl` and all those Google JARs should get installed in your repo

That assumes the "mvn" executable was in your path and that you run the scripts from within the same directory as all the JARs, but it's easily modified for whatever your situation may be.

Note that relative to `./lib`, there are 2 jars in `../deps/` that you should also install in your repo because the Google JARs to avoid ClassNotFoundExceptions in some runtime code paths.

Once in, you should be able to bootstrap a mvn client project against a Google Data source with a pom not too dissimilar from:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <artifactId>foo</artifactId>
  <packaging>jar</packaging>
  <version>1.0.0-SNAPSHOT</version>
  <name>Google Client Example</name>

  <scm>
    <developerConnection>foo</developerConnection>
  </scm>

  <dependencies>
    <dependency>
        <groupId>com.google.gdata</groupId>
        <artifactId>gdata-core</artifactId>
        <version>1.0</version>
    </dependency>
    <dependency>
        <groupId>com.google.gdata</groupId>
        <artifactId>gdata-analytics</artifactId>
        <version>2.1</version>
    </dependency>
    <dependency>
        <groupId>com.google.gdata</groupId>
        <artifactId>gdata-client</artifactId>
        <version>1.0</version>
    </dependency>
    <dependency>
        <groupId>com.google</groupId>
        <artifactId>google-collect</artifactId>
        <version>1.0-rc1</version>
    </dependency>
    dependencies>
</project>
{% endhighlight %}
