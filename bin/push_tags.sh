#!/bin/bash

git remote add super https://gett-systems:$GITLAB_ACCESS_TOKEN@gitlab.com/getto-systems-labo/rubygems-params.git
git remote add github https://getto-systems:$GITHUB_ACCESS_TOKEN@github.com/getto-systems/rubygems-getto-params.git
git tag $(cat .release-version)
git push super HEAD:master --tags
git push bitbucket HEAD:master --tags
