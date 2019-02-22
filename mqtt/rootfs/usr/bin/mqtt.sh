#!/bin/bash

# TMP
if [ -d '/tmpfs' ]; then TMP='/tmpfs'; else TMP='/tmp'; fi

if [ -z "${MQTT_PERIOD}" ]; then MQTT_PERIOD=60; fi

CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"period":'${MQTT_PERIOD}'}'

# start MQTT broker as daemon
mosquitto -d -c /etc/mosquitto.conf

# get pid
PID=$(ps | grep "mosquitto" | grep -v grep | awk '{ print $1 }' | head -1)
if [ -z "${PID}" ]; then PID=0; fi
CONFIG=$(echo "${CONFIG}" | jq '.pid='"${PID}")
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

VERSION=$(mosquitto_sub -C 1 -h horizon.dcmartin.com -t '$SYS/broker/version')
if [ -z "${VERSION:-}" ]; then VERSION="unknown"; fi
CONFIG=$(echo "${CONFIG}" | jq '.version="'"${VERSION}"'"')

# intialize service output
echo "${CONFIG}" > ${TMP}/${SERVICE_LABEL}.json

###
### MAIN
### 

MQTT_HOST="${SERVICE_LABEL}"

# iterate forever
while true; do
  # re-initialize
  OUTPUT="${CONFIG}"
  # get MQTT stats
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.bytes.received='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/bytes/received'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.bytes.sent='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/bytes/sent'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.clients.connected='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/clients/connected'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.load.messages.sent.one='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/sent/1min'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.load.messages.sent.five='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/sent/5min'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.load.messages.sent.fifteen='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/sent/15min'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.load.messages.received.one='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/received/1min'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.load.messages.received.five='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/received/5min'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.load.messages.received.fifteen='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/load/messages/received/15min'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.publish.messages.received='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/publish/messages/received'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.publish.messages.sent='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/publish/messages/sent'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.publish.messages.dropped='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/publish/messages/dropped'))
  OUTPUT=$(echo "${OUTPUT}" | jq '.broker.subscriptions.count='$(mosquitto_sub -C 1 -h "${MQTT_HOST}" -t '$SYS/broker/subscriptions/count'))
  # update output
  echo "${OUTPUT}" | jq '.date='$(date +%s) > "${TMP}/${0##*/}.$$"
  mv -f "${TMP}/${0##*/}.$$" "${TMP}/${SERVICE_LABEL}.json"
  # wait for ..
  SLEEP=$((MQTT_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SLEEP} > 0 ]; then
    sleep ${SLEEP}
  fi
done
