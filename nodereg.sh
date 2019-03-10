#!/bin/bash

node_status()
{
  machine=${1}
  hzn=$(ssh ${machine} 'command -v hzn')
  if [ ! -z "${hzn}" ]; then
    state=$(ssh ${machine} 'hzn node list 2> /dev/null' | jq -c '.')
  fi
  if [ -z "${state:-}" ]; then state='null'; fi
  echo ${state}
}

node_state()
{
  machine=${1}
  state=$(node_status ${machine} | jq -r '.configstate.state')
  if [ -z "${state:-}" ]; then state='null'; fi
  echo ${state}
}

node_purge()
{
  machine=${1}
  echo "--- INFO -- $0 $$ -- purging ${machine}" &> /dev/stderr
  ssh ${machine} 'hzn unregister -f -r' &> /dev/null
  ssh ${machine} 'sudo apt-get remove -y bluehorizon horizon horizon-cli' &> /dev/null
  ssh ${machine} 'sudo apt-get purge -y bluehorizon horizon horizon-cli' &> /dev/null
}

node_install()
{
  machine=${1}
  echo "--- INFO -- $0 $$ -- installing ${machine}" &> /dev/stderr
  ssh ${machine} 'sudo apt-get update' &> /dev/null
  ssh ${machine} 'sudo apt-get upgrade -y' &> /dev/null
  ssh ${machine} 'sudo apt-get install -y bluehorizon' &> /dev/null
}

node_register()
{
  machine=${1}
  echo "--- INFO -- $0 $$ -- registering ${machine} with pattern ${SERVICE_NAME}" &> /dev/stderr
  scp ${INPUT} ${machine}:/tmp/input.json &> /dev/null
  echo hzn register ${HZN_ORG_ID} -u iamapikey:${HZN_EXCHANGE_APIKEY} ${HZN_ORG_ID}/${SERVICE_NAME} -f /tmp/input.json -n "${machine%.*}:null" &> /dev/stderr
  ssh ${machine} hzn register ${HZN_ORG_ID} -u iamapikey:${HZN_EXCHANGE_APIKEY} ${HZN_ORG_ID}/${SERVICE_NAME} -f /tmp/input.json -n "${machine%.*}:null" &> /dev/null
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
    configuring|unconfiguring)
      node_purge ${machine}
      ;;
    configured)
      echo "--- INFO -- $0 $$ -- ${machine} -- configured" $(node_status ${machine}) &> /dev/stderr
      ;;
    *)
      echo "+++ WARN -- $0 $$ -- ${state} ${machine} with ${SERVICE_NAME}" &> /dev/stderr
      ;;
  esac
  state=$(node_state ${machine})
  echo ${state}
}

if [ -z "${HZN_EXCHANGE_APIKEY}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable HZN_EXCHANGE_APIKEY"; exit 1; fi
if [ -z "${SERVICE_NAME}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable SERVICE_NAME"; exit 1; fi
if [ -z "${HZN_ORG_ID}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable HZN_ORG_ID"; exit 1; fi
if [ -z "${INPUT}" ]; then echo "*** ERROR -- $0 $$0 -- set environment variable INPUT"; exit 1; fi

###
### MAIN
###

machine=${1}
echo "--- INFO -- $0 $$ -- ${machine}" &> /dev/stderr
state=$(node_update ${machine}) 
while [ "${state}" != 'configured' ]; do
  echo "--- INFO -- $0 $$ -- machine: ${machine}; state: ${state}" &> /dev/stderr
  state=$(node_update "${machine}") 
done

