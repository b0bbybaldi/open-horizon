#!/usr/bin/env bash

# TMPDIR
if [ -d '/tmpfs' ]; then TMPDIR='/tmpfs'; else TMPDIR='/tmp'; fi

# logging
if [ -z "${LOGTO:-}" ]; then LOGTO="${TMPDIR}/${0##*/}.log"; fi

##
## functions
##

hzn_setup_exchange_nodes()
{
  ALL=$(curl -fsSL -u ${HZN_SETUP_ORG}/iamapikey:${HZN_SETUP_APIKEY} ${HZN_SETUP_EXCHANGE}/orgs/${HZN_SETUP_ORG}/nodes 2> /dev/null)
  ENTITYS=$(echo "${ALL}" | jq '{"nodes":[.nodes | objects | keys[]] | unique}' | jq -r '.nodes[]')
  OUTPUT='{"nodes":['
  i=0; for ENTITY in ${ENTITYS}; do
    if [[ $i > 0 ]]; then OUTPUT="${OUTPUT}"','; fi
    OUTPUT="${OUTPUT}"$(echo "${ALL}" | jq '.nodes."'"${ENTITY}"'"' | jq -c '.id="'"${ENTITY}"'"')
    i=$((i+1))
  done
  OUTPUT="${OUTPUT}"']}'
  echo "${OUTPUT}" | jq -c '.'
}

hzn_setup_node_lookup()
{
  id="${1}"
  if [ ! -z "${id:-}" ]; then
    nodes=$(curl -fsSL -u ${HZN_SETUP_ORG}/iamapikey:${HZN_SETUP_APIKEY} ${HZN_SETUP_EXCHANGE}/orgs/${HZN_SETUP_ORG}/nodes/${id})
    if [ ! -z "${nodes:-}" ]; then
      node=$(echo "${nodes}" | jq '.nodes|to_entries|first|.value.id=.key|.value')
    fi
  fi
  echo "${node:-}"
}

## create node in exchange
hzn_setup_node_create()
{
  if [ ! -z "${1}" ]; then
    node="${1}"
    # setup command
    id=$(echo "${node}" | jq -r '.device')
    token=$(echo "${node}" | jq -r '.token')
    org=${HZN_SETUP_ORG}
    heu=${org}/iamapikey:${HZN_SETUP_APIKEY}
    # test args
    if [ ! -z "${id:-}" ] && [ ! -z "${token:-}" ] && [ ! -z "${org:-}" ] && [ ! -z "${heu:-}" ]; then
      # setup command
      cmd="hzn exchange node create -o ${org} -u ${heu} -n ${id}:${token}"
      # run command
      out=$(HZN_EXCHANGE_URL=${HZN_SETUP_EXCHANGE} && ${cmd} 2>&1)
      # test output
      if [ !? != 0 ] && [ ! -z "${out}" ]; then
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- failure: ${cmd}; failed: ${out}" >> ${LOGTO} 2>&1; fi
      else
	# sleep 1
        node=$(hzn_setup_node_lookup "${id}")
        if [ ! -z "${node:-}" ] && [ $(echo "${node:-null}" | jq '.nodes|length') -gt 0 ]; then
          node=$(echo "${node}" | jq -c '.nodes|to_entries|first|.value.id=.key|.value')
        else
          if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- could not find device: ${id}" >> ${LOGTO} 2>&1; fi
        fi
      fi
    fi
  fi
  echo "${node:-}"
}

hzn_setup_node_valid()
{
  echo true
}

## approve (or not)
hzn_setup_approve()
{
  node="${1}"
  if [ ! -z "${node:-}" ] && [ "${node}" != 'null' ]; then
    id=$(echo "${node}" | jq -r '.device')
    if [ ! -z "${id}" ]; then
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- testing node: ${id}" >> ${LOGTO} 2>&1; fi
      case ${HZN_SETUP_APPROVE} in
        auto)
          if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- auto-approving node: ${id}" >> ${LOGTO} 2>&1; fi
	  token=$(echo "${node}" | jq -r '.serial' | sha1sum | awk '{ print $1 }')
          node=$(echo "${node}" | jq '.token="'"${token}"'"')
	  exchange=$(hzn_setup_node_create "${node}")
	  node=$(echo "${node}" | jq '.exchange='"${exchange:-null}")
	  ;;
        *)
	  ;;
      esac
    else
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- invalid id: ${node}" >> ${LOGTO} 2>&1; fi
    fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- invalid node" >> ${LOGTO} 2>&1; fi
  fi
  echo "${node:-}"
}

## lookup node
hzn_setup_lookup()
{
  # should search the DB or the exchange
  if [ ! -z "${1:-}" ] && [ ! -z "${2:-}" ]; then
    serial="${1}"
    mac=$(echo "${2}" | sed 's/://g')
    device="${HZN_SETUP_BASENAME:-}${mac}"
    node=$(hzn_setup_node_lookup "${device}")
    if [ ! -z "${node:-}" ]; then
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_lookup: found in exchange: ${device}" >> ${LOGTO} 2>&1; fi
    else
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_lookup: not found in exchange: ${device}" >> ${LOGTO} 2>&1; fi
      node='null'
    fi
  fi
  echo '{"serial":"'${serial:-}'","device":"'${device:-}'","exchange":'${node:-}'}'
}

hzn_setup_process()
{
  if [ ! -z "${1}" ]; then
    input="${1}"
    ## process input
    serial=$(echo "${input}" | jq -r '.serial')
    mac=($(echo "${input}" | jq -r '.mac'))

    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_process: serial: ${serial}; mac: ${mac}" >> ${LOGTO} 2>&1; fi

    ## lookup device
    node=$(hzn_setup_lookup ${serial} ${mac})

    if [ -z "${node:-}" ]; then
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_process: no device found; serial: ${serial}; mac: ${mac}" >> ${LOGTO} 2>&1; fi
    elif [ $(echo "${node}" | jq '.exchange!=null') = true ]; then
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_process: node already in exchange: ${node}" >> ${LOGTO} 2>&1; fi
    fi
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_process: device found; not in exchange" >> ${LOGTO} 2>&1; fi
    node=$(hzn_setup_approve "${node}")
  fi
  echo "${node:-null}"
}

