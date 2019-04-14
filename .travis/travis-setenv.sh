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
if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- Horizon organization: ${HZN_ORG_ID}; Docker namespace: ${DOCKER_NAMESPACE}" &> /dev/stderr; fi

# on a branch
if [ ! -z "${TAG}" ]; then echo "${TAG}" > TAG; fi

if [ ${TRAVIS_PULL_REQUEST:-} = false ]; then 
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- non-pull-request: BRANCH: ${TRAVIS__BRANCH}; TAG: ${TAG}" &> /dev/stderr; fi
  echo ${HZN_EXCHANGE_APIKEY} > APIKEY
  echo ${PRIVATE_KEY} | base64 --decode > ${HZN_ORG_ID}.key
  echo ${PUBLIC_KEY} | base64 --decode > ${HZN_ORG_ID}.pem
else
  if [ "${DEBUG:-}" = 'true' ]; then echo "--- INFO -- $0 $$ -- pull-request: BRANCH: ${TRAVIS_PULL_REQUEST_BRANCH}; TAG: ${TAG}" &> /dev/stderr; fi
fi
