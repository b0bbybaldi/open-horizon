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

  if [ "${DEBUG:-}" = true ]; then echo "::: DEBUG -- $0 $$ -- ${1}" > /dev/stderr; fi


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
CONFIG='{"conf":"'${APACHE_CONF}'","htdocs": "'${APACHE_HTDOCS}'","cgibin": "'${APACHE_CGIBIN}'","host": "'${APACHE_HOST}'","port": "'${APACHE_PORT}'","admin": "'${APACHE_ADMIN}'","pidfile":"'${APACHE_PID_FILE:-none}'","rundir":"'${APACHE_RUN_DIR:-none}'"}'

## initialize service
service_init ${CONFIG}

## START HTTPD
if [ -s "${APACHE_CONF}" ]; then
  # edit defaults
  sed -i 's|^Listen \(.*\)|Listen '${APACHE_PORT}'|' "${APACHE_CONF}"
  sed -i 's|^ServerName \(.*\)|ServerName '"${APACHE_HOST}:${APACHE_PORT}"'|' "${APACHE_CONF}"
  sed -i 's|^ServerAdmin \(.*\)|ServerAdmin '"${APACHE_ADMIN}"'|' "${APACHE_CONF}"
  # enable CGI
  sed -i 's|^\([^#]\)#LoadModule cgi|\1LoadModule cgi|' "${APACHE_CONF}"
  # set environment
  echo "SetEnv HZN ${HZN}" >> "${APACHE_CONF}"
  # make /run/apache2 for PID file
  mkdir -p ${APACHE_RUN_DIR}
  # start HTTP daemon 
  httpd -E /dev/stderr -e ${LOG_LEVEL:-debug} -f "${APACHE_CONF}" &
  PID=$!
else
  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- no configuration: ${APACHE_CONF}" > /dev/stderr; fi
fi

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
