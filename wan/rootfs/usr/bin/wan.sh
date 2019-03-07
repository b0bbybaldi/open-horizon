#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${WAN_PERIOD}" ]; then WAN_PERIOD=1800; fi
CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${WAN_PERIOD}'}' 
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

while true; do
  DATE=$(date +%s)
  OUTPUT="${CONFIG}"
  SPEEDTEST=$(speedtest --json)
  if [ -z "${SPEEDTEST}" ]; then SPEEDTEST=null; fi

  OUTPUT=$(echo "${OUTPUT}" | jq '.date='$(date +%s))

  echo "${OUTPUT}" | jq '.speedtest='"${SPEEDTEST}" > "${TMP}/$$"
  mv -f "${TMP}/$$" "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SECONDS=$((WAN_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
