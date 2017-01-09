#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Run our compile script
ng build --prod -o ./dist --base-href "/angular2-getting-started/"

# Clone the existing gh-pages for this repo into out/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
git clone $REPO ../out
cd ../out
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
git config user.name "Travis CI"
git config user.email "cideploy@digitaldrummerj.me"
cd ..

# Clean out existing contents
rm -rf out/**/* || exit 0

# ng test --watch=false        

# Now let's go have some fun with the cloned repo
cd angular2-getting-started
mv dist/* ../out

cd ../out
# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add .
git commit -m "Deploy to GitHub Pages: ${SHA}. " #" Travis build: $TRAVIS_BUILD_NUMBER"


# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH

#source: https://github.com/domenic/zones/blob/master/deploy.sh
