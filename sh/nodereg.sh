#!/bin/bash

###
### THIS SCRIPT PROVIDES AUTOMATED NODE REGISTRATION
###
### REQUIRES UTILIZATION OF SSH AND HZN CLI
###
### CONSUMES THE FOLLOWING ENVIRONMENT VARIABLES:
###
### + HZN_EXCHANGE_URL
### + HZN_ORG_ID
### + HZN_EXCHANGE_APIKEY
###

node_alive()
{
  machine=${1}
  if [ ! -z "${machine}" ]; then
    $(ping -W 1 -c 1 ${machine} &> /dev/null)
    RESULT=$?
  fi
  echo ${RESULT:-1} 
}

node_status()
{
  machine=${1}
  if [ $(node_alive ${machine}) == 0 ]; then
    hzn=$(ssh ${machine} 'command -v hzn')
    if [ ! -z "${hzn}" ]; then
      state=$(ssh ${machine} 'hzn node list 2> /dev/null')
    fi
    if [ -z "${state:-}" ]; then state='null'; fi
  else
    state='offline'
  fi
  echo ${state}
}

node_state()
{
  machine=${1}
  state=$(node_status ${machine})
  if [ -z "${state:-}" ] || [ "${state}" == 'null' ]; then state='null'; else state=$(echo "${state}" | jq -r '.configstate.state'); fi
  echo ${state}
}

node_purge()
{
  machine=${1}
  node_unregister ${machine}
  if [ $(node_is_debian ${machine}) = true ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- purging ${machine}" &> /dev/stderr; fi
    ssh ${machine} 'sudo apt purge -y bluehorizon horizon horizon-cli' # &> /dev/null
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- ${1} - non-DEBIAN; purge manually" &> /dev/stderr; fi
  fi
}

node_is_debian()
{
  result='false'
  debian=$(ssh ${1} 'lsb_release &> /dev/null && echo $?')
  if [ ! -z "${debian}" ] && [ "${debian}" == '0' ]; then result='true'; fi
  echo "${result}"
}

node_install()
{
  if [ $(node_is_debian ${1}) = true ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${1} - DEBIAN" &> /dev/stderr; fi
    node_aptget ${1}
  else
    if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- ${1} - non-DEBIAN; install manually" &> /dev/stderr; fi
  fi
}

node_aptget()
{
  machine=${1}
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- installing ${machine}" &> /dev/stderr; fi
  ssh ${machine} 'APT_REPO=updates \
  && APT=/etc/apt/sources.list.d/bluehorizon.list \
  && URL=http://pkg.bluehorizon.network \
  && KEY=${URL}/bluehorizon.network-public.key \
  && wget -qO - "${KEY}" | sudo apt-key add - \
  && echo "deb [arch=armhf,arm64,amd64,ppc64el] ${URL}/linux/ubuntu xenial-${APT_REPO} main" > /tmp/$$ \
  && sudo mv /tmp/$$ "${APT}"'
  ssh ${machine} 'sudo apt-get update &> update.log'
  ssh ${machine} 'sudo apt-get upgrade -y &> upgrade.log'
  ssh ${machine} 'sudo apt-get install -y bluehorizon &> install.log'
}

node_unregister()
{
  machine=${1}
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- unregistering ${machine}" &> /dev/stderr; fi
  ssh ${machine} 'hzn unregister -f -r &> unregister.log &'
}

node_register()
{
  machine=${1}
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- registering ${machine} with pattern: ${SERVICE_NAME}; input: ${INPUT}" &> /dev/stderr; fi
  scp ${INPUT} ${machine}:input.json &> /dev/null
  ssh ${machine} "hzn register ${HZN_ORG_ID} -u iamapikey:${HZN_EXCHANGE_APIKEY} ${SERVICE_NAME} -f input.json -n ${machine%.*}:null &> register.log"
}

node_update()
{
  machine=${1}
  state=$(node_state ${machine})
  case ${state} in
    null)
      node_install ${machine}
      ;;
    unconfigured)
      node_register ${machine}
      ;;
    configuring)
      pattern=$(node_status ${machine} | jq -r '.pattern')
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${machine} -- ${state} ${pattern}" &> /dev/stderr; fi
      ssh ${machine} 'hzn eventlog list 2> /dev/stderr' | jq -c '.[]?'
      node_unregister ${machine}
      sleep 10
      ;;
    unconfiguring)
      pattern=$(node_status ${machine} | jq -r '.pattern')
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${machine} -- ${state} ${pattern}" &> /dev/stderr; fi
      node_purge ${machine}
      ;;
    configured)
      pattern=$(node_status ${machine} | jq -r '.pattern')
      if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${machine} -- configured with ${pattern}" &> /dev/stderr; fi
      if [ "${SERVICE_NAME}" == "${pattern}" ]; then
        URL=$(ssh ${machine} hzn service list | jq -r '.[]?.url' | while read; do if [ "${REPLY##*.}" == "${pattern##*/}" ]; then echo "${REPLY}"; fi; done)
        VER=$(ssh ${machine} hzn service list | jq -r '.[]?|select(.url=="'${URL}'").version' 2> /dev/null)
        if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${machine} -- version: ${VER}; url: ${URL}" &> /dev/stderr; fi
      else
	node_unregister ${machine}
        sleep 30
      fi
      ;;
    *)
      if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ --  ${machine} state: ${state}" &> /dev/stderr; fi
      ;;
  esac
  state=$(node_state ${machine})
  echo ${state}
}

if [ -z "${HZN_ORG_ID}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable HZN_ORG_ID"; exit 1; fi
if [ -z "${HZN_EXCHANGE_APIKEY}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable HZN_EXCHANGE_APIKEY"; exit 1; fi

if [ -z "${SERVICE_NAME}" ]; then 
  if [ ! -z "${2}" ]; then SERVICE_NAME="${2}"; else echo "*** ERROR -- $0 $$0 -- set environment variable SERVICE_NAME"; exit 1; fi
fi
if [ "${SERVICE_NAME##*/}" == "${SERVICE_NAME}" ]; then
  SERVICE_NAME="${HZN_ORG_ID}/${SERVICE_NAME}"
  if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- missing service organization; using ${SERVICE_NAME}" &> /dev/stderr; fi
fi
if [ -z "${INPUT}" ]; then 
  if [ ! -z "${3}" ]; then INPUT="${3}"; else  echo "*** ERROR -- $0 $$0 -- set environment variable INPUT"; exit 1; fi
fi

###
### MAIN
###

machine=${1}
if [ -z "${machine}" ]; then echo "*** ERROR -- $0 $$ -- no machine specified; exiting" &> /dev/stderr; exit 1; fi

OUT=$(ping -W 1 -c 1 ${machine})
if [ $? != 0 ]; then echo "*** ERROR -- $0 $$ -- machine ${machine} not found on network; exiting" &> /dev/stderr; exit 0; fi
IPADDR=$(echo "${OUT}" | head -1 | sed 's|.*(\([^)]*\)).*|\1|')
if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- ${machine} at IP: ${IPADDR:-}" &> /dev/stderr; fi

state=$(node_update ${machine})
while [ "${state}" != 'configured' ]; do
  if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine}; state: ${state}" &> /dev/stderr; fi
  state=$(node_update "${machine}") 
done

