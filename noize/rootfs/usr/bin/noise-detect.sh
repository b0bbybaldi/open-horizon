#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

###
### noise-detect.sh - create multiple WAV files named `noise###.wav`
###
### NOISE_START_SECONDS - number of seconds of non-silence to start noiseing
### NOISE_START_LEVEL - percentage change between silence and non-silence
### NOISE_FINISH_LEVEL - percentage change between non-silence and silence
### NOISE_FINISH_SECONDS - number of seconds of silence after noise detected to stop noiseing
### NOISE_FREQUENCY_MIN - use high-pass filter to remove sounds below threshold
### NOISE_FILENAME - alternative file-name template; default `noise`
###

if [ -z "${NOISE_SAMPLE_RATE:-}" ]; then NOISE_SAMPLE_RATE='19200'; fi
if [ -z "${NOISE_START_SECONDS:-}" ]; then NOISE_START_SECONDS='0.1'; fi
if [ -z "${NOISE_START_LEVEL:-}" ]; then NOISE_START_LEVEL='1'; fi
if [ -z "${NOISE_FINISH_LEVEL:-}" ]; then NOISE_FINISH_LEVEL='1' ; fi
if [ -z "${NOISE_FINISH_SECONDS:-}" ]; then NOISE_FINISH_SECONDS='5.0'; fi
if [ ! -z ${NOISE_FREQUENCY_MIN:-} ]; then NOISE_FREQUENCY_MIN="sinc ${NOISE_FREQUENCY_MIN}"; fi

# hzn-tools.sh
source /usr/bin/hzn-tools.sh
source /usr/bin/sox-tools.sh

###
### MAIN
###

SOX_SAMPLE_RATE=${NOISE_SAMPLE_RATE}

DIR=$(mktemp -d)

sox_detect_record  ${DIR}
