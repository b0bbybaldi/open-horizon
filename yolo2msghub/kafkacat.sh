#!/bin/bash
BROKER="kafka05-prod02.messagehub.services.us-soutbluemix.net:9093,kafka01-prod02.messagehub.services.us-south.bluemix.net:9093,kafka03-prod02.messagehub.services.us-south.bluemix.net:9093,kafka04-prod02.messagehub.services.us-south.bluemix.net:9093,kafka02-prod02.messagehub.services.us-south.bluemix.net:9093"

if [ -z "${1}" ]; then SERVICE="service.json"; echo "+++ WARN $0 $$ -- service configuration JSON not specified on command line; using ${SERVICE}" &> /dev/stderr; else SERVICE="${1}"; fi
if [ ! -s "${SERVICE}" ]; then echo "*** ERROR $0 $$ -- cannot locate service configuration JSON: ${SERVICE}; exiting" &> /dev/stderr; exit 1; fi

LABEL=$(jq -r '.label' "${SERVICE}")
if [ -z "${LABEL}" ]; then echo "*** ERROR $0 $$ -- no service label defined in ${SERVICE}; exiting" &> /dev/stderr; exit 1; fi

ENVIRONMENT=$(jq -r '.deployment.services.'"${LABEL}"'.environment[]' "${SERVICE}")
if [ ! -z "${ENVIRONMENT}" ] && [ "${ENVIRONMENT}" != 'null' ]; then
  for E in ${ENVIRONMENT}; do
    if [[ "${E}" == SERVICE_LABEL=* ]]; then SERVICE_LABEL=$(echo "${E}" | sed 's|SERVICE_LABEL=||'); break; fi
  done
  if [ -z "${SERVICE_LABEL:-}" ]; then
    SERVICE_LABEL="${LABEL}"
    echo "+++ WARN $0 $$ -- SERVICE_LABEL not defined in deployment.services.${SERVICE}.environment; using default ${SERVICE_LABEL}" &> /dev/stderr
  fi
else
  echo "+++ WARN $0 $$ -- no environment defined for service ${LABEL}; exiting" &> /dev/stderr
  exit 1
fi

REQUIRED_VARIABLES=YOLO2MSGHUB_APIKEY
for R in ${REQUIRED_VARIABLES}; do
  if [ ! -s "${R}" ]; then echo "*** ERROR $0 $$ -- required variable ${R} file not found; exiting" &> /dev/stderr; fi
  APIKEY=$(sed -e 's|^["]*\([^"]*\)["]*|\1|' "${R}")
  echo "--- INFO $0 $$ -- set ${R} to ${APIKEY}" &> /dev/stderr
done

TOPIC="yolo2msghub"
DEVICES='[]'

echo "--- INFO $0 $$ -- listening for topic ${TOPIC}" &> /dev/stderr

kafkacat -E -u -C -q -o end -f "%s\n" -b "${BROKER}" \
  -X "security.protocol=sasl_ssl" \
  -X "sasl.mechanisms=PLAIN" \
  -X "sasl.username=${APIKEY:0:16}" \
  -X "sasl.password=${APIKEY:16}" \
  -t "${TOPIC}" | while read -r; do
    if [ -n "${REPLY}" ]; then
      PAYLOAD=${0##*/}.$$.json
      echo "${REPLY}" > ${PAYLOAD}
      VALID=$(echo "${REPLY}" | ./test-yolo2msghub.sh 2> ${PAYLOAD%.*}.out)
    else
      if [ "${DEBUG:-}" == 'true' ]; then echo "+++ WARN $0 $$ -- null payload" &> /dev/stderr; fi
      continue
    fi
    if [ "${VALID}" != 'true' ]; then
      echo "+++ WARN $0 $$ -- invalid payload: ${VALID}" $(jq -c '.' ${PAYLOAD%.*}.out) &> /dev/stderr
    fi
    ID=$(jq -r '.hzn.device_id' ${PAYLOAD})
    DATE=$(jq -r '.yolo2msghub.yolo.date' ${PAYLOAD})
    THIS=$(echo "${DEVICES}" | jq '.[]|select(.id=="'${ID}'")')
    if [ -z "${THIS}" ] || [ "${THIS}" == 'null' ]; then
      THIS='{"id":"'${ID}'","date":'${DATE}',"count":0}'
      DEVICES=$(echo "${DEVICES}" | jq '.+=['"${THIS}"']')
      TOTAL=0
      LAST=0
    else
      TOTAL=$(echo "${THIS}" | jq '.count')
      LAST=$(echo "${THIS}" | jq '.date')
    fi

    DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")

    if [ $(jq '.yolo2msghub.yolo!=null' ${PAYLOAD}) == 'true' ]; then
      if [ $(jq -r '.yolo2msghub.yolo.mock' ${PAYLOAD}) == 'null' ]; then
        if [ ${DATE} -gt ${LAST} ]; then
          COUNT=$(jq -r '.yolo2msghub.yolo.count' ${PAYLOAD})
          if [ ${COUNT} -gt 0 ]; then
            echo "--- INFO $0 $$ -- ${ID} at ${DATE}: person count ${COUNT}" &> /dev/stderr
            TOTAL=$((${TOTAL}+${COUNT}))
            THIS=$(echo "${THIS}" | jq '.count='${TOTAL})
            jq -r '.yolo2msghub.yolo.image' ${PAYLOAD} | base64 --decode > ${0##*/}.$$.${ID}.jpeg
            # if [ ! -z $(command -v open) ]; then open ${0##*/}.$$.${ID}.jpeg; fi
          else
            echo "+++ WARN $0 $$ -- ${ID} at ${DATE}: no person" &> /dev/stderr
          fi
          THIS=$(echo "${THIS}" | jq '.date='${DATE})
          DEVICES=$(echo "${DEVICES}" | jq '(.[]|select(.id=="'${ID}'"))|='"${THIS}")
          DEVICES=$(echo "${DEVICES}" | jq '.|sort_by(.count)|reverse')
        fi
      else
        echo "+++ WARN $0 $$ -- ${ID} at ${DATE}: mock" $(jq -c '.yolo2msghub.yolo.detected' ${PAYLOAD}) &> /dev/stderr
      fi
    else
      echo "+++ WARN $0 $$ -- ${ID} at ${DATE}: no yolo output" &> /dev/stderr
    fi
    echo "${DEVICES}" | jq -c '.' &> /dev/stderr
done
rm -f ${0##*/}.$$.*
