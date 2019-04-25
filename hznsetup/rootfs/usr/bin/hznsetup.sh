#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### hznsetup.sh
###
### Run forever sending requests to hznsetup-node.sh
###

if [ "${HZN_SETUP_VENDOR:-any}" = 'any' ]; then HZN_SETUP_VENDOR="*"; fi
if [ -z "${HZN_SETUP_EXCHANGE:-}" ]; then HZN_SETUP_EXCHANGE="https://alpha.edge-fabric.com/v1/"; fi
if [ -z "${HZN_SETUP_ORG:-}" ]; then HZN_SETUP_ORG="${HZN_ORG_ID:-none}"; fi
if [ -z "${HZN_SETUP_APIKEY:-}" ]; then HZN_SETUP_APIKEY="${HZN_EXCHANGE_APIKEY}"; fi
if [ -z "${HZN_SETUP_APPROVE:-}" ]; then HZN_SETUP_APPROVE="auto"; fi
if [ -z "${HZN_SETUP_DB:-}" ]; then HZN_SETUP_DB="https://515bed78-9ddc-408c-bf41-32502db2ddf8-bluemix.cloudant.com"; fi
if [ -z "${HZN_SETUP_DB:-}" ]; then echo "*** ERROR -- $0 $$ -- no database" >> ${LOGTO} 2>&1; fi
if [ -z "${HZN_SETUP_USERNAME:-}" ]; then echo "+++ WARN -- $0 $$ -- no database username" >> ${LOGTO} 2>&1; fi
if [ -z "${HZN_SETUP_PASSWORD:-}" ]; then echo "+++ WARN -- $0 $$ -- no database password" >> ${LOGTO} 2>&1; fi
if [ -z "${HZN_SETUP_BASENAME:-}" ]; then echo "--- INFO -- $0 $$ -- no client basename" >> ${LOGTO} 2>&1; fi
if [ -z "${HZN_SETUP_PATTERN:-}" ]; then echo "--- INFO -- $0 $$ -- no initial pattern" >> ${LOGTO} 2>&1; fi
if [ -z "${HZN_SETUP_PORT:-}" ]; then HZN_SETUP_PORT=3093; echo "--- INFO -- $0 $$ -- using default port: ${HZN_SETUP_PORT}" >> ${LOGTO} 2>&1; fi
if [ -z "${HZN_SETUP_PERIOD:-}" ]; then HZN_SETUP_PERIOD=30; echo "--- INFO -- $0 $$ -- using default period: ${HZN_SETUP_PERIOD}" >> ${LOGTO} 2>&1; fi

## FUNCTIONS
source /usr/bin/service-tools.sh
source /usr/bin/hznsetup-tools.sh

## setup response script
if [ -z "${HZN_SETUP_SCRIPT:-}" ]; then HZN_SETUP_SCRIPT="hznsetup-node.sh"; fi
HZN_SETUP_SCRIPT=$(command -v "${HZN_SETUP_SCRIPT}")

###
### MAIN
###

## initialize horizon
hzn_init

## configure service
#SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
CONFIG='{"tmpdir":"'${TMPDIR}'","logto":"'${LOGTO:-}'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-true}',"org":"'${HZN_SETUP_ORG:-none}'","exchange":"'${HZN_SETUP_EXCHANGE:-none}'","pattern":"'${HZN_SETUP_PATTERN:-}'","port":'${HZN_SETUP_PORT:-0}',"db":"'${HZN_SETUP_DB}'","username":"'${HZN_SETUP_DB_USERNAME:-none}'","approve":"auto","vendor":"any","services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

## FOREVER
while true; do
  DATE=$(date +%s)
  # report in
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- checking socat; port ${HZN_SETUP_PORT:-NONE}; script: ${HZN_SETUP_SCRIPT:-NONE}" >> "${LOGTO}" 2>&1; fi
  PID=$(ps x | egrep 'socat' | egrep "${HZN_SETUP_SCRIPT}" | awk '{ print $1 }' | head -1)
  if [ -z "${PID:-}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- starting socat; port ${HZN_SETUP_PORT:-NONE}; script: ${HZN_SETUP_SCRIPT:-NONE}" >> "${LOGTO}" 2>&1; fi
    # start listening
    socat TCP4-LISTEN:${HZN_SETUP_PORT},fork EXEC:${HZN_SETUP_SCRIPT} &
    PID=$(ps x | egrep 'socat' | egrep "${HZN_SETUP_SCRIPT}" | awk '{ print $1 }' | head -1)
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- started socat; PID: ${PID}; port ${HZN_SETUP_PORT}" >> "${LOGTO}" 2>&1; fi
  elif [ "${DEBUG:-}" = true ]; then 
    PS=$(ps x | egrep socat | egrep "${HZN_SETUP_SCRIPT}")
    echo "--- INFO -- $0 $$ -- found ${HZN_SETUP_SCRIPT:-NONE}: ${PS}" >> "${LOGTO}" 2>&1
  fi

  if [ ! -z "${PID:-}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- socat running; PID: ${PID}; port ${HZN_SETUP_PORT}" >> "${LOGTO}" 2>&1; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- socat failed; PID: ${PID}" >> "${LOGTO}" 2>&1; fi
  fi

  # update service
  hzn_setup_exchange_nodes | jq '.date='$(date +%s)'|.pid='${PID:-0} > "${OUTPUT_FILE}"
  service_update "${OUTPUT_FILE}"

  # wait for ..
  SECONDS=$((HZN_SETUP_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- sleep ${SECONDS}" >> "${LOGTO}" 2>&1; fi
    sleep ${SECONDS}
  fi

done
