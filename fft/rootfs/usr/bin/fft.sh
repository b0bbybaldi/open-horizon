#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## configure service

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"period":"'${FFT_PERIOD:-60}'","port":'${SERVICE_PORT:-null}',"services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## start discovery
python /usr/bin/discovery.py &
# get pid
PID=$(ps | grep "discovery.py" | grep -v grep | awk '{ print $1 }' | head -1)

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)',"pid":'${PID:-0}'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

URL='http://127.0.0.1:'${SERVICE_PORT}'/v1/discovered'

while true; do
  DATE=$(date +%s)
  OUTPUT=$(jq -c '.' "${OUTPUT_FILE}")
  DISCOVERED=$(curl -sSL "${URL}" | jq -c '.' 2> /dev/null)
  if [ -z "${DISCOVERED}" ]; then DISCOVERED=null; echo "+++ WARN $0 $$ -- no output from ${URL}; continuing"; fi
  OUTPUT=$(echo "${OUTPUT}" | jq -c '.found='"${DISCOVERED}")

  # output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${OUTPUT_FILE}"
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((FFT_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
