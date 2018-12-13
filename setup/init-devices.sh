#!/bin/bash

DEBUG=
VERBOSE=

###
### default EXCHANGE URL
###

HZN_EXCHANGE_URL="https://alpha.edge-fabric.com/v1"

## check for necessary tooling
if [[ ! -e "/usr/local/bin/nmap" && ! -e "/usr/bin/nmap" ]]; then
  echo '*** ERROR: No nmap(8); install using brew or apt' &> /dev/stderr
  exit 1
fi

## MACOS is strange
if [[ "$OSTYPE" == "darwin" && "$VENDOR" == "apple" ]]; then
  BASE64_ENCODE='base64'
else
  BASE64_ENCODE='base64 -w 0'
fi

if [[ -n "${1}" ]]; then
  config="${1}"
else
  config="horizon.json"
fi
if [[ ! -s "${config}"  ]]; then
  echo "Cannot find configuration file" &> /dev/stderr
  exit 1
fi

###
### DISTRIBUTION config
###

SETUP_ID=$(jq -r '.setup' "${config}")
if [ -n "${SETUP_ID}" ]; then
  HORIZON_SETUP_URL=$(jq -r '.setups[]|select(.id=="'$SETUP_ID'").url' "${config}")
  if [ -z "${HORIZON_SETUP_URL}" ]; then
    echo "*** ERROR: cannot find URL for setup id ${SETUP_ID} in ${config}" &> /dev/stderr
    exit 1
  fi
else
  echo "*** ERROR: no setup specified" &> /dev/stderr
  exit 1
fi

## VENDOR for auto-discovery
VENDOR_ID=$(jq -r '.vendor' "${config}")
if [ -n "${VENDOR_ID}" ]; then
  VENDOR_TAG=$(jq -r '.vendors[]|select(.id=="'"${VENDOR_ID}"'").tag' "${config}")
  if [ -z "${VENDOR_TAG}" ]; then
    echo "*** ERROR: cannot find tag for vendor id ${VENDOR_ID} in configuration ${config}" &> /dev/stderr
    exit 1
  fi
else
  echo "+++ WARN: no vendor specified for auto-discovery in ${config}" &> /dev/stderr
  VENDOR_TAG=
fi

# NETWORK
if [[ -n "${2}" ]]; then
  net="${2}"
else
  net="192.168.1.0/24"
fi
echo "--- INFO: executing: $0 ${config} $net" &> /dev/stderr

TTL=300 # seconds
SECONDS=$(date "+%s")
DATE=$(echo $SECONDS \/ $TTL \* $TTL | bc)
TMP="/tmp/${0##*/}.$$"

# make temporary directory for working files
mkdir -p "$TMP"
if [[ ! -d "$TMP" ]]; then
  echo "FATAL: no $TMP" &> /dev/stderr
  exit 1
fi

out="${TMP%.*}.$DATE.txt"
if [[ ! -s "$out" ]]; then
  rm -f "${out%.*}".*.txt
  if [[ $(whoami) != "root" ]]; then
    echo "--- INFO: scanning network ${net}" &> /dev/stderr
    sudo nmap -sn -T5 "$net" > "$out"
  else
    nmap -sn -T5 "$net" > "$out"
  fi
fi

if [[ ! -s "$out" ]]; then
  echo 'ERROR: no nmap(8) output for '"$net" &> /dev/stderr
  exit 1
fi

