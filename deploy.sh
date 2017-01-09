#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Skipping deploy; just doing a build."
    ng build --prod
    ng test --watch=false        
    exit 0
fi

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
openssl aes-256-cbc -K $encrypted_b32679098817_key -iv $encrypted_b32679098817_iv -in id_rsa.enc -out id_rsa -d
mv id_rsa ~/.ssh/id_rsa
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Clone the existing gh-pages for this repo into out/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
git clone $REPO dist
cd dist
git config user.name "Travis CI"
git config user.email "cideploy@digitaldrummerj.me"
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
cd ..

# Clean out existing contents
rm -rf dist/**/* || exit 0

#cd dist
#git add .
#git commit -m "removing old files"
#cd ..

# Run our compile script

ng build --prod -o ./dist --base-href "/angular2-getting-started/"
ng test --watch=false        

# Now let's go have some fun with the cloned repo
cd dist

# If there are no changes (e.g. this is a README update) then just bail.
if [ -z `git diff --exit-code` ]; then
    echo "No changes to the spec on this push; exiting."
    exit 0
fi

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add .
git commit -m "Deploy to GitHub Pages: ${SHA}.  Travis build: $TRAVIS_BUILD_NUMBER"


# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH

#source: https://github.com/domenic/zones/blob/master/deploy.sh
