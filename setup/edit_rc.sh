#!/bin/bash

## not for macintosh
if [ "${VENDOR}" == "apple" ] || [ "${OSTYPE}" == "darwin" ]; then
  echo "You're on a Macintosh; run in VirtualBox Ubuntu18 VM and use vmdk_sd.sh to enable SD card access" >&2
  exit 1
fi

### DEFAULTS

DEFAULT_WIFI_SSID="TEST"
DEFAULT_WIFI_PASSWORD="0123456789"
DEFAULT_PUBLIC_KEY_FILE=~/.ssh/id_rsa.pub

## CONFIGURATION
CONFIG="horizon.json"
if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}"
    exit 1
  fi
else
  if [ ! -s "${1}" ]; then
    echo "*** ERROR configuration file empty: ${1}"
    exit 1
  fi
  CONFIG="${1}"
fi

## WIFI
WIFI_SSID=$(jq -r '.networks|first|.ssid' "${CONFIG}")
WIFI_PASSWORD=$(jq -r '.networks|first|.password' "${CONFIG}")
if [ "${WIFI_SSID}" == "null" ] || [ "${WIFI_PASSWORD}" == "null" ]; then
  WIFI_SSID="${DEFAULT_WIFI_SSID}"
  WIFI_PASSWORD="${DEFAULT_WIFI_PASSWORD}"
  echo "+++ WARN $0 $$ -- no WIFI_SSID or WIFI_PASSWORD defined; using default (${WIFI_SSID}:${WIFI_PASSWORD})"
else
  echo "--- INFO $0 $$ -- WIFI_SSID & WIFI_PASSWORD defined; using (${WIFI_SSID}:${WIFI_PASSWORD})"
fi

## PARTITION
SDB="/dev/sdb"
if [ -z "${2}" ]; then
  if [ -e "${SDB}" ]; then
    echo "+++ WARN $0 $$ -- no device specified; found default ${SDB}"
  else
    echo "*** ERROR $0 $$ -- no device specified; no default (${SDB}) found"
    exit 1
  fi
else
  SDB="${2}"
fi
if [ ! -e "${SDB}" ]; then
  echo "*** ERROR $0 $$ -- device not found: ${SDB}"
  exit 1
fi
BOOT_PART=${SDB}1
if [ ! -e "${BOOT_PART}" ]; then
  echo "*** ERROR $0 $$ -- boot partition not found: ${BOOT_PART}"
  exit 1
fi
LINUX_PART=${SDB}2
if [ ! -e "${LINUX_PART}" ]; then
  echo "*** ERROR $0 $$ -- LINUX partition not found: ${LINUX_PART}"
  exit 1
fi

## MOUNT POINT
VOL=/mnt
if [ -z "${3}" ]; then
  if [ -d "${VOL}" ]; then
    echo "+++ WARN $0 $$ -- no mount point specified; found default directory: ${VOL}"
  else
    echo "*** ERROR $0 $$ -- no device specified; no default directory (${VOL}) found"
    exit 1
  fi
else
  VOL="${3}"
fi
if [ ! -d "${VOL}" ]; then
  echo "+++ WARN $0 $$ -- no mount point specified; found default directory: ${VOL}"
  sudo mkdir -p "${VOL}"
fi
BOOT_VOL="${VOL}/boot"
LINUX_VOL="${VOL}/linux"
# make directories
sudo mkdir -p "${BOOT_VOL}" "${LINUX_VOL}"
# test
if [ ! -d "${BOOT_VOL}" ] || [ ! -d "${LINUX_VOL}" ]; then
  echo "*** ERROR $0 $$ -- invalid mount directories: ${BOOT_VOL} & ${LINUX_VOL}"
  exit 1
fi

### BOOT

sudo mount "${BOOT_PART}" "${BOOT_VOL}"
if [ ! -d "${BOOT_VOL}" ]; then
  echo "*** ERROR $0 $$ -- failed to mount partition ${BOOT_PART} on ${BOOT_VOL}"
  exit 1
fi

