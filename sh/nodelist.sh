#!/bin/bash

###
### THIS SCRIPT PROVIDES AUTOMATED NODE LISTING
## ARGS: 
## 1. machine to inspect; default none; error
## 2. number of errors; default: 1
###
### REQUIRES: utilization of ssh and hzn CLI on test devices
###
### CONSUMES THE FOLLOWING ENVIRONMENT VARIABLES:
###
###


###
### MAIN
###

machine=${1}
if [ -z "${machine:-}" ]; then echo "*** ERROR -- $0 $$ -- no machine specified; exiting" &> /dev/stderr; exit 1; fi
errors=${2}
if [ -z "${errors:-}" ]; then errors=1; if [ "${DEBUG:-}" = true ]; then echo "+++ WARN -- $0 $$ -- number of errors unspecified; using default: ${errors}" &> /dev/stderr; fi; fi

ping -W 1 -c 1 ${machine} &> /dev/null
if [ $? ]; then
  NODE=$(ssh ${machine} 'hzn node list' 2> /dev/null | jq -c '{"state":.configstate.state}')
  if [ -z "${NODE}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine} is not a node" &> /dev/stderr; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine} is node: ${NODE}" &> /dev/stderr; fi
  fi
  if [ $(echo "${NODE}" | jq '.state==null') = true ]; then 
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine} is not configured" &> /dev/stderr; fi
  else
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine} state:" $(echo "${NODE}" | jq -r '.state') &> /dev/stderr; fi
  fi

  AGREEMENTS=$(ssh ${machine} 'hzn agreement list' 2> /dev/null | jq -c '{"agreements":[.[].workload_to_run]}')
  SERVICES=$(ssh ${machine} 'hzn service list 2> /dev/null')
  if [ -z "${SERVICES:-}" ]; then
    SERVICES='{"services":null}'
  else
    SERVICES=$(echo "${SERVICES}" | jq -c '{"services":[.[].url]}')
  fi
  ERRORS=$(ssh ${machine} 'hzn eventlog list 2> /dev/null')
  if [ -z "${ERRORS}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine}; no eventlog" &> /dev/stderr; fi
  fi
  ERRORS=$(echo "${ERRORS}" | jq -r '.[]' | egrep "Error" | head "-${errors:-1}" | awk -F':   ' 'BEGIN { printf("{\"errors\":["); x=0 } { if(x++>0) printf(","); s1=sprintf("%s",$1); gsub("\"","",s1); s2=sprintf("%s",$2); gsub("\"","",s2); printf("{\"time\":\"%s\",\"message\":\"%s\"}",s1,s2); } END { printf("]}") }'  | jq -c '.')

  CONTAINERS=$(ssh ${machine} 'docker ps --format "{{.Names}},{{.Image}}"' 2> /dev/null)
  if [ -z "${CONTAINERS}" ]; then
    if [ "${DEBUG:-}" = true ]; then echo "--- INFO -- $0 $$ -- machine: ${machine}; no containers" &> /dev/stderr; fi
  fi
  CONTAINERS=$(echo "${CONTAINERS}" | awk -F, 'BEGIN { printf("{\"containers\":["); x=0 } { if (x++>0) printf(","); printf("{\"name\":\"%s\",\"image\":\"%s\"}\n", $1, $2) } END { printf("]}")}')
  
  # produce output
  echo "[${NODE},${AGREEMENTS},${SERVICES},${ERRORS},${CONTAINERS}]" | jq 'map({(.|to_entries[].key|tostring):.|to_entries[].value})|add'

else
  echo "+++ WARN -- $0 $$ -- not found ${machine}" &> /dev/stderr
  echo '{"machine":"'${machine:-}'","error":"not found"}'
fi
