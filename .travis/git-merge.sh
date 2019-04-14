#!/bin/bash
set -o errexit

###
### git-merge.sh
###
### This script pulls the proper parent
###

if [ ! -z "${1}" ]; then
  TPR="${1}"
else
  TPR=${TRAVIS_PULL_REQUEST:-} 
fi

if [ "${TPR}" = true ];  then
  # get repo
  REPO_SLUG=${TRAVIS_PULL_REQUEST_SLUG}
  # get branch
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH}
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- pull request; branch: ${BRANCH} to branch: ${TRAVIS_BRANCH}" &> /dev/stderr; fi
  # test for master
  case ${BRANCH} in
    master)
	git merge beta
	;;
    beta)
	git merge exp
	;;
    *)
	echo "+++ WARN -- $0 $$ -- branch in invalid: ${BRANCH}" &> /dev/stderr
	;;
  esac
else
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- non-pull request; branch: ${TRAVIS_BRANCH}" &> /dev/stderr; fi
fi
