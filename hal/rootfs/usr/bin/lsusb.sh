#!/bin/bash
if [ -z $(command -v "lsusb") ]; then
  exit 1
fi
echo -n '{"lsusb":['
lsusb | while read -r; do
  BUS=$(echo "$REPLY" | sed 's|^Bus \([^ ]*\) .*|\1|')
  DID=$(echo "$REPLY" | sed 's|.*Device \([^:]*\):.*|\1|')
  DBN=$(echo "$REPLY" | sed 's|.*ID \([^:]*\):.*|\1|')
  MID=$(echo "$REPLY" | sed 's|.*ID [^:]*:\([^ ]*\) .*|\1|')
  MDN=$(echo "$REPLY" | sed 's|.*ID [^:]*:[^ ]* \(.*\)|\1|')
  if [ -n "${VALUE:-}" ]; then echo -n ','; fi
  VALUE='{"bus_number": "'${BUS}'","device_id": "'${DID}'","device_bus_number": "'${DBN}'", "manufacture_id": "'${MID}'", "manufacture_device_name": "'${MDN}'"}'
  echo -n "${VALUE}"
done
echo ']}'
