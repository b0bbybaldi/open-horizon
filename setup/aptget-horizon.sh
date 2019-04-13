#!/bin/bash

HZN_URL="http://pkg.bluehorizon.network/"
  
if [ ! -z $(command -v "apt-get") ]; then
  TYPE=linux
  DIST=ubuntu
  #RELEASE=$(lsb_release -cs)
  RELEASE=xenial
  REPO=updates
  KEY=${HZN_URL}/bluehorizon.network-public.key
  wget -qO - ${KEY} | sudo apt-key add -
  sudo add-apt-repository "deb [arch=armhf,arm64,amd64,ppc64el] ${HZN_URL}/${TYPE}/${DIST} ${RELEASE}-${REPO} main"
  sudo apt-get update -qq && sudo apt-get install -y -qq --no-install-recommend bluehorizon
else
  VERSION=$(curl -fsSL 'http://pkg.bluehorizon.network/macos/' | egrep 'horizon-cli' | sed 's/.*-cli-\(.*\)\.pkg<.*/\1/' | sort | uniq | tail -1)

  if [ -z "${1}" ]; then echo "--- INFO -- $0 $$ -- no version specified; using ${VERSION}" &> /dev/stderr; else VERSION="${1}"; fi

  HZN_PLATFORM="macos"
  if [ ! -z $(command -v 'hzn') ]; then
    if [ ! -z "$(hzn node list 2> /dev/null)" ]; then
      echo "--- INFO -- $0 $$ -- unregistering" &> /dev/stderr
      hzn unregister -f
    fi
  HZNCLI_PKG="horizon-cli-${VERSION}.pkg"
  URL="${HZN_URL}/${HZN_PLATFORM}/${HZNCLI_PKG}"
  echo "--- INFO -- $0 $$ -- getting macOS package from: ${URL}" &> /dev/stderr; fi
  TEMPKG=$(mktemp).pkg
  curl -fsSL "${URL}" -o "${TEMPKG}"
  if [ -s "${TEMPKG}" ]; then
    sudo installer -allowUntrusted -pkg "${TEMPKG}" -target /
    horizon-container update &> /dev/null
  else
    echo "*** ERROR -- $0 $$ -- cannot download package from URL: ${URL}" &> /dev/stderr
    exit 1
  fi
  rm -f "${TEMPKG}"
fi
