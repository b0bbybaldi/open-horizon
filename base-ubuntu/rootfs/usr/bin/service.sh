#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

source /usr/bin/service-tools.sh

###
### MAIN
###

RESPONSE_FILE=$(mktemp)
service_output ${RESPONSE_FILE}
SIZ=$(wc -c "${RESPONSE_FILE}" | awk '{ print $1 }')
if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- output: ${RESPONSE_FILE}; size: ${SIZ}" >> ${LOGTO} 2&1; fi

echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo ""
cat "${RESPONSE_FILE}"
rm -f ${RESPONSE_FILE}
