#!/bin/bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

##
## functions
##

source /usr/bin/hzn-setup-tools.sh

###
### hzn-setup-node.sh
### 

## read request
while read; do
  if [ -z "${REPLY:-}" ]; then continue; fi
  case "${REPLY}" in
    POST*)
	POST=true
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- received: ${REPLY}" >> ${LOGTO} 2>&1; fi
	continue
	;;
    Content-Length*)
	if [ "${POST:-false}" = true ]; then
	  # size being sent
	  BYTES=$(echo "${REPLY}" | sed 's/.*: \([0-9]*\).*/\1/')
	  # margin
	  BYTES=$((BYTES+2))
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- content length: ${BYTES}" >> ${LOGTO} 2>&1; fi
	  break;
        fi
	continue
	;;
    GET*)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- received: ${REPLY}" >> ${LOGTO} 2>&1; fi
	POST=false
	break
	;;
    *)
	continue
	;;
  esac
done

## check if handling a post
if [ "${POST:-false}" = true ]; then
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- reading ${BYTES} bytes" >> ${LOGTO} 2>&1; fi
  ## read request
  INPUT=$(dd count=${BYTES} bs=1 | tr '\n' ' ' | tr '\r' ' ')
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- processing: ${INPUT}" >> ${LOGTO} 2>&1; fi
  ## validate JSON
  INPUT=$(echo "${INPUT:-null}" | jq -c '.')
  if [ ! -z "${INPUT}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- valid: ${INPUT}" >> ${LOGTO} 2>&1; fi
    ## generate response
    RESPONSE='{"exchange":"'${HZN_SETUP_EXCHANGE:-none}'","org":"'${HZN_SETUP_ORG:-none}'","pattern":"'${HZN_SETUP_PATTERN:-none}'"}'
    ## process input
    NODE=$(hzn_setup_process "${INPUT}")
    ## update response
    if [ -z "${NODE:-}" ] || [ "${NODE:-}" = 'null' ]; then
      RESPONSE=$(echo "${RESPONSE}" | jq '.node=null|.error="not found"')
    else
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- approved node:" $(echo "${NODE}" | jq -c '.' ) >> ${LOGTO} 2>&1; fi
      RESPONSE=$(echo "${RESPONSE}" | jq '.node='$(echo "${NODE:-null}" | jq -c '.'))
    fi
  fi
fi

if [ "${POST:-false}" = false ] || [ -z "${INPUT}" ]; then
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- error: ${INPUT}" >> ${LOGTO} 2>&1; fi
  ## generate error
  RESPONSE='{"error":"POST only valid JSON"}'
fi

## iff DEBUG add input received
if [ "${DEBUG:-}" = true ]; then RESPONSE=$(echo "${RESPONSE:-null}" | jq '.|.input='${INPUT:-null}); fi

## add date
RESPONSE=$(echo "${RESPONSE}" | jq '.|.date='$(date +%s))

## calculate size
SIZ=$(echo "${RESPONSE}" | wc -c | awk '{ print $1 }')
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- output size: ${SIZ}" >> ${LOGTO} 2>&1; fi

## send response
echo "HTTP/1.1 200 OK"
echo "Content-Type: application/json; charset=ISO-8859-1"
echo "Content-length: ${SIZ}" 
echo "Access-Control-Allow-Origin: *"
echo ""
echo "${RESPONSE:-error}"
