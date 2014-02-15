#!/bin/bash

# Generates the site using Jekyll and publishes the resulting static files to
# the master branch of the master repo.

if [[ ! -d _site || ! -r _site/.git ]]; then
    echo "_site directory has not been initialized as a submodule"
    echo "run 'git submodule update --init'"
    exit 1
fi

BRANCH=$(git symbolic-ref HEAD)
if [[ "$BRANCH" != "refs/heads/working" ]]; then
    echo "Run this script while on the 'working' branch" >&2
    exit 1
fi

if [[ ! -r _config.yml ]]; then
    echo "Run this script from the root directory, where _config.yml is" >&2
    exit 1
fi

# Update the content in the submodule first
cd _site
git reset --hard HEAD
git clean -df
git pull git@github.com:opower/opower.github.io.git master

# Now generate the new content
cd ..
bundle exec jekyll build

# Show off the diff
cd _site
git add --all
git diff --cached
git status
echo "Did that all look like what you expected?" >&2
echo "Are you ready to commit that content change?" >&2
echo "Once you type 'y', I will push the content live" >&2
read -ep "Push the content? [y/n]: " RESPONSE
if [[ "$RESPONSE" != "y" ]]; then
    echo "Aborting publish process"
    exit 0
fi

# Push the content and the submodule SHA
git commit -m "Publishes new content"
git push git@github.com:opower/opower.github.io.git HEAD:master
cd ..
git commit -m "Syncs submodule with new published content" _site
git push git@github.com:opower/opower.github.io.git HEAD:working

echo "Content published.  Check out http://opower.github.io"

exit 0
