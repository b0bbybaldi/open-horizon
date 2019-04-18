#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

###
### FUNCTIONS
###

source /usr/bin/service-tools.sh
source /usr/bin/sox-tools.sh

###
### noise-detect.sh - create multiple WAV files named `noise###.wav`
###
### NOIZE_START_LEVEL - percentage change between silence and non-silence
### NOIZE_START_SECONDS - number of seconds of non-silence to start noiseing
### NOIZE_FINISH_SECONDS - number of seconds of silence after noise detected to stop noiseing
### NOIZE_FINISH_LEVEL - percentage change between non-silence and silence
### NOIZE_SAMPLE_RATE - sampling rate; default: 19200
### NOIZE_THRESHOLD - use high-pass filter to remove sounds below threshold
###

if [ -z "${NOIZE_START_LEVEL:-}" ]; then NOIZE_START_LEVEL='1.0'; fi
if [ -z "${NOIZE_START_SECONDS:-}" ]; then NOIZE_START_SECONDS='0.1'; fi
if [ -z "${NOIZE_FINISH_LEVEL:-}" ]; then NOIZE_FINISH_LEVEL='1.0' ; fi
if [ -z "${NOIZE_FINISH_SECONDS:-}" ]; then NOIZE_FINISH_SECONDS='5.0'; fi
if [ -z "${NOIZE_SAMPLE_RATE:-}" ]; then NOIZE_SAMPLE_RATE='19200'; fi
if [ -z ${NOIZE_THRESHOLD:-} ]; then NOIZE_THRESHOLD=; fi

###
### MAIN
###

## initialize horizon
hzn_init

## configure service

CONFIG='{"log_level":"'${LOG_LEVEL:-}'","debug":'${DEBUG:-false}',"start":{"level":'${NOIZE_START_LEVEL}',"seconds":'${NOIZE_START_SECONDS}'},"finish":{"level":'${NOIZE_FINISH_LEVEL}',"seconds":'${NOIZE_FINISH_SECONDS}'},"sample_rate":"'${NOIZE_SAMPLE_RATE:-60}',"threshold":"'${NOIZE_THRESHOLD:-}'","threshold_tune":false,"level_tune":false,"services":'"${SERVICES:-null}"'}'

## initialize servive
service_init ${CONFIG}

## start noise-detector
DIR=${TMPDIR}/${0##*/}
mkdir -p ${DIR}
if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- created directory: $DIR" &> /dev/stderr; fi

## start listener
PID=$(sox_detect_record ${DIR} ${NOISE_START_LEVEL} ${NOIZE_START_SECONDS} ${NOIZE_FINISH_LEVEL} ${NOIZE_FINISH_SECONDS})
if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- started sox; PID" &> /dev/stderr; fi

## initialize
OUTPUT_FILE="${TMPDIR}/${0##*/}.${SERVICE_LABEL}.$$.json"
echo '{"date":'$(date +%s)',"pid":'${PID:-0}'}' > "${OUTPUT_FILE}"
service_update "${OUTPUT_FILE}"

while true; do
  # update service
  service_update ${OUTPUT_FILE}
  if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- waiting on directory: ${DIR}" >> ${LOGTO} 2>&1; fi
  # wait (forever) on changes in ${DIR}
  inotifywait -m -r -e close_write --format '%w%f' "${DIR}" | while read FULLPATH; do
    if [ "${DEBUG}" == 'true' ]; then echo "--- INFO -- $0 $$ -- inotifywait ${FULLPATH}" >> ${LOGTO} 2>&1; fi
    if [ ! -z "${FULLPATH}" ]; then
      # process updates
      case "${FULLPATH##*/}" in
        *.wav)
          if [ -s "${FULLPATH}" ]; then
	    # process wav into png
            PNGFILE=$(sox_spectrogram ${FULLPATH})
            if [ ! -z "${PNGFILE}" ] && [ -s "${PNGFILE}" ]; then
              if [ "${DEBUG:-}" = true ]; then echo "--- INFO $0 $$ -- spectrogram created: ${PNGFILE}" &> /dev/stderr; fi
            else
	      echo "+++ WARN $0 $$ -- no PNG file for WAV: ${FULLPATH}; continuing..." >> ${LOGTO} 2>&1
	      continue
            fi
          else
            echo "+++ WARN $0 $$ -- no content in ${FULLPATH}; continuing..." >> ${LOGTO} 2>&1
            continue
          fi
          ;;
        *)
	  continue
	  ;;
      esac
    else
      echo "+++ WARN $0 $$ -- empty path" &> /dev/stderr
      continue
    fi
    # update output
    service_update "${OUTPUT_FILE}"
  done
done