## SSH ACCESS
SSH_FILE="${BOOT_VOL}/ssh"
sudo touch "${SSH_FILE}"
if [ ! -e "${SSH_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${SSH_FILE}"
  exit 1
fi
echo "--- INFO $0 $$ -- created ${SSH_FILE} for SSH access"
# public key setup
PUBLIC_KEY=$(jq -r '.keys.public' "${CONFIG}")
if [ -z "${PUBLIC_KEY}" ] || [ "${PUBLIC_KEY}" == "null" ]; then
  if [ -e "${DEFAULT_PUBLIC_KEY_FILE}" ]; then
    echo "+++ WARN $0 $$ -- no public key; found default ${DEFAULT_PUBLIC_KEY_FILE}"
    PUBLIC_KEY=$(base64 -w 0 "${DEFAULT_PUBLIC_KEY_FILE}")
  else
    echo "*** ERROR $0 $$ -- no public key; no default ${DEFAULT_PUBLIC_KEY_FILE}; run ssh-keygen"
    exit 1
  fi
fi
# write public keyfile
echo "${PUBLIC_KEY}" | base64 --decode | tee "${SSH_FILE}.pub" &> /dev/null
echo "--- INFO $0 $$ -- created ${SSH_FILE}.pub for authorized_hosts"

## WPA
# SUPPLICANT
if [ -z "${WPA_SUPPLICANT_FILE:-}" ]; then
  WPA_SUPPLICANT_FILE="${BOOT_VOL}/wpa_supplicant.conf"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_SUPPLICANT_FILE: ${WPA_SUPPLICANT_FILE}"
fi
# WPA TEMPLATE
if [ -z "${WPA_TEMPLATE_FILE:-}" ]; then
    WPA_TEMPLATE_FILE="wpa_supplicant.tmpl"
else
  echo "+++ WARN $0 $$ -- non-standard WPA_TEMPLATE_FILE: ${WPA_TEMPLATE_FILE}"
fi
if [ ! -s "${WPA_TEMPLATE_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not find: ${WPA_TEMPLATE_FILE}"
  exit 1
fi
# change template
sudo cp -f "${WPA_TEMPLATE_FILE}" "${WPA_SUPPLICANT_FILE}"
sudo sed -i \
  -e 's|%%WIFI_SSID%%|'"${WIFI_SSID}"'|g' \
  -e 's|%%WIFI_PASSWORD%%|'"${WIFI_PASSWORD}"'|g' \
  "${WPA_SUPPLICANT_FILE}"
if [ ! -s "${WPA_SUPPLICANT_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${WPA_SUPPLICANT_FILE}"
  exit 1
fi
# SUCCESS
echo "--- INFO $0 $$ -- ${WPA_SUPPLICANT_FILE} created"
# unmount & remove mount point directory
sudo umount "${BOOT_VOL}"
sudo rmdir "${BOOT_VOL}"

### LINUX

sudo mount "${LINUX_PART}" "${LINUX_VOL}"
if [ ! -d "${LINUX_VOL}" ]; then
  echo "*** ERROR $0 $$ -- failed to mount partition ${LINUX_PART} on ${LINUX_VOL}"
  exit 1
fi

## RC.LOCAL
if [ -z "${RC_LOCAL_FILE:-}" ]; then
  RC_LOCAL_FILE="${LINUX_VOL}/etc/rc.local"
else
  echo "+++ WARN $0 $$ -- non-standard RC_LOCAL_FILE: ${RC_LOCAL_FILE}"
fi
# RC TEMPLATE
if [ -z "${RC_TEMPLATE_FILE:-}" ]; then
    RC_TEMPLATE_FILE="rc_local.tmpl"
else
  echo "+++ WARN $0 $$ -- non-standard RC_TEMPLATE_FILE: ${RC_TEMPLATE_FILE}"
fi
if [ ! -s "${RC_TEMPLATE_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not find: ${RC_TEMPLATE_FILE}"
  exit 1
fi
# change template
sudo cp -f "${RC_TEMPLATE_FILE}" "${RC_LOCAL_FILE}"
sudo sed -i \
  -e 's|%%CLIENT_USERNAME%%|'"${CLIENT_USERNAME}"'|g' \
  -e 's|%%DEVICE_NAME%%|'"${DEVICE_NAME}"'|g' \
  -e 's|%%DEVICE_TOKEN%%|'"${DEVICE_TOKEN}"'|g' \
  -e 's|%%HORIZON_SETUP_URL%%|'"${HORIZON_SETUP_URL}"'|g' \
  "${RC_LOCAL_FILE}"
if [ ! -s "${RC_LOCAL_FILE}" ]; then
  echo "*** ERROR $0 $$ -- could not create: ${RC_LOCAL_FILE}"
  exit 1
fi
# SUCCESS
echo "--- INFO $0 $$ -- ${RC_LOCAL_FILE} created"
# unmount & remove mount point directory
sudo umount "${LINUX_VOL}"
sudo rmdir "${LINUX_VOL}"

echo "--- INFO $0 $$ -- you may now safely eject disk ${SDB}"
