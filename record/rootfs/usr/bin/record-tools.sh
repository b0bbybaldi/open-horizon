#!/bin/bash

record_sound()
{
  OUTPUT=$(mktemp).wav
  arecord  -D ${RECORD_DEVICE} -d ${RECORD_DURATION} ${OUTPUT}
  echo ${OUTPUT}
}

if [ -z "${1:-}" ]; then OUTPUT=$(mktemp); else OUTPUT=${1}; fi
RECORD_DEVICE='plughw:1'
RECORD_DURATION=5

