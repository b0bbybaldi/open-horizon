#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh

###
### GLOBALS
###

## location of mock data
MOCK_DATADIR=/etc/fft/samples

## configure service we're consuming
API='record'
URL="http://${API}"

###
### MAIN
###

if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- start: " $(date +%T) &> /dev/stderr; fi

## initialize horizon
HZN=$(hzn_init)
if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- HZN: ${HZN}" &> /dev/stderr; fi

## configure service
SERVICES='[{"name":"mqtt","url":"http://mqtt"}]'
CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"period":'${FFT_PERIOD:-0}',"type":"'${FFT_ANOMALY_TYPE:-none}'","level":'${FFT_ANOMALY_LEVEL:-0}',"mock":'${FFT_ANOMALY_MOCK:-false}',"services":'"${SERVICES:-null}"'}'

## initialize servive
CONFIG=$(service_init ${CONFIG})
if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- CONFIG: ${CONFIG}" &> /dev/stderr; fi

## create output file & update service output to indicate life
OUTPUT_FILE=$(mktemp)
echo '{"date":'$(date +%s)',"pid":'${PID:-0}'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

## start the clock; and indicate we're already late
LAST=$(date +%s)
BEGIN=$((LAST-FFT_PERIOD))

while true; do
  # wait for ..
  SECONDS=$((FFT_PERIOD - $(($(date +%s) - BEGIN))))
  if [ ${SECONDS} -gt 0 ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- taking nap: ${SECONDS} seconds" &> /dev/stderr; fi
    sleep ${SECONDS}
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- no nap; lagging: ${SECONDS} seconds" &> /dev/stderr; fi
  fi

  # re-start the clock
  BEGIN=$(date +%s)

  # get service
  PAYLOAD=$(mktemp)
  curl --connect-timeout 1.0 -fsSL "${URL}" -o ${PAYLOAD} 2> /dev/null

  # handle no payload; do mock 
  if [ ! -s "${PAYLOAD}" ] || [ "${FFT_ANOMALY_MOCK}" = true ]; then
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- no payload or FFT_ANOMALY_MOCK is true: ${FFT_ANOMALY_MOCK}" &> /dev/stderr; fi
    # available mock data in MOCK_DATADIR
    MOCKS=( square mixer_1 mixer_2 )
    if [ -z "${ITERATION:-}" ]; then MOCK_INDEX=0 && ITERATION=1; else MOCK_INDEX=$((ITERATION % ${#MOCKS[@]})); ITERATION=$((ITERATION+1)); fi
    if [ ${MOCK_INDEX} -ge ${#MOCKS[@]} ]; then MOCK_INDEX=0; fi
    MOCK="${MOCKS[${MOCK_INDEX}]}"
    WAV_MOCK=${MOCK_DATADIR}/${MOCK}.wav
    if [ "${DEBUG:-}" == 'true' ]; then echo "--- INFO $0 $$ -- MOCK: ${MOCK}; sound: ${WAV_MOCK}; size:" $(wc -c ${WAV_MOCK}) &> /dev/stderr; fi
    # create mock payload
    echo '{"record":{"mock":"'${MOCK}'","date":'$(date +%s)',"audio":"'$(base64 -w 0 ${WAV_MOCK})'"}}' | jq -c '.' > ${PAYLOAD}
    if [ ! -s ${PAYLOAD} ]; then
      echo "*** ERROR $0 $$ -- unable to generate mock payload from ${MOCK}" &> /dev/stderr
      continue
    else
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- generated mock payload: ${PAYLOAD}; size:" $(wc -c ${PAYLOAD}) &> /dev/stderr; fi
    fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- received payload: ${PAYLOAD}; size:" $(wc -c ${PAYLOAD}) &> /dev/stderr; fi
  fi

  # process payload iff new
  WHEN=$(jq -r '.record.date' ${PAYLOAD})
  if [ -z "${WHEN}" ] || [ "${WHEN}" = 'null' ]; then
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- invalid date for payload: ${WHEN}" &> /dev/stderr; fi
    continue
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- payload date: ${WHEN}" &> /dev/stderr; fi
  fi
  
  # test if been-there-done-that
  if [ ${WHEN:-0} -le ${LAST:-0} ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- no update; since: ${LAST}; ago:" $((BEGIN-LAST)) &> /dev/stderr; fi
    continue
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- new payload; ago:" $((BEGIN-WHEN)) &> /dev/stderr; fi
  fi

  # test recording exists
  if [ $(jq '.record.audio?==null' ${PAYLOAD}) = true ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- no audio; when: ${WHEN}; ago:" $((BEGIN-WHEN)) &> /dev/stderr; fi
    continue
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- audio exists" &> /dev/stderr; fi
  fi

  # get audio into working directory
  WORKDIR=$(mktemp -d)
  FILENAME=${WORKDIR}/audio
  WAV_FILE=${FILENAME}.wav
  jq -r '.record.audio' ${PAYLOAD} | base64 --decode > ${WAV_FILE}
  if [ ! -s ${WAV_FILE} ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- no WAV file" &> /dev/stderr; fi
    continue
  fi
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- good WAV file: ${WAV_FILE}; size:" $(wc -c ${WAV_FILE}) &> /dev/stderr; fi

  # process audio
  case ${FFT_ANOMALY_TYPE} in
    "butter")
  	if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- detecting anomaly: ${FFT_ANOMALY_TYPE}; level: ${FFT_ANOMALY_LEVEL}; file: ${FILENAME}" &> /dev/stderr; fi
	${0%/*}/butter.py ${FILENAME} 3 ${FFT_ANOMALY_LEVEL}
	;;
    "welch")
  	if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- detecting anomaly: ${FFT_ANOMALY_TYPE}; level: ${FFT_ANOMALY_LEVEL}; file: ${FILENAME}" &> /dev/stderr; fi
	${0%/*}/welch.py ${FILENAME} "hanning" ${FFT_ANOMALY_LEVEL}
	;;
    *)
  	if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- invalid anomaly type: ${FFT_ANOMALY_TYPE}; continuing" &> /dev/stderr; fi
	continue
	;;
  esac

  # test for result data
  if [ ! -s "${FILENAME}-${FFT_ANOMALY_TYPE}.json" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "*** ERROR $0 $$ -- no output; input: ${FILENAME}; type: ${FFT_ANOMALY_TYPE}"  &> /dev/stderr; fi
    continue
  fi

  # encode FFT image
  if [ ! -s "${FILENAME}-fft.png" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "*** ERROR $0 $$ -- no FFT image"  &> /dev/stderr; fi
    continue
  fi
  base64 -w 0 ${FILENAME}-fft.png > ${FILENAME}-fft.b64

  # encode anomaly image
  if [ ! -s "${FILENAME}-${FFT_ANOMALY_TYPE}.png" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "*** ERROR $0 $$ -- no FFT image"  &> /dev/stderr; fi
    continue
  fi
  base64 -w 0 ${FILENAME}-${FFT_ANOMALY_TYPE}.png > ${FILENAME}-${FFT_ANOMALY_TYPE}.b64

  ## start output for update
  echo '{"date":'$(date +%s)',"type":"'${FFT_ANOMALY_TYPE}'","level":'${FFT_ANOMALY_LEVEL}',"id":"'${HZN_DEVICE_ID}'",' > ${OUTPUT_FILE}
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- initialized output: ${OUTPUT_FILE}" &> /dev/stderr; fi

  # do recording
  if [ "${FFT_INCLUDE_WAV}" = true ]; then
    echo '"'${API}'":' >> ${OUTPUT_FILE}
    jq '.'"${API}" ${PAYLOAD} >> ${OUTPUT_FILE}
    echo ',' >> ${OUTPUT_FILE}
  fi

  # do raw data & image
  if [ "${FFT_INCLUDE_RAW:-}" = true ]; then
    echo '"raw":{"data":' >> ${OUTPUT_FILE}
    cat ${FILENAME}-fft.json >> ${OUTPUT_FILE}
    echo ',' >> ${OUTPUT_FILE}
    echo -n '"image":"' >> ${OUTPUT_FILE}
    cat ${FILENAME}-fft.b64 >> ${OUTPUT_FILE}
    echo '"' >> ${OUTPUT_FILE}
    echo '},' >> ${OUTPUT_FILE}
  fi

  # do anomaly data & image
  echo -n '"'${FFT_ANOMALY_TYPE}'":{"data":' >> ${OUTPUT_FILE}
  cat ${FILENAME}-${FFT_ANOMALY_TYPE}.json >> ${OUTPUT_FILE}
  echo ',' >> ${OUTPUT_FILE}
  echo -n '"image":"' >> ${OUTPUT_FILE}
  cat ${FILENAME}-${FFT_ANOMALY_TYPE}.b64 >> ${OUTPUT_FILE}
  echo '"' >> ${OUTPUT_FILE}
  echo '}' >> ${OUTPUT_FILE}

  # close dict
  echo '}' >> ${OUTPUT_FILE}

  # cleanup
  rm -fr ${PAYLOAD} ${WORKDIR}

  ## DONE
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- created output: ${OUTPUT_FILE}" $(jq -c '.record.audio=(.record.audio!=null)|.raw.data=(.raw.data!=null)|.raw.image=(.raw.image!=null)|.butter.data=(.butter.data!=null)|.butter.image=(.butter.image!=null)|.welch.data=(.welch.data!=null)|.welch.image=(.welch.image!=null)' ${OUTPUT_FILE}) &> /dev/stderr; fi

  ## update the output file
  service_update "${OUTPUT_FILE}"

  ## send payload to MQTT
  if [ ! -z "${MQTT_HOST}" ]; then
    MQTT_TOPIC="${FFT_GROUP}/${FFT_DEVICE}/fft/event"
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- publishing ${OUTPUT_FILE} to ${MQTT_TOPIC}; size:" $(wc -c ${OUTPUT_FILE}) &> /dev/stderr; fi
    ${0%/*}/mqtt_pub.sh -t "${MQTT_TOPIC}" -f "${OUTPUT_FILE}"
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- no MQTT host defined" &> /dev/stderr; fi
  fi

done
