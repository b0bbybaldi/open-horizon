#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### initialization
###

## initialize horizon
hzn_init

## configure service

SERVICES='[{"name": "hal", "url": "http://hal" },{"name":"cpu","url":"http://cpu"},{"name":"wan","url":"http://wan"}]'
CONFIG='{"date":'$(date +%s)',"log_level":"'${LOG_LEVEL}'","debug":'${DEBUG}',"services":'${SERVICES}',"period":'${YOLO2MSGHUB_PERIOD}'}'
echo "${CONFIG}" > ${TMPDIR}/${SERVICE_LABEL}.json

## initialize servive
service_init ${CONFIG}

###
### MAIN
###

## initial output
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

# make topic
TOPIC=$(curl -sSL -H 'Content-Type: application/json' -H "X-Auth-Token: ${YOLO2MSGHUB_APIKEY}" "${YOLO2MSGHUB_ADMIN_URL}/admin/topics" -d '{"name":"'${SERVICE_LABEL}'"}')
if [ "$(echo "${TOPIC}" | jq '.errorCode!=null')" == 'true' ]; then
  echo "+++ WARN $0 $$ -- topic ${SERVICE_LABEL} message:" $(echo "${TOPIC}" | jq -r '.errorMessage') &> /dev/stderr
fi

## configure service we're sending
API='yolo'
URL="http://${API}"

while true; do
  DATE=$(date +%s)

  # get service
  PAYLOAD=$(mktemp)
  curl -sSL "${URL}" -o ${PAYLOAD} 2> /dev/null
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

  # send via kafka
  if [ $(command -v kafkacat) ] && [ ! -z "${YOLO2MSGHUB_BROKER}" ] && [ ! -z "${YOLO2MSGHUB_APIKEY}" ]; then
    # get the combined service output
    SERVICE_OUTPUT=$(mktemp)
    service_output ${SERVICE_OUTPUT}
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- service_output size:" $(wc -c ${SERVICE_OUTPUT}) &> /dev/stderr; fi
    # process output
    if [ -s ${SERVICE_OUTPUT} ]; then
      # package output for Kafka (single-line)
      KAFKA_PAYLOAD=$(mktemp)
      jq -c '.' ${SERVICE_OUTPUT} > ${KAFKA_PAYLOAD}
      if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO -- $0 $$ -- payload size:" $(wc -c ${KAFKA_PAYLOAD}) &> /dev/stderr; fi
      if [ -s ${KAFKA_PAYLOAD} ]; then 
        kafkacat "${KAFKA_PAYLOAD}" \
          -P \
          -b "${YOLO2MSGHUB_BROKER}" \
          -X api.version.request=true \
          -X security.protocol=sasl_ssl \
          -X sasl.mechanisms=PLAIN \
          -X sasl.username=${YOLO2MSGHUB_APIKEY:0:16}\
          -X sasl.password="${YOLO2MSGHUB_APIKEY:16}" \
          -t "${SERVICE_LABEL}"
      else
        echo "+++ WARN $0 $$ -- zero-sized payload: ${KAFKA_PAYLOAD}" &> /dev/stderr
      fi
      rm -f ${KAFKA_PAYLOAD}
    else
      echo "+++ WARN $0 $$ -- zero-sized service_output: ${SERVICE_OUTPUT}" &> /dev/stderr
    fi
    rm -f ${SERVICE_OUTPUT}
  else
    echo "+++ WARN $0 $$ -- kafka invalid" &> /dev/stderr
  fi

  # wait for ..
  SECONDS=$((YOLO2MSGHUB_PERIOD - $(($(date +%s) - DATE))))
  if [ ${SECONDS} -gt 0 ]; then
    sleep ${SECONDS}
  fi
done