MACS=$(egrep MAC "$out" | awk '{ print $3 }' | sort | uniq)
MAC_ARRAY=($(echo ${MACS}))
MAC_COUNT=${#MAC_ARRAY[@]}
echo "--- INFO: found ${MAC_COUNT} devices on LAN ${net}" &> /dev/stderr

# get nodes
NODES=$(jq -r '.nodes[]?.mac' "${config}")
if [ -z "${NODES}" ] || [ "${NODES}" == 'null' ]; then
  echo "+++ WARN: no nodes in configuration" &> /dev/stderr
  NODE_COUNT=0
else
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: existing nodes:" $(echo ${NODES} | fmt -256) &> /dev/stderr; fi
  NODE_ARRAY=($(echo ${NODES}))
  NODE_COUNT=${#NODE_ARRAY[@]}
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found ${NODE_COUNT} nodes by MAC in configuration" &> /dev/stderr; fi
fi

# find all devices from specified vendor
if [ -n "${VENDOR_TAG}" ]; then
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: searching for all from ${VENDOR_TAG}" &> /dev/stderr; fi
  vmacs=$(egrep "${VENDOR_TAG}" "${out}" | awk '{ print $3 }' | sort | uniq)
fi

if [ -n "${vmacs}" ]; then
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${VENDOR_TAG} devices found:" $(echo ${vmacs} | fmt -256) &> dev/stderr; fi
  JSON=; for vmac in ${vmacs}; do 
    FOUND=; for NODE in ${NODES}; do
      if [ "${vmac}" == "${NODE}" ]; then FOUND="true"; break; fi
    done
    if [ -z "${FOUND}" ]; then
      if [ -n "${JSON}" ]; then JSON="${JSON}"','; else JSON='['; i=$((NODE_COUNT)); fi
      i=$((i+1))
      JSON="${JSON}"'{"id":"'"${VENDOR_ID}-${i}"'","mac":"'"${vmac}"'"}'
    else
      if [ -n "${DEBUG}" ]; then echo echo "??? DEBUG: node ${vmac} in configuration ${config}" &> /dev/stderr; fi
    fi
  done

  if [ -n "${JSON}" ]; then 
    JSON="${JSON}"']'
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found" $(echo "${JSON}" | jq '.|length') "new ${VENDOR_TAG} nodes" &> /dev/stderr; fi
    jq '.nodes+='"${JSON}" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: updated configuration ${config}" &> /dev/stderr; fi
  fi
else
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: no ${VENDOR_TAG} devices found" &> /dev/stderr ; fi
fi

# update 
NODES=$(jq -r '.nodes[]?.mac' "${config}")
if [ -z "${NODES}" ]; then
  echo "+++ WARN: no nodes (MACs) in configuration" &> /dev/stderr
  NODE_COUNT=0
else
  NODE_ARRAY=($(echo ${NODES}))
  NODE_COUNT=${#NODE_ARRAY[@]}
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: found ${NODE_COUNT} nodes (MACs) in configuration" &> /dev/stderr; fi
fi

echo "--- INFO: total of ${NODE_COUNT} nodes in configuration ${config}" &> /dev/stderr

###
### ITERATE OVER ALL MACS on LAN
###

for MAC in ${MACS}; do 
  # get ipaddr
  client_ipaddr=$(egrep -B 2 "$MAC" "$out" | egrep "Nmap scan" | head -1 | awk '{ print $5 }')
  # search for device by MAC
  id=$(jq -r '.nodes[]|select(.mac=="'$MAC'").id' "${config}")
  if [ -z "$id" ]; then
    if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: NOT FOUND; MAC: $MAC; IP: $client_ipaddr" &> /dev/stderr; fi
    continue
  else
    # get ip address from nmap output file
    echo "--- INFO: ${id}: FOUND at MAC: $MAC; IP $client_ipaddr" &> /dev/stderr
    # remove from known hosts
    if [ -s "${HOME}/.ssh/known_hosts" ]; then
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: removing $client_ipaddr from ${HOME}/.ssh/known_hosts" &> /dev/stderr; fi
      egrep -v "${client_ipaddr}" "${HOME}/.ssh/known_hosts" > $TMP/known_hosts
      mv -f $TMP/known_hosts ${HOME}/.ssh/known_hosts
    fi
  fi

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: searching for configuration" &> /dev/stderr; fi

  # find configuration which includes device
  conf=$(jq '.configurations[]|select(.nodes[].id=="'"${id}"'")' "${config}")
  if [[ -z "${conf}" || "${conf}" == "null" ]]; then
    echo "*** ERROR: ${id}: Cannot find node configuration for device: $id" &> /dev/stderr
    continue
  else
    # identify configuration
    conf_id=$(echo "$conf" | jq -r '.id')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: found configuration $conf_id" &> /dev/stderr; fi
  fi

  # find node state (cannot fail)
  node_state=$(jq '.nodes[]|select(.id=="'$id'")' "${config}")
  if [ -z "${node_state}" ] || [ "${node_state}" == 'null' ]; then
    echo "*** ERROR ${id}: found no existing node state; continuing..." &> /dev/stderr
    continue
  fi

  ## TEST STATUS
  config_keys=$(echo "$conf" | jq '.public_key!=null')
  config_ssh=$(echo "$node_state" | jq '.ssh!=null')
  config_security=$(echo "$node_state" | jq '.ssh.device!=null')
  config_software=$(echo "$node_state" | jq '.software!=null')
  config_exchange=$(echo "$node_state" | jq '.exchange.node!=null')
  config_network=$(echo "$node_state" | jq '.network!=null')

  ## CONFIGURATION KEYS
  if [[ ${config_keys} != "true" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: configuring KEYS for $conf_id" &> /dev/stderr; fi
    # test for existing keys
    if [[ ! -s "$conf_id" && ! -s "${conf_id}.pub" ]]; then
      # generate new key
      ssh-keygen -t rsa -f "$conf_id" -N "" &> /dev/null
      # test for success
      if [[ ! -s "$conf_id" || ! -s "$conf_id.pub" ]]; then
        echo "*** ERROR: ${id}: failed to create key files for $conf_id" &> /dev/stderr
        exit 1
      fi
    else
      if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: ${id}: using existing keys $conf_id" &> /dev/stderr; fi
    fi
    # save into configuration
    public_key='{ "encoding": "base64", "value": "'$(${BASE64_ENCODE} "${conf_id}.pub")'" }'

    jq '(.configurations[]|select(.id=="'"$conf_id"'").public_key)|='"${public_key}" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    private_key='{ "encoding": "base64", "value": "'$(${BASE64_ENCODE} "$conf_id")'" }'
    jq '(.configurations[]|select(.id=="'$conf_id'").private_key)|='"${private_key}" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    conf=$(jq '.configurations[]|select(.nodes[].id=="'$id'")' "${config}")
    # update status
    config_keys=$(echo "$conf" | jq '.public_key!=null')
  else
    if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: KEYS configured: ${config_keys}" &> /dev/stderr; fi
  fi
  # sanity
  if [[ "${config_keys}" != "true" ]]; then
    echo "FATAL: ${id}: failure to configure keys for $conf_id" &> /dev/stderr
    exit
  else
    public_key=$(echo "$conf" | jq '.public_key')
    private_key=$(echo "$conf" | jq '.private_key')
    if [ -n "${VERBOSE}" ]; then echo ">>> VERBOSE: ${conf_id}: KEYS configured" &> /dev/stderr; fi
  fi

  # process public key for device
  pke=$(echo "$public_key" | jq -r '.encoding')
  if [[ -n $pke && "$pke" == "base64" ]]; then
    public_keyfile="$TMP/${conf_id}.pub"
    if [[  ! -e "$public_keyfile"  ]]; then
      echo "$public_key" | jq -r '.value' | base64 --decode > "$public_keyfile"
      chmod 400 "$public_keyfile"
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${conf_id}: found existing keyfile: $public_keyfile" &> /dev/stderr; fi
    fi
  else
    echo "FATAL: ${id}: invalid public key encoding" &> /dev/stderr
    exit 1
  fi

  # process private key for device
  pke=$(echo "$private_key" | jq -r '.encoding')
  if [[ -n $pke && "$pke" == "base64" ]]; then
    private_keyfile="$TMP/${conf_id}"
    if [[  ! -e "$private_keyfile"  ]]; then
      echo "$private_key" | jq -r '.value' | base64 --decode > "$private_keyfile"
      chmod 400 "$private_keyfile"
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${conf_id}: found existing keyfile: ${private_keyfile}" &> /dev/stderr; fi
    fi
  else
    echo "FATAL: ${id}: invalid private key encoding" &> /dev/stderr
    exit 1
  fi

  # get configuration for identified node
  node_conf=$(echo "$conf" | jq '.nodes[]|select(.id=="'"$id"'")')

  # get default username and password for distribution associated with machine assigned to node
  mid=$(echo "$node_conf" | jq -r '.machine')
  did=$(jq -r '.machines[]|select(.id=="'$mid'").distribution' "${config}") 
  dist=$(jq '.distributions[]|select(.id=="'$did'")' "${config}")
  client_hostname=$(echo "$dist" | jq -r '.client.hostname')
  client_username=$(echo "$dist" | jq -r '.client.username')
  client_password=$(echo "$dist" | jq -r '.client.password')
  client_distro=$(echo "$dist" | jq '{"id":.id,"kernel_version":.kernel_version,"release_date":.release_date,"version":.version}')

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: machine = $mid; distribution = $did" &> /dev/stderr; fi

  ## CONFIG SSH
  if [ "${config_ssh}" == "true" ]; then
    # test access
    result=$(ssh -o "BatchMode yes" -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'whoami') 2> /dev/null
    if [[ -z "${result}" || "${result}" != "${client_username}" ]]; then
      echo "*** ERROR: ${id} SSH failed; cannot confirm identity ${client_username}; got: ${result}"
      continue
    fi
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SSH public key configured:" $(echo "$node_state" | jq -c '.ssh.id') &> /dev/stderr ; fi
  else
    # edit template ssh-copy-id 
    ssh_copy_id="$TMP/ssh-copy-id.exp"
    cat "ssh-copy-id.tmpl" \
      | sed 's|%%CLIENT_IPADDR%%|'"${client_ipaddr}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%CLIENT_PASSWORD%%|'"${client_password}"'|g' \
      | sed 's|%%PUBLIC_KEYFILE%%|'"${public_keyfile}"'|g' \
      > "$ssh_copy_id"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SSH attempting ssh-copy-id ${ssh_copy_id} to ${client_ipaddr}" &> /dev/stderr; fi
    success=$(expect -f "$ssh_copy_id" 2> /dev/null | egrep "success")
    if [ "${success}" != "success"  ]; then
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id} SSH failed ssh-copy-id; checking public key: $public_keyfile" &> /dev/stderr ; fi
      result=$(ssh -o "BatchMode yes" -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hostname 2> /dev/null')
      if [ -z "${result}" ]; then
	echo "*** ERROR: ${id} SSH failed; consider reflashing; continuing..." &> /dev/stderr
	continue
      else
        if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: hostname: ${result}" &> /dev/stderr; fi
      fi
    fi
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG ${id}: configured with $conf_id public key" &> /dev/stderr; fi
    ## UPDATE CONFIGURATION
    node_state=$(echo "$node_state" | jq '.ssh.id="'"${conf_id}"'"')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: updating configuration ${config}" &> /dev/stderr; fi
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    # get new status
    config_ssh=$(jq '.nodes[]|select(.id=="'$id'").ssh != null' "${config}")
  fi
  if [ "${config_ssh}" != "true" ]; then
    echo "*** ERROR: ${id} SSH failed; consider reflashing; continuing..." &> /dev/stderr
    continue
  fi

  ## CONFIG SECURITY
  if [[ ${config_security} != "true" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: SECURITY setting hostname and password" &> /dev/stderr ; fi
    # get node configuration specifics
    device=$(echo "$node_conf" | jq -r '.device')
    token=$(echo "$node_conf" | jq -r '.token')
    if [[ -z $device || -z $token ]]; then
      echo "*** ERROR: ${id}: node configuration device or token are unspecified: $node_conf" &> /dev/stderr
      continue
    fi
    # create device and token script
    config_script="$TMP/config-ssh.sh"
    cat "config-ssh.tmpl" \
      | sed 's|%%DEVICE_NAME%%|'"${device}"'|g' \
      | sed 's|%%CLIENT_USERNAME%%|'"${client_username}"'|g' \
      | sed 's|%%CLIENT_HOSTNAME%%|'"${client_hostname}"'|g' \
      | sed 's|%%DEVICE_TOKEN%%|'"${token}"'|g' \
      > "${config_script}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: copying SSH script ${config_script}" &> /dev/stderr; fi
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${config_script}" "${client_username}@${client_ipaddr}:." &> /dev/null
    cmd="sudo bash ./${config_script##*/}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: invoking ${cmd}" &> /dev/stderr; fi
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${client_username}@${client_ipaddr}" "${cmd}")
    if [ "${result}" != "changed" ]; then
      echo "*** ERROR: ${id}: SECURITY failed; result ($result) for command $cmd; continuing..." &> /dev/stderr
      continue
    fi
    ## UPDATE CONFIGURATION
    node_state=$(echo "$node_state" | jq '.ssh={"id":"'"$conf_id"'","token":"'"${token}"'","device":"'"${device}"'"}')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: updating configuration ${config}" &> /dev/stderr; fi
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    config_security=$(echo "$node_state" | jq '.ssh.device!=null')
  fi
  # sanity
  if [[ ${config_security} != "true" ]]; then
    echo "*** ERROR: ${id}: SECURITY failed; continuing..." &> /dev/stderr
    continue
  else
    # test access
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'hostname')
    if [[ -z $result || $(echo "$node_state" | jq -r '.ssh.device=="'"$result"'"') != "true" ]]; then
      echo "*** ERROR: ${id} SSH failed; cannot confirm hostname: ${result}" $(echo "$node_state" | jq '.ssh') &> /dev/stderr
      continue
    fi
    echo "--- INFO: ${id}: SECURITY configured" $(echo "$node_state" | jq -c '.ssh') &> /dev/stderr
  fi

  ## CONFIG SOFTWARE
  if [ "${config_software}" == "true" ]; then
    # test access
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'command -v hzn')
    if [ -z "${result}" ] || [ "${result}" != $(echo "${node_state}" | jq -r '.software.command') ]; then
      echo "+++ WARN : ${id} SOFTWARE failed; cannot confirm command: ${result}" &> /dev/stderr
      node_state=$(echo "$node_state" | jq '.software=null')
      # update configuration file
      jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
      # update software configuration
      config_software=$(jq '.nodes[]|select(.id=="'$id'").software != null' "${config}")
    else
      echo "--- INFO: ${id}: SOFTWARE configured:" $(echo "$node_state" | jq -c '.software.command') &> /dev/stderr
    fi
  fi
  if [ "${config_software}" != "true" ]; then
    # install software
    echo "--- INFO: ${id}: SOFTWARE installing ${HORIZON_SETUP_URL}" &> /dev/stderr
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" 'wget -qO - '"${HORIZON_SETUP_URL}"' | sudo bash 2> log')
    if [[ -z "${result}" ]]; then
      echo "*** ERROR: ${id}: SOFTWARE failed; result = $result" &> /dev/stderr
      continue
    else
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: installation result: $result" &> /dev/stderr; fi
    fi
    # add distribution information
    result=$(echo "$result" | jq '.distribution='"${client_distro}")
    # update node state
    node_state=$(echo "$node_state" | jq '.software='"$result")
    # update configuration file
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    # update software configuration
    config_software=$(jq '.nodes[]|select(.id=="'$id'").software != null' "${config}")
  fi
  # sanity
  if [ "${config_software}" != "true" ]; then
    echo "*** ERROR: ${id}: SOFTWARE failed" &> /dev/stderr
    continue
  fi

  ## CONFIG EXCHANGE
  if [[ ${config_exchange} != "true" ]]; then
    echo "--- INFO: ${id}: EXCHANGE configuring" &> /dev/stderr
    # get exchange
    ex_id=$(echo "$conf" | jq -r '.exchange')
    if [[ -z $ex_id || "$ex_id" == "null" ]]; then
      echo "*** ERROR: ${id}: exchange not specified in configuration: $conf" &> /dev/stderr
      continue
    fi
    exchange=$(jq '.exchanges[]|select(.id=="'$ex_id'")' "${config}")
    if [[ -z "${exchange}" || "${exchange}" == null ]]; then
      echo "*** ERROR: ${id}: exchange $ex_id not found in exchanges" &> /dev/stderr
      continue
    fi
    # check URL for exchange
    ex_url=$(echo "$exchange" | jq -r '.url')
    if [[ -z $ex_url || "$ex_url" == "null" ]]; then
      ex_url="$HZN_EXCHANGE_URL"
      echo "+++ WARN: exchange $ex_id does not have URL specified; using default: $ex_url" &> /dev/stderr
    fi

    # update node state
    node_state=$(echo "$node_state" | jq '.exchange.id="'"$ex_id"'"|.exchange.url="'"$ex_url"'"')
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "$node_state" | jq -c '.') &> /dev/stderr; fi

    # get exchange specifics
    ex_org=$(echo "$exchange" | jq -r '.org')
    ex_username=$(echo "$exchange" | jq -r '.username')
    ex_password=$(echo "$exchange" | jq -r '.password')
    ex_device=$(echo "$node_state" | jq -r '.ssh.device')
    ex_token=$(echo "$node_state" | jq -r '.ssh.token')

    # force specification of exchange URL
    cmd="sudo sed -i 's|HZN_EXCHANGE_URL=.*|HZN_EXCHANGE_URL=${ex_url}|' /etc/default/horizon"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    cmd="sudo systemctl restart horizon || false"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    # test for failure status
    if [[ $? != 0 ]]; then
      echo "*** ERROR: ${id}: EXCHANGE failed; $cmd" &> /dev/stderr
      continue
    else
      echo "--- INFO: ${id}: EXCHANGE succeeded; $cmd" &> /dev/stderr
    fi

    # create node in exchange (always returns nothing)
    cmd="hzn exchange node create -o ${ex_org} -u ${ex_username}:${ex_password} -n ${ex_device}:${ex_token}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result=$?
    while [[ $result != 0 ]]; do
	if [ -n "${DEBUG}" ]; then echo "+++ WARN: ${id}: failed command ${result}: $cmd" &> /dev/stderr; fi
        ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
        result=$?
    done

    # get exchange node information
    cmd="hzn exchange node list -o ${ex_org} -u ${ex_username}:${ex_password} ${ex_device}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/henl.json"
    result=$?
    while [[ $result != 0 || ! -s "$TMP/henl.json" ]]; do
      echo "+++ WARN: ${id}: EXCHANGE retry; $cmd" &> /dev/stderr
      ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/henl.json"
      result=$?
    done
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: result $TMP/henl.json" $(jq -c '.' "$TMP/henl.json") &> /dev/stderr; fi
    # update node state
    result=$(sed 's/{}/null/g' "$TMP/henl.json" | jq '.')
    node_state=$(echo "$node_state" | jq '.exchange.node='"$result")
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "$node_state" | jq -c '.') &> /dev/stderr; fi

    # get exchange status
    cmd="hzn exchange status -o $ex_org -u ${ex_username}:${ex_password}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/hes.json"
    result=$?
    while [[ $result != 0 || ! -s "$TMP/hes.json" ]]; do
      echo "+++ WARN: ${id}: EXCHANGE retry; $cmd" &> /dev/stderr
      ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" > "$TMP/hes.json"
      result=$?
    done
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: result $TMP/hes.json" $(jq -c '.' "$TMP/hes.json") &> /dev/stderr; fi
    # update node state
    result=$(sed 's/{}/null/g' "$TMP/hes.json" | jq '.')
    node_state=$(echo "$node_state" | jq '.exchange.status='"$result")
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "$node_state" | jq -c '.') &> /dev/stderr; fi

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    config_exchange=$(jq '.nodes[]|select(.id=="'$id'").exchange.node != null' "${config}")
  fi
  # sanity
  if [[ ${config_exchange} != "true" ]]; then
    echo "+++ WARN: ${id}: EXCHANGE failed" &> /dev/stderr
    continue
  else
    echo "--- INFO: ${id}: EXCHANGE configured:" $(echo "$node_state" | jq -c '.exchange.id') &> /dev/stderr
  fi

  ##
  ## CONFIG PATTERN (or reconfigure)
  ##

  echo "--- INFO: ${id}: PATTERN configuring" &> /dev/stderr
  # get pattern
  ptid=$(echo "$conf" | jq -r '.pattern?')
  if [[ -z $ptid || $ptid == 'null' ]]; then
    echo "*** ERROR: ${id}: pattern not specified in configuration: $conf" &> /dev/stderr
    continue
  fi
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: pattern identifier $ptid" &> /dev/stderr; fi
  pattern=$(jq '.patterns[]|select(.id=="'$ptid'")' "${config}")
  if [[ -z "${pattern}" || "${pattern}" == "null" ]]; then
    echo "*** ERROR: ${id}: pattern $ptid not found in patterns" &> /dev/stderr
    continue
  fi

  # pattern for registration
  pt_id=$(echo "$pattern" | jq -r '.id')
  pt_org=$(echo "$pattern" | jq -r '.org')
  pt_url=$(echo "$pattern" | jq -r '.url')
  pt_vars=$(echo "$conf" | jq '.variables')
  
  # get node specifics
  ex_id=$(echo "$node_state" | jq -r '.exchange.id')
  ex_device=$(echo "$node_state" | jq -r '.ssh.device')
  ex_token=$(echo "$node_state" | jq -r '.ssh.token')
  ex_org=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").org' "${config}")
  ex_username=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").username' "${config}")
  ex_password=$(jq -r '.exchanges[]|select(.id=="'"$ex_id"'").password' "${config}")

  # get node status
  cmd='hzn node list'
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
  result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null" | jq '.')
  if [ -z "${result}" ]; then
    echo "*** ERROR: remote command $cmd returned zero results; continuing..." &> /dev/stderr
    continue
  else
    node_state=$(echo "$node_state" | jq '.node='"$result")
  fi

  # test if node is configured with pattern
  node_id=$(echo "$node_state" | jq -r '.node.id')
  node_status=$(echo "$node_state" | jq -r '.node.configstate.state')
  node_pattern=$(echo "$node_state" | jq -r '.node.pattern')

  # unregister node iff
  if [[ ${node_id} == ${ex_device} && $node_pattern == ${pt_org}/${pt_id} && ( $node_status == "configured" || $node_status == "configuring" ) ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: node ${node_id} is ${node_status} with pattern ${node_pattern}" &> /dev/stderr; fi
  elif [[ $node_status == "unconfiguring" ]]; then
    echo "*** ERROR: ${id}: node ${node_id} aka ${ex_device} is unconfiguring; consider reflashing or remove, purge, update, prune, and reboot" &> /dev/stderr
    continue
  elif [[ ${node_id} != ${ex_device} || $node_status != "unconfigured" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: unregistering node ${node_id}" &> /dev/stderr ; fi
    # unregister client
    cmd='hzn unregister -f'
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"

    # POLL client for node list information; wait until device identifier matches requested
    cmd='hzn node list'
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: executing remote command: $cmd" &> /dev/stderr; fi
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
    iteration=1; while [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="unconfigured"') == false ]; do
      if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on unregistration [10]; iteration ${iteration}; result:" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
      iteration=$((iteration+1))
      if [ ${iteration} -le 5 ]; then 
        sleep 10
      else
        if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: stopped waiting on unregistration at iteration ${iteration}; result:" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
        break
      fi
      result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
    done
    if [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="unconfigured"') == false ]; then
      echo "*** ERROR: ${id}: command failed: $cmd; iteration ${iteration}; result:" $(echo "${result}" | jq -c '.') &> /dev/stderr
      continue
    fi
    node_state=$(echo "$node_state" | jq '.node='"$result")
  fi

  # register node iff
  if [[ $(echo "$node_state" | jq '.node.configstate.state=="unconfigured"') == "true" ]]; then
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: registering node" $(echo "$node_state" | jq -c '.') &> /dev/stderr ; fi
    # create pattern registration file
    input="$TMP/input.json"
    echo '{"services": [{"org": "'"${pt_org}"'","url": "'"${pt_url}"'","versionRange": "[0.0.0,INFINITY)","variables": {' > "${input}"
    # process all variables 
    pvs=$(echo "${pt_vars}" | jq -r '.[].key')
    i=0; for pv in ${pvs}; do
      value=$(echo "${pt_vars}" | jq -r '.[]|select(.key=="'"${pv}"'").value')
      if [[ $i > 0 ]]; then echo ',' >> "${input}"; fi
      echo '"'"${pv}"'":"'"${value}"'"' >> "${input}"
      i=$((i+1))
    done
    echo '}}]}' >> "${input}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node ${ex_device}; pattern ${pt_org}/${pt_id}; input" $(cat "${input}") &> /dev/stderr; fi

    # copy pattern registration file to client
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${input}" "${client_username}@${client_ipaddr}:." &> /dev/null
    # perform registration
    cmd="hzn register ${ex_org} -u ${ex_username}:${ex_password} ${pt_org}/${pt_id} -f ${input##*/} -n ${ex_device}:${ex_token}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: registering with command: $cmd" &> /dev/stderr; fi
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "${cmd} &> /dev/null")
  fi

  # POLL client for node list information; wait for configured state
  cmd="hzn node list"
  result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  while [ -z "${result}" ] || [ $(echo "$result" | jq '.configstate.state=="configured"') == false ]; do
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on configuration [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
    sleep 10
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  done
  if [ -z "${result}" ] || [ "${results}" == "null" ]; then
    echo "*** ERROR: ${id}: command $cmd failed; continuing..." &> /dev/stderr
    continue
  fi
  node_state=$(echo "$node_state" | jq '.node='"$result")
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node is configured" &> /dev/stderr; fi

  # POLL client for agreementlist information; wait until agreement exists
  cmd="hzn agreement list"
  result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  while [ -z "${result}" ] || [ $(echo "$result" | jq '.==[]') == "true" ]; do
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: waiting on agreement [10]" $(echo "$result" | jq -c '.') &> /dev/stderr; fi
    sleep 10
    result=$(ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd 2> /dev/null")
  done
  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: agreement complete:" $(echo "${result}" | jq -c '.') &> /dev/stderr; fi
  node_state=$(echo "$node_state" | jq '.pattern='"$result")

  # UPDATE CONFIGURATION
  jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"

  ## DONE w/ PATTERN
  echo "--- INFO: ${id}: PATTERN configured" $(echo "$node_state" | jq -c '.pattern[]?.workload_to_run.url') &> /dev/stderr

  ##
  ## CONFIG NETWORK
  ##

  if [[ ${config_network} != "true" ]]; then
    echo "--- INFO: ${id}: configuring NETWORK" &> /dev/stderr
    # get network
    nwid=$(echo "$conf" | jq -r '.network?')
    if [[ -z $nwid || $nwid == 'null' ]]; then
      echo "*** ERROR: ${id}: network not specified in configuration: $conf" &> /dev/stderr
      continue
    fi
    network=$(jq '.networks[]|select(.id=="'$nwid'")' "${config}")
    if [[ -z "${network}" || "${network}" == "null" ]]; then
      echo "*** ERROR: ${id}: network $nwid not found in network" &> /dev/stderr
      continue
    fi
    # network for deployment
    nw_id=$(echo "$network" | jq -r '.id')
    nw_dhcp=$(echo "$network" | jq -r '.dhcp')
    nw_ssid=$(echo "$network" | jq -r '.ssid')
    nw_password=$(echo "$network" | jq -r '.password')
    # create wpa_supplicant.conf
    config_script="$TMP/wpa_supplicant.conf"
    cat "wpa_supplicant.tmpl" \
      | sed 's|%%WIFI_SSID%%|'"${nw_ssid}"'|g' \
      | sed 's|%%WIFI_PASSWORD%%|'"${nw_password}"'|g' \
      > "${config_script}"
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: copying script ${config_script}" &> /dev/stderr; fi
    scp -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "${config_script}" "${client_username}@${client_ipaddr}:." &> /dev/null
    if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: invoking script ${config_script##*/}" &> /dev/stderr; fi
    cmd='sudo mv -f '"${config_script##*/}"' /etc/wpa_supplicant/wpa_supplicant.conf'
    ssh -o "CheckHostIP no" -o "StrictHostKeyChecking no" -i "$private_keyfile" "$client_username"@"$client_ipaddr" "$cmd &> /dev/null"
    result='{ "ssid": "'"${nw_ssid}"'","password":"'"${nw_password}"'"}'
    node_state=$(echo "$node_state" | jq '.network='"$result")

    ## UPDATE CONFIGURATION
    jq '(.nodes[]|select(.id=="'$id'"))|='"$node_state" "${config}" > "$TMP/${config##*/}"; mv -f "$TMP/${config##*/}" "${config}"
    config_network=$(jq '.nodes[]|select(.id=="'$id'").network != null' "${config}")
  fi
  # sanity
  if [[ ${config_network} != "true" ]]; then
    echo "+++ WARN: ${id}: NETWORK failed" &> /dev/stderr
    continue
  else
    echo "--- INFO: ${id}: NETWORK configured" $(echo "$node_state" | jq -c '.network') &> /dev/stderr
  fi

  if [ -n "${DEBUG}" ]; then echo "??? DEBUG: ${id}: node state:" $(echo "${node_state}" | jq -c '.') &> /dev/stderr; fi

done

echo $(jq -c '[.nodes[]?|{"node":.node.id,"mac":.mac,"exchange":.exchange?.id,"pattern":.pattern[]?.workload_to_run.url}]' "${config}")

if [ -z "${DEBUG}" ]; then rm -fr "$TMP"; fi
exit 0
