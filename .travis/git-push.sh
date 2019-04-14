#!/bin/bash
set -o errexit

### git-push.sh

if [ ${TRAVIS_PULL_REQUEST} = false ]; then
  REPO_SLUG=${TRAVIS_PULL_REQUEST_SLUG}
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH}
else
  REPO_SLUG=${TRAVIS_REPO_SLUG}
  BRANCH=${TRAVIS_BRANCH}
fi

if [ ${TRAVIS_PULL_REQUEST} = "true" ]; then 
case ${BRANCH} in
  master)
  	git config --global user.email "travis@travis-ci.org"
  	git config --global user.name "Travis-CI"
  	git remote add origin "https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"
  	git -a commit -m "merge beta" && git push origin master || exit 1
	;;
  beta)
    	git config --global user.email "travis@travis-ci.org"
	git config --global user.name "Travis-CI"
	git remote add origin "https://${GITHUB_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git"
	git -a commit -m "merge exp" && git push origin beta || exit 1
	;;
  *)
	;;
esac
