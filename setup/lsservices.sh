#!/bin/bash
if [ -z $(command -v jq) ]; then
  echo "*** ERROR $0 $$ -- please install jq"
  exit 1
fi

if [ "${0%/*}" != "${0}" ]; then
  CONFIG="${0%/*}/horizon.json"
else
  CONFIG="horizon.json"
fi
if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}" &> /dev/stderr
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}; run mkconfig.sh" &> /dev/stderr
    exit 1
  fi
else
  CONFIG="${1}"
fi
if [ ! -s "${CONFIG}" ]; then
  echo "*** ERROR $0 $$ -- configuration file empty: ${1}" &> /dev/stderr
  exit 1
fi

HZN_EXCHANGE_APIKEY=$(jq -r '.exchanges[]|select(.id=="alpha")|.password' "${CONFIG}")
if [ -z "${HZN_EXCHANGE_APIKEY}" ] || [ "${HZN_EXCHANGE_APIKEY}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_EXCHANGE_APIKEY" &> /dev/stderr
  exit 1
fi
  
HZN_EXCHANGE_URL=$(jq -r '.exchanges[]|select(.id=="alpha")|.url' "${CONFIG}")
if [ -z "${HZN_EXCHANGE_URL}" ] || [ "${HZN_EXCHANGE_URL}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_EXCHANGE_URL" &> /dev/stderr
  exit 1
fi

HZN_EXCHANGE_ORG=$(jq -r '.exchanges[]|select(.id=="alpha")|.org' "${CONFIG}")
if [ -z "${HZN_EXCHANGE_ORG}" ] || [ "${HZN_EXCHANGE_ORG}" == "null" ]; then
  echo "*** ERROR $0 $$ -- invalid HZN_EXCHANGE_ORG" &> /dev/stderr
  exit 1
fi

ALL=$(curl -sL -u "${HZN_EXCHANGE_ORG}/iamapikey:${HZN_EXCHANGE_APIKEY}" "${HZN_EXCHANGE_URL}/orgs/${HZN_EXCHANGE_ORG}/services")
ENTITYS=$(echo "${ALL}" | jq '{"services":[.services | objects | keys[]] | unique}' | jq -r '.services[]')  
OUTPUT='{"services":['
i=0; for ENTITY in ${ENTITYS}; do 
  if [[ $i > 0 ]]; then OUTPUT="${OUTPUT}"','; fi
  OUTPUT="${OUTPUT}"$(echo "${ALL}" | jq '.services."'"${ENTITY}"'"' | jq -c '.id="'"${ENTITY}"'"')
  i=$((i+1))
done 
OUTPUT="${OUTPUT}"']}'
echo "${OUTPUT}" | jq -c '.'
