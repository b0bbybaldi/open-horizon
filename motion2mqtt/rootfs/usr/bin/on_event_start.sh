#!/bin/tcsh

if ( -d "/tmpfs" ) then 
  set TMPDIR = "/tmpfs"
else
  set TMPDIR = "/tmp"
endif

unsetenv DEBUG
unsetenv DEBUG_MQTT

if ($?DEBUG) then
  set message = ( "START" `date` )
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

## REQUIRES date utilities
if ( -e /usr/bin/dateutils.dconv ) then
   set dateconv = /usr/bin/dateutils.dconv
else if ( -e /usr/bin/dateconv ) then
   set dateconv = /usr/bin/dateconv
else if ( -e /usr/local/bin/dateconv ) then
   set dateconv = /usr/local/bin/dateconv
else
  if ($?DEBUG) then
    set message = "no dateutils(1) found; exiting"
    echo "$0:t $$ -- $message" >& /dev/stderr
    if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
  endif
  # quit
  goto done
endif

## ARGUMENTS
#
# on_event_start.sh %$ %v %Y %m %d %H %M %S
#
# %$ - camera name
# %v - Event number. An event is a series of motion detections happening with less than 'gap' seconds between them. 
# %Y - The year as a decimal number including the century. 
# %m - The month as a decimal number (range 01 to 12). 
# %d - The day of the month as a decimal number (range 01 to 31).
# %H - The hour as a decimal number using a 24-hour clock (range 00 to 23)
# %M - The minute as a decimal number (range 00 to 59). >& /dev/stderr
# %S - The second as a decimal number (range 00 to 61). 
#

set CN = "$1"
set EN = "$2"
set YR = "$3"
set MO = "$4"
set DY = "$5"
set HR = "$6"
set MN = "$7"
set SC = "$8"
set TS = "${YR}${MO}${DY}${HR}${MN}${SC}"

# in seconds
set NOW = `$dateconv -i '%Y%m%d%H%M%S' -f "%s" "${TS}"`

set dir = "/var/lib/motion"

set EJ = "${dir}/${TS}-${EN}.json"

if ($?DEBUG) then
  set message = '{"dir":"'${dir}'","camera":"'$CN'","event":"'$EN'","start":'$NOW',"timestamp":"'"$TS"'","json":"'"$EJ"'"}'
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

## create event JSON
echo '{"device":"'${MOTION_CLIENT}'","camera":"'${CN}'","event":"'${EN}'","start":'${NOW}'}' >! "${EJ}"

## PUBLISH
set MQTT_TOPIC = "${MOTION_GROUP}/${MOTION_CLIENT}/${CN}/event/start"
motion2mqtt_pub.sh -q 2 -r -t "${MQTT_TOPIC}" -f "$EJ"

# debug
if ($?DEBUG) then
  set message = "sent file ${EJ} to topic ${MQTT_TOPIC} at ${MQTT_HOST}"
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif

done:

if ($?DEBUG) then
  set message = ( "FINISH" `date` )
  echo "$0:t $$ -- $message" >& /dev/stderr
  if ($?DEBUG_MQTT) motion2mqtt_pub.sh -t "${MOTION_GROUP}/${MOTION_CLIENT}/debug" -m '{"'${MOTION_CLIENT}'":"'$0:t'","pid":'$$',"message":"'"$message"'"}'
endif
