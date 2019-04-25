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

hzn_setup_exchange_node_list()
{
  if [ ! -z "${1}" ]; then
    node="${1}"
    id=$(echo "${node}" | jq -r '.device')
    node=$(curl -fsSL -u ${HZN_SETUP_ORG}/iamapikey:${HZN_SETUP_APIKEY} ${HZN_SETUP_EXCHANGE}/orgs/${HZN_SETUP_ORG}/nodes/${id} 2> /dev/null)
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- hzn_setup_exchange_node_list:" $(echo "${node}" | jq -c '.') >> ${LOGTO} 2>&1; fi
  fi
  echo "${node:-}"
}

hzn_setup_node_create()
{
  id=$(echo "${node}" | jq -r '.device')
  token=$(echo "${node}" | jq -r '.token')
  org=${HZN_SETUP_ORG}
  heu=${org}/iamapikey:${HZN_SETUP_APIKEY}
  cmd="hzn exchange node create -o ${org} -u ${heu} -n ${id}:${token}"
  out=$(HZN_EXCHANGE_URL=${HZN_SETUP_EXCHANGE} && ${cmd} 2>&1)
  if [ ! -z "${out}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- failure: ${cmd}; failed: ${out}" >> ${LOGTO} 2>&1; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- success: ${cmd}" >> ${LOGTO} 2>&1; fi
    node=$(hzn_setup_exchange_node_list "${node}")
    if [ ! -z "${node:-}" ] && [ $(echo "${node:-null}" | jq '.nodes|length') -gt 0 ]; then
      node=$(echo "${node}" | jq -c '.nodes|to_entries|first|.value.id=.key|.value')
    fi
  fi
  echo "${node:-}"
}

hzn_setup_node_valid()
{
  echo true
}

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
          node=$(echo "${node:-null}" | jq '.token="'${token:-}'"|.timestamp="'$(date +"%D-%T")'"')
	  exchange=$(hzn_setup_node_create "${node}")
	  node=$(echo "${node}" | jq '.exchange='${exchange:-null})
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

hzn_setup_lookup()
{
  args=(${*})
  if [ ${#args[@]} -gt 0 ]; then
    serial="${args[0]}"
  fi
  if [ ${#args[@]} -gt 1 ]; then
    i=1; while [ ${i} -le ${#args[@]} ]; do
      macs=(${macs:-} ${args[${i}]})
      i=$((i+1))
    done
    if [ ${#macs[@]} -gt 0 ]; then
      node=$(echo "${macs[0]}" | sed 's/://g')
      node="${HZN_SETUP_BASENAME:-}${node}"
    fi
  fi
  echo '{"serial":"'${serial}'","device":"'${node:-}'"}'
}

hzn_setup_process()
{
  input="${1}"
  ## process input
  serial=$(echo "${input}" | jq -r '.serial')
  mac=($(echo "${input}" | jq -r '.mac[]?'))

  ## lookup device
  node=$(hzn_setup_lookup ${serial} ${mac})

  if [ -z "${node:-}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- no node found; serial: ${serial}; mac: ${mac}" >> ${LOGTO} 2>&1; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- node found: ${node}" >> ${LOGTO} 2>&1; fi
    node=$(hzn_setup_approve ${node})
  fi

  echo "${node:-null}"
}

