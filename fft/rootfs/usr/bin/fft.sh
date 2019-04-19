#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/fft-tools.sh

###
### MAIN
###

## initialize horizon
hzn_init

## configure service

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"bins":'${FFT_BIN_COUNT:-0}',"min":'${FFT_SAMPLE_MIN:-0}',"max":'${FFT_SAMPLE_MAX:-0}',"level":'${FFT_ANOMALY_LEVEL:-0.0}',"period":'${FFT_PERIOD:-1}',"type":"'${FFT_ANOMALY_TYPE:-none}'","mock":'${FFT_ANOMALY_MOCK:-false}',,"services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}


## create output file & update service output to indicate life
OUTPUT_FILE=$(mktemp)
echo '{"date":'$(date +%s)',"pid":'${PID:-0}'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

## configure service we're sending
API='record'
URL="http://${API}"

while true; do
  DATE=$(date +%s)

  # get service
  PAYLOAD=$(mktemp)
  curl -sSL "${URL}" -o ${PAYLOAD} 2> /dev/null
  CURRENT=$(jq -r '.date' ${PAYLOAD})
  if [ 
  echo '{"date":'$(date +%s)',"'${API}'":' > ${OUTPUT_FILE}
  if [ -s "${PAYLOAD}" ]; then
    jq '.'"${API}" ${PAYLOAD} >> ${OUTPUT_FILE}
  else
    echo 'null' >> ${OUTPUT_FILE}
  fi
  rm -f ${PAYLOAD}
  echo '}' >> ${OUTPUT_FILE}
  # update the output file
  service_update "${OUTPUT_FILE}"
  # wait for ..
  SECONDS=$((FFT_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
  done
done
