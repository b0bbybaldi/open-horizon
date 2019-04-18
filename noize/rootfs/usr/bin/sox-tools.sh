#!/usr/bin/env bash

###
### mkspectrogram.sh
###

sox_spectrogram()
{
  if [ ! -z "${1:-}" ]; then 
    SOX_WAVNAME="${SOX_WAVFILE%%.}"
    SOX_PNGFILE="${SOX_WAVNAME}.png"
    rm -f "${SOX_PNGFILE}"
    if [ -z "${2:-}" ]; then SOX_TITLE="SPECTROGRAM OF ${SOX_WAVNAME}"; fi
    if [ -s "${SOX_WAVFILE}" ]; then
      sox "${SOX_WAVFILE}" -n spectrogram -t "${SOX_TITLE}" -o ${SOX_PNGFILE}
    else
      if [ "${DEBUG:-}" = true ]; then echo "*** ERROR $0 $$ -- no WAV file found: ${SOX_WAVFILE}" &> /dev/stderr; fi
    fi
    if [ ! -s "${SOX_PNGFILE:-}" ]; then SOX_PNGFILE=; fi
  fi
  echo "${SOX_PNGFILE:-}"
}

## detect and record noise forever
sox_detect_record()
{
  PID=0
  if [ -z "${1:-}" ]; then 
    if [ "${DEBUG}" = true ]; then echo "*** ERROR $0 $$ -- no directory argument provided" &> /dev/stderr
  else
    SOX_DIRECTORY="${1}"
    if [ ! -d "${SOX_DIRECTORY}" ]; then
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN $0 $$ -- no directory: ${SOX_DIRECTORY}; creating" &> /dev/stderr
      mkdir -p ${SOX_DIRECTORY}"
    fi
    if [ -z "${2:-}" ]; then SOX_START_LEVEL='1.0'; fi
    if [ -z "${3:-}" ]; then SOX_START_SECONDS='0.1'; fi
    if [ -z "${4:-}" ]; then SOX_FINISH_LEVEL='1.0' ; fi
    if [ -z "${5:-}" ]; then SOX_FINISH_SECONDS='5.0'; fi
    if [ ! -z "${6:-}" ]; then SOX_FREQUENCY_MIN="sinc ${6}"; fi
    if [ ! -z "${7:-}" ]; then SOX_SAMPLE_RATE='19200'; else SOX_SAMPLE_RATE=${7}; fi
    rec -c1 \
	-r ${SOX_SAMPLE_RATE} \
	${TMPDIR}/${SOX_DIRECTORY}/noise.wav \
	silence  \
	1 ${SOX_START_SECONDS} ${SOX_START_LEVEL}'%' \
	1 ${SOX_FINISH_SECONDS} ${SOX_FINISH_LEVEL}'%' \
	: newfile : restart &> /dev/stderr &
    PID=$!
  fi
  echo "${PID}"
}
