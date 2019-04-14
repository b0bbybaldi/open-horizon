#!/bin/bash
set -o errexit

###
### travis-setenv.sh
###
### This script sets environment in Travis-CI
###

# minimum
echo ${HZN_ORG_ID} > HZN_ORG_ID
echo ${DOCKER_NAMESPACE} > DOCKER_NAMESPACE

# on a branch
if [ "${TRAVIS_PULL_REQUEST:-}" = false ]; then 
  BRANCH=${TRAVIS_PULL_REQUEST_BRANCH:-}
else
  BRANCH=${TRAVIS_BRANCH:-}
fi
if [ -z "${BRANCH:-}" ]; then 
  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ - no branch" &> /dev/stderr; fi
fi
if [ "${BRANCH}" != 'master' ]; then TAG="${BRANCH}" && echo "${TAG}" > TAG; fi

# report
if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- BRANCH: ${BRANCH:-none}; TAG: ${TAG:-none}; Horizon organization: ${HZN_ORG_ID:-none}; Docker namespace: ${DOCKER_NAMESPACE:-none}" &> /dev/stderr; fi

# make secrets
if [ ${TRAVIS_PULL_REQUEST:-false} = false ]; then 
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- non-pull-request" &> /dev/stderr; fi
  echo ${HZN_EXCHANGE_APIKEY} > APIKEY
  echo ${PRIVATE_KEY} | base64 --decode > ${HZN_ORG_ID}.key
  echo ${PUBLIC_KEY} | base64 --decode > ${HZN_ORG_ID}.pem
else
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- pull-request; no secrets" &> /dev/stderr; fi
fi
