#!/bin/bash

# set -o nounset  # Exit script on use of an undefined variable
# set -o pipefail # Return exit status of the last command in the pipe that failed
# set -o errexit  # Exit script when a command exits with non-zero status
# set -o errtrace # Exit on error inside any functions or sub-shells

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

## parent functions
source /usr/bin/service-tools.sh
source /usr/bin/apache-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## defaults
if [ -z "${APACHE_PID_FILE:-}" ]; then export APACHE_PID_FILE="/var/run/apache2.pid"; fi
if [ -z "${APACHE_RUN_DIR:-}" ]; then export APACHE_RUN_DIR="/var/run/apache2"; fi
if [ -z "${APACHE_ADMIN:-}" ]; then export APACHE_ADMIN="${HZN_ORG_ID}"; fi

## configuration
CONFIG='{"tmpdir":"'${TMPDIR}'","logto":"'${LOGTO:-}'","log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-true}',"org":"'${HZN_SETUP_ORG:-none}'","exchange":"'${HZN_SETUP_EXCHANGE:-none}'","db":"'${HZN_SETUP_DB}'","username":"'${HZN_SETUP_DB_USERNAME:-none}'","conf":"'${APACHE_CONF}'","htdocs": "'${APACHE_HTDOCS}'","cgibin": "'${APACHE_CGIBIN}'","host": "'${APACHE_HOST}'","port": "'${APACHE_PORT}'","admin": "'${APACHE_ADMIN}'","pidfile":"'${APACHE_PID_FILE:-none}'","rundir":"'${APACHE_RUN_DIR:-none}'","services":'"${SERVICES:-null}"'}'

## initialize service
service_init ${CONFIG}

## setup environment for apache CGI scripts
export HZN_EXCHANGE_APIKEY="${HZN_SETUP_APIKEY:-none}"
export HZN_EXCHANGE_URL="${HZN_SETUP_EXCHANGE:-none}"
export HZN_ORG_ID="${HZN_SETUP_ORG:-none}"

# start apache
PID=$(apache_start HZN_EXCHANGE_URL HZN_EXCHANGE_APIKEY HZN_ORG_ID HZN_SETUP_DB HZN_SETUP_DB_USERNAME HZN_SETUP_DB_PASSWORD)

# create output file
OUTPUT_FILE=$(mktemp)

# loop while node is alive
while [ true ]; do
  # test for PID file
  if [ ! -z "${APACHE_PID_FILE:-}" ]; then
    if [ -s "${APACHE_PID_FILE}" ]; then
      PID=$(cat ${APACHE_PID_FILE})
    else
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- empty PID file: ${APACHE_PID_FILE}" > /dev/stderr; fi
    fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no PID file defined" > /dev/stderr; fi
  fi
  # create output
  echo -n '{"pid":'${PID:-0}',"status":"' > ${OUTPUT_FILE}
  curl -fsSL "localhost:${APACHE_PORT}/server-status" | base64 -w 0 >> ${OUTPUT_FILE}
  echo '"}' >> ${OUTPUT_FILE}
  service_update ${OUTPUT_FILE}
  sleep ${APACHE_PERIOD:-30}

done
